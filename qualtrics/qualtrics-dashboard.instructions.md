# Project Instructions: Qualtrics Dashboard Development

---
description: Development guidelines and patterns for Qualtrics disposition reporting dashboard
applyTo: 'src/**,infrastructure/**'
---

> **⚠️ DISPOSITION REPORTING (v2.0.0 DIBINIUM)**: This project provides **email disposition metrics** (sent, bounced, opened, clicked, response rates) through **aggregate-only data**, NOT individual response tracking. See [Disposition Reporting Refactor](../../docs/refactoring/DISPOSITION-REPORTING-REFACTOR.md) for complete architecture details.

## 🎯 Project Context

This project builds a **real-time disposition reporting dashboard** for monitoring email distribution performance in Qualtrics survey campaigns. The system uses **polling-based architecture** with Azure services for scalability, reliability, and **privacy-preserving aggregate metrics**.

**Key Principles**:
- **Aggregate-Only**: No individual PII storage (counts and calculated rates only)
- **Polling-Based**: Distributions API polling (5-60 minute intervals, user-configurable)
- **Time-Series**: 365-day retention for historical trend analysis
- **Privacy-First**: Zero individual response data stored in our database
- **Complementary**: Works alongside existing data systems without conflicts

**Technology Stack**:
- Frontend: React + TypeScript (disposition metrics dashboard)
- Backend: ASP.NET Core 8+ (disposition API + polling service)
- Real-Time: Azure SignalR Service (disposition updates broadcasting)
- Database: Azure Cosmos DB (DistributionDispositions, aggregates, configurations)
- Queue: Azure Service Bus (optional webhook supplemental events)
- Background Service: DistributionPollingService (scheduled polling)

**Disposition Metrics Tracked**:
| Metric | Source | Description |
|--------|--------|-------------|
| **Emails Sent** | Distributions API | Total emails sent in distribution |
| **Bounce Rate** | `bounced / sent` | % of emails that bounced |
| **Open Rate** | `opened / (sent - bounced)` | % of delivered emails opened |
| **Click Rate** | `clicked / opened` | % of opened emails with clicks |
| **Response Rate** | `finished / sent` | % of sent emails completed |
| **Completion Rate** | `finished / opened` | % of opened emails completed |

**Data Models** (Phase 2B):
- `DistributionDisposition` - Time-series snapshots with counts and calculated rates
- `SurveyDispositionAggregate` - Survey-level rollups for dashboard display
- `PollingConfiguration` - User-configurable polling settings (5-60 min intervals)
- `DispositionDelta` - Change tracking for anomaly detection

---

## 📋 Development Rules

### 1. API Integration Patterns

**Always** use the QualtricsService for API calls:
```csharp
// ✅ GOOD: Centralized service with error handling
public class SurveysController : ControllerBase
{
    private readonly IQualtricsService _qualtricsService;
    
    [HttpGet("{surveyId}/responses")]
    public async Task<IActionResult> GetResponses(string surveyId)
    {
        var responses = await _qualtricsService.GetResponsesAsync(surveyId);
        return Ok(responses);
    }
}

// ❌ BAD: Direct HTTP calls scattered in controllers
[HttpGet]
public async Task<IActionResult> Get()
{
    using var client = new HttpClient();
    client.DefaultRequestHeaders.Add("X-API-TOKEN", _token);
    var response = await client.GetAsync("https://...");
    // ...
}
```

**Rate Limit Handling**:
```csharp
// Implement retry logic with exponential backoff
public async Task<T> ExecuteWithRetryAsync<T>(Func<Task<T>> operation)
{
    const int maxAttempts = 3;
    
    for (int attempt = 1; attempt <= maxAttempts; attempt++)
    {
        try
        {
            return await operation();
        }
        catch (HttpRequestException ex) when (ex.StatusCode == HttpStatusCode.TooManyRequests)
        {
            if (attempt == maxAttempts) throw;
            
            var delay = TimeSpan.FromSeconds(Math.Pow(2, attempt));
            await Task.Delay(delay);
        }
    }
}
```

### 2. Cosmos DB Best Practices

**Partition Key**: Always use `surveyId` as partition key
```csharp
// ✅ GOOD: Query within partition
var query = container.GetItemLinqQueryable<Response>()
    .Where(r => r.SurveyId == surveyId && r.CompletedDate > startDate);

// ❌ BAD: Cross-partition query without filter
var query = container.GetItemLinqQueryable<Response>()
    .Where(r => r.CompletedDate > startDate);  // Scans all partitions!
```

**Use Projections** to reduce RU consumption:
```csharp
// ✅ GOOD: Only fetch needed fields
var summaries = container.GetItemLinqQueryable<Response>()
    .Where(r => r.SurveyId == surveyId)
    .Select(r => new ResponseSummary 
    { 
        Id = r.Id, 
        CompletedDate = r.CompletedDate,
        Duration = r.Duration 
    });

// ❌ BAD: Fetch full documents when only need metadata
var responses = container.GetItemLinqQueryable<Response>()
    .Where(r => r.SurveyId == surveyId)
    .ToList();  // Pulls ALL fields including large 'values' object
```

**Upserting Responses** (idempotent webhook handling):
```csharp
public async Task SaveResponseAsync(Response response)
{
    var partitionKey = new PartitionKey(response.SurveyId);
    
    // Upsert ensures idempotency (duplicate webhooks are safe)
    await _container.UpsertItemAsync(
        response, 
        partitionKey,
        new ItemRequestOptions { EnableContentResponseOnWrite = false }  // Save RUs
    );
}
```

### 3. SignalR Real-Time Updates

**Group Management** for per-survey subscriptions:
```csharp
// SurveyHub.cs
public class SurveyHub : Hub
{
    public async Task SubscribeToSurvey(string surveyId)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, $"survey_{surveyId}");
        
        // Optionally send current stats immediately
        var stats = await _statisticsService.GetCurrentStatsAsync(surveyId);
        await Clients.Caller.SendAsync("InitialStats", stats);
    }
    
    public async Task UnsubscribeFromSurvey(string surveyId)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"survey_{surveyId}");
    }
}

// SurveyUpdateService.cs - Broadcasting updates
public async Task BroadcastNewResponseAsync(string surveyId, Response response)
{
    // Only notify clients subscribed to this survey
    await _hubContext.Clients
        .Group($"survey_{surveyId}")
        .SendAsync("NewResponse", new ResponseNotification
        {
            ResponseId = response.Id,
            CompletedDate = response.CompletedDate,
            Duration = response.Duration
        });
}
```

**Frontend Connection Management**:
```typescript
// ✅ GOOD: Automatic reconnection with cleanup
export function useRealtimeSurvey(surveyId: string) {
  const [connection, setConnection] = useState<HubConnection | null>(null);

  useEffect(() => {
    const hubConnection = new HubConnectionBuilder()
      .withUrl('/hubs/survey')
      .withAutomaticReconnect({
        nextRetryDelayInMilliseconds: (context) => {
          return Math.min(1000 * Math.pow(2, context.previousRetryCount), 30000);
        }
      })
      .build();

    hubConnection.start()
      .then(() => hubConnection.invoke('SubscribeToSurvey', surveyId))
      .catch(err => console.error('SignalR error:', err));

    setConnection(hubConnection);

    // Cleanup on unmount
    return () => {
      hubConnection.invoke('UnsubscribeFromSurvey', surveyId);
      hubConnection.stop();
    };
  }, [surveyId]);

  return connection;
}
```

### 4. Webhook Security

**HMAC Signature Validation**:
```csharp
public class WebhookReceiverFunction
{
    [Function("ReceiveQualticsWebhook")]
    public async Task<HttpResponseData> Run(
        [HttpTrigger(AuthorizationLevel.Anonymous, "post")] HttpRequestData req)
    {
        var signature = req.Headers.GetValues("X-Qualtrics-Signature").FirstOrDefault();
        var body = await req.ReadAsStringAsync();
        
        // Validate signature BEFORE processing
        if (!ValidateSignature(body, signature))
        {
            return req.CreateResponse(HttpStatusCode.Unauthorized);
        }
        
        // Enqueue for async processing (return 200 quickly)
        await _serviceBusClient.SendMessageAsync(new ServiceBusMessage(body));
        
        return req.CreateResponse(HttpStatusCode.OK);
    }
    
    private bool ValidateSignature(string body, string signature)
    {
        var secret = Environment.GetEnvironmentVariable("QualtricsWebhookSecret");
        var hmac = new HMACSHA256(Encoding.UTF8.GetBytes(secret));
        var hash = hmac.ComputeHash(Encoding.UTF8.GetBytes(body));
        var computed = BitConverter.ToString(hash).Replace("-", "").ToLower();
        
        return signature == computed;
    }
}
```

### 5. Redis Caching Patterns

**Use Redis for Hot Data**:
```csharp
public class CacheService
{
    private readonly IConnectionMultiplexer _redis;
    
    // Counter pattern (atomic increment)
    public async Task<long> IncrementResponseCountAsync(string surveyId)
    {
        var db = _redis.GetDatabase();
        return await db.StringIncrementAsync($"survey:{surveyId}:total");
    }
    
    // Recent items list (capped at 100)
    public async Task AddRecentResponseAsync(string surveyId, ResponseSummary response)
    {
        var db = _redis.GetDatabase();
        var key = $"survey:{surveyId}:recent";
        
        var json = JsonSerializer.Serialize(response);
        await db.ListLeftPushAsync(key, json);
        await db.ListTrimAsync(key, 0, 99);  // Keep only latest 100
    }
    
    // Get aggregated stats (single roundtrip)
    public async Task<SurveyStats> GetStatsAsync(string surveyId)
    {
        var db = _redis.GetDatabase();
        
        var keys = new RedisKey[] 
        {
            $"survey:{surveyId}:total",
            $"survey:{surveyId}:today",
            $"survey:{surveyId}:active_sessions"
        };
        
        var values = await db.StringGetAsync(keys);
        
        return new SurveyStats
        {
            TotalResponses = (long)values[0],
            TodayResponses = (long)values[1],
            ActiveSessions = (long)values[2]
        };
    }
}
```

### 6. Error Handling & Logging

**Structured Logging**:
```csharp
// ✅ GOOD: Structured logging with context
_logger.LogInformation(
    "Processing webhook for survey {SurveyId}, response {ResponseId}",
    surveyId, responseId);

_logger.LogError(
    ex,
    "Failed to save response {ResponseId} to Cosmos DB. Retry attempt {Attempt}",
    responseId, attempt);

// ❌ BAD: String interpolation loses structure
_logger.LogInformation($"Processing webhook for {surveyId}");
```

**Global Exception Handling**:
```csharp
// Startup.cs / Program.cs
app.UseExceptionHandler(errorApp =>
{
    errorApp.Run(async context =>
    {
        var exceptionHandler = context.Features.Get<IExceptionHandlerFeature>();
        var exception = exceptionHandler?.Error;
        
        var logger = context.RequestServices.GetRequiredService<ILogger<Program>>();
        logger.LogError(exception, "Unhandled exception");
        
        context.Response.StatusCode = (int)HttpStatusCode.InternalServerError;
        await context.Response.WriteAsJsonAsync(new 
        { 
            error = "An error occurred processing your request",
            traceId = Activity.Current?.Id 
        });
    });
});
```

---

## 🔐 Security Checklist

- [ ] API tokens stored in Azure Key Vault (never in appsettings.json)
- [ ] Webhook HMAC validation implemented
- [ ] CORS configured with specific origins (not wildcard `*`)
- [ ] Rate limiting enabled on API endpoints
- [ ] HTTPS enforced for all endpoints
- [ ] Azure AD authentication for dashboard access
- [ ] Role-based access control (RBAC) for survey access
- [ ] Input validation and sanitization on all endpoints
- [ ] SQL injection prevention (using parameterized queries)
- [ ] XSS prevention (React escapes by default, but verify)

---

## 📊 Monitoring & Observability

### Application Insights Setup
```csharp
// Program.cs
builder.Services.AddApplicationInsightsTelemetry();

// Custom metrics tracking
public class MetricsService
{
    private readonly TelemetryClient _telemetry;
    
    public void TrackWebhookReceived(string surveyId)
    {
        _telemetry.TrackEvent("WebhookReceived", new Dictionary<string, string>
        {
            { "surveyId", surveyId }
        });
    }
    
    public void TrackResponseProcessingTime(string surveyId, TimeSpan duration)
    {
        _telemetry.TrackMetric("ResponseProcessingTime", duration.TotalMilliseconds, 
            new Dictionary<string, string> { { "surveyId", surveyId } });
    }
}
```

### Health Checks
```csharp
builder.Services.AddHealthChecks()
    .AddCheck<CosmosDbHealthCheck>("cosmosdb")
    .AddCheck<RedisHealthCheck>("redis")
    .AddCheck<QualtricsApiHealthCheck>("qualtrics-api");

app.MapHealthChecks("/health");
```

---

## 🧪 Testing Guidelines

### Unit Tests for Services
```csharp
public class QualtricsServiceTests
{
    [Fact]
    public async Task GetResponsesAsync_WhenApiReturnsData_ParsesCorrectly()
    {
        // Arrange
        var mockHttp = new MockHttpMessageHandler();
        mockHttp.When("https://*/API/v3/surveys/*/responses")
                .Respond("application/json", "{ \"result\": { \"elements\": [] } }");
        
        var service = new QualtricsService(mockHttp.ToHttpClient(), _options);
        
        // Act
        var result = await service.GetResponsesAsync("SV_123");
        
        // Assert
        Assert.NotNull(result);
    }
}
```

### Integration Tests for API
```csharp
public class SurveysControllerTests : IClassFixture<WebApplicationFactory<Program>>
{
    [Fact]
    public async Task GetSurveys_ReturnsOkWithSurveyList()
    {
        // Arrange
        var client = _factory.CreateClient();
        
        // Act
        var response = await client.GetAsync("/api/surveys");
        
        // Assert
        response.EnsureSuccessStatusCode();
        var surveys = await response.Content.ReadFromJsonAsync<List<SurveyDto>>();
        Assert.NotEmpty(surveys);
    }
}
```

---

## 🚀 Deployment Guidelines

### Infrastructure as Code (Bicep)
- Store all Azure resources in `infrastructure/` directory
- Use parameters files for environment-specific config
- Version control all IaC files
- Test infrastructure changes in dev environment first

### Configuration Management System

**Single Source of Truth**: `azure-resources.json`

All PowerShell scripts and C# application configuration now use centralized configuration:

```powershell
# PowerShell scripts
. "$PSScriptRoot\AzureResourceConfig.ps1"
$config = Get-AzureResourceConfig -Environment dev

# Access configuration
$appServiceName = $config.appService.name
$cosmosDbEndpoint = $config.cosmosDb.endpoint
$resourceGroup = $config.resourceGroup.name
```

**C# Application**: Use `Update-AppSettings.ps1` to sync appsettings.json:
```powershell
.\scripts\Update-AppSettings.ps1 -Environment dev -DiscoverResources
```

**Benefits**:
- ✅ Single configuration file for all environments
- ✅ No hardcoded resource names in scripts
- ✅ Faster execution (eliminated 60+ unnecessary Azure queries)
- ✅ Easy environment switching
- ✅ Version-controlled configuration

**Scripts Using Configuration** (10 total):
- `scripts/Test-WebhookIntegration.ps1`
- `scripts/deploy-app.ps1`
- `infrastructure/scripts/Assign-RBACRoles.ps1`
- `rbac/assign-rbac-roles.ps1`
- `rbac/assign-rbac-to-user.ps1`
- `rbac/verify-rbac.ps1`
- `scripts/deploy-research-improvements.ps1`
- `tests/api/test-api.ps1`
- `scripts/provision-azure-infrastructure.ps1`
- `scripts/validate-environment.ps1`

**Reference**: See `DK-CONFIGURATION-MANAGEMENT-v1.0.0.md` for comprehensive configuration patterns.

### CI/CD Pipeline
- Separate pipelines for backend, frontend, and infrastructure
- Run tests before deployment
- Use staging slots for zero-downtime deployment
- Automate database migrations
- Validate health checks post-deployment

---

## 💰 Infrastructure Optimization Principles

### 1. Constraint-Driven Architecture

**Context**: This project serves **≤100 concurrent users** (small team deployment).

**Optimization Strategy**: Right-size all Azure services for actual usage, not theoretical capacity.

**Key Decisions**:
- App Service Plan: **B2** (not P1v3) - 2 cores, 3.5GB RAM sufficient for small team
- SignalR Service: **Free F1** (not Standard S1) - 20 connections adequate for team size
- Service Bus: **Basic** (not Standard) - Low message volume doesn't justify Standard tier
- Cosmos DB: **Serverless** - Pay-per-request optimal for variable workload
- Redis Cache: **Basic C1** (production) - 1GB sufficient for hot data

**Cost Impact**: Production environment $175/month (vs $328/month with premium tiers) = **47% reduction**

**Reference**: See `DK-AZURE-INFRASTRUCTURE-OPTIMIZATION-v1.0.0.md` for comprehensive optimization patterns.

---

### 2. Free Tier Monitoring Requirements

**Critical**: Free tier services require active monitoring to prevent service degradation.

**SignalR Free F1 Monitoring** (20 connection limit):
```bash
# Set alert at 75% capacity (15 connections)
az monitor metrics alert create \
  --name "SignalR-Connection-Limit-Warning" \
  --resource-group "rg-qualtrics-dashboard-prod" \
  --scopes "/subscriptions/.../providers/Microsoft.SignalRService/SignalR/signalr-dashboard-prod" \
  --condition "avg connections > 15" \
  --description "Alert when approaching Free tier 20-connection limit"
```

**Upgrade Path**: If sustained >15 connections, upgrade to Standard S1 (+$50/month for 1,000 concurrent connections).

**Log Analytics Monitoring** (5GB/month free):
```kql
// Alert if approaching 150MB daily average (5GB ÷ 30 days)
Usage
| where TimeGenerated > ago(1d)
| summarize DataVolume = sum(Quantity) / 1024  // Convert to GB
| where DataVolume > 0.15  // 150MB threshold
```

**Lesson Learned**: Document monitoring requirements BEFORE deploying free-tier services.

---

### 3. Infrastructure-First Deployment Strategy

**Recommendation**: Deploy dev infrastructure BEFORE starting deep application development.

**Rationale**:
1. **Early Validation**: Test Azure service connections before code investment
2. **Real Services**: Develop against actual Cosmos DB, SignalR, Redis (not mocks)
3. **Issue Discovery**: Find infrastructure problems when cheap to fix
4. **Cost Efficiency**: Dev environment only $65/month for validation
5. **Iterative Development**: Adjust infrastructure AND code simultaneously

**Connection to Bootstrap Learning**: Infrastructure-first = bootstrap learning applied to DevOps
- Same principle: Test assumptions against reality early
- Same benefit: Discover mismatches when cheap to fix  
- Same risk avoided: Elaborate work invalidated late

**Implementation Path** (from TODO.md):
1. Week 1-2: Deploy dev infrastructure ($65/month)
2. Week 3-4: Validate all Azure connections (Cosmos DB, SignalR, Redis, Service Bus)
3. Week 5+: Begin application development with real services

---

### 4. Fact-Checking Discipline for Technical Documentation

**Requirement**: All technical claims must be empirically verifiable.

**Examples of Unsubstantiated Claims Removed**:
- ❌ "< 2 seconds latency" (no performance testing conducted)
- ❌ "< 500ms response time p95" (no empirical data)
- ❌ "100x RU efficiency" (exaggerated comparison)
- ❌ "98/100 security score" (fictional metric)

**Professional Standard**:
- ✅ Cite sources (Microsoft Learn, Azure documentation)
- ✅ Document actual measurements (when testing completed)
- ✅ Use qualifiers ("estimated", "projected", "expected")
- ✅ Provide upgrade decision matrices (not aspirational claims)

**Reference**: See `empirical-validation.instructions.md` for comprehensive fact-checking protocols.

---

### 5. Trade-Off Documentation

**Principle**: Document capabilities lost with cost optimization decisions.

**SignalR Free F1 Trade-Offs**:
| Feature | Free F1 | Standard S1 | Impact |
|---------|---------|-------------|--------|
| Concurrent Connections | 20 | 1,000 | ⚠️ Hard limit - monitor carefully |
| Messages/Day | 20,000 | 1,000,000 | ⚠️ ~14 messages/minute average |
| SLA | None | 99.9% | ⚠️ No uptime guarantee |
| Auto-Scale | No | Yes | Manual upgrade required if exceeded |

**Service Bus Basic Trade-Offs**:
| Feature | Basic | Standard | Impact |
|---------|-------|----------|--------|
| Max Queue Size | 1 GB | 1 GB | ✅ Same capacity |
| Topics/Subscriptions | ❌ Not supported | ✅ Supported | ⚠️ Use queues only |
| Transactions | ❌ Not supported | ✅ Supported | ⚠️ No batch operations |
| Scheduled Messages | ❌ Not supported | ✅ Supported | ⚠️ Schedule externally |

**Professional Practice**: Communicate trade-offs to stakeholders before deployment.

---

### 6. Upgrade Decision Matrix

**Purpose**: Clear guidance on when to scale up Azure services.

| Service | Current SKU | Trigger | Upgrade Target | Cost Delta |
|---------|-------------|---------|----------------|------------|
| SignalR | Free F1 | Sustained >15 connections | Standard S1 | +$50/month |
| App Service | B2 | CPU >70% sustained | B3 (4 core) | +$36/month |
| Redis | Basic C1 | Memory >80% | Basic C2 (2.5GB) | +$23/month |
| Cosmos DB | Serverless | >3,000 RU/s sustained | Provisioned 4000 RU/s | +$200/month |
| Log Analytics | Pay-per-GB | >5GB/month | 100GB reservation | +$120/month |

**Monitoring Queries**: See `DK-AZURE-INFRASTRUCTURE-OPTIMIZATION-v1.0.0.md` for complete monitoring scripts.

---

## 🧠 Alex Cognitive Integration

When working on this project:

1. **Reference Domain Knowledge**: 
   - `DK-QUALTRICS-API-v1.0.0.md` - Qualtrics API patterns and best practices
   - `DK-DASHBOARD-ARCHITECTURE-v1.0.0.md` - Real-time dashboard architecture
   - **`DK-AZURE-INFRASTRUCTURE-OPTIMIZATION-v1.0.0.md`** - Cost optimization strategies *(Oct 31, 2025)*
   - **`DK-CONFIGURATION-MANAGEMENT-v1.0.0.md`** - Centralized configuration architecture *(NEW - Nov 4, 2025)*
   - **`DK-DOCUMENTATION-EXCELLENCE-v1.2.0.md`** - Systematic refactoring with privacy-first alignment *(Nov 3, 2025)*

2. **Apply Azure Best Practices**: 
   - `azure.instructions.md` - General Azure development guidelines
   - `azurecosmosdb.instructions.md` - Cosmos DB optimization patterns
   - Infrastructure optimization principles (above) - Right-sizing for ≤100 users

3. **Bootstrap Learning**: 
   - If encountering unfamiliar Qualtrics API concepts → Use conversational learning, create DK files
   - If uncertain about infrastructure decisions → Deploy dev environment first ($65/month validation)
   - If adding new Azure services → Research free tier capabilities and monitoring requirements

4. **Meditation Triggers**: 
   - After completing major features → Consolidate learnings
   - When discovering cross-domain patterns → Document connections
   - Post-implementation → Create/update synaptic connections in DK files
   - **After infrastructure optimization → Document cost savings and lessons learned** (completed Oct 31, 2025)

5. **Fact-Checking Requirements**:
   - Verify all technical claims against Microsoft Learn
   - Remove unsubstantiated performance metrics
   - Document actual measurements when testing completed
   - Use qualifiers for estimates ("projected", "expected")

---

## Embedded Synapse Network

### Key Connections

- [DK-QUALTRICS-API-v1.0.0.md] (0.97, implements, forward) - "Qualtrics API integration patterns"
- [DK-DASHBOARD-ARCHITECTURE-v1.0.0.md] (0.94, implements, forward) - "Real-time dashboard architecture patterns"
- [DK-AZURE-INFRASTRUCTURE-OPTIMIZATION-v1.0.0.md] (0.97, applies, bidirectional) - "Infrastructure cost optimization for ≤100 users" *(Oct 31, 2025)*
- [DK-AZURE-RBAC-ARCHITECTURE-v1.0.0.md] (0.95, implements, bidirectional) - "Azure permission management with Test-AzurePermissions.ps1 and Admin-AssignRBAC.ps1" *(Nov 7, 2025)*
- [DK-CONFIGURATION-MANAGEMENT-v1.0.0.md] (0.98, integrates, bidirectional) - "Centralized configuration architecture for all scripts and C# application" *(Nov 4, 2025)*
- [DK-PROFESSIONAL-CAREER-READINESS-v1.0.0.md] (0.9, implements, bidirectional) - "Phase 3C completion: 5 custom hooks provide declarative API/SignalR interface for Phase 3D components" *(NEW - Nov 7, 2025)*
- [AZURE-RESOURCES-QUICK-REFERENCE.md] (0.99, references, unidirectional) - "Azure resource names, commands, and endpoints for quick access" *(Nov 4, 2025)*
- [empirical-validation.instructions.md] (0.92, validates, bidirectional) - "Fact-checking discipline for technical claims"
- [bootstrap-learning.instructions.md] (0.89, applies, forward) - "Infrastructure-first = bootstrap learning for DevOps"
- [azure.instructions.md] (0.88, guides, bidirectional) - "Azure development best practices"
- [azurecosmosdb.instructions.md] (0.91, optimizes, forward) - "Cosmos DB optimization patterns"

### Activation Patterns

- **Starting new feature** → Reference DK-QUALTRICS-API and DK-DASHBOARD-ARCHITECTURE
- **Infrastructure decisions** → Apply DK-AZURE-INFRASTRUCTURE-OPTIMIZATION principles
- **Permission troubleshooting** → Use Test-AzurePermissions.ps1 and reference DK-AZURE-RBAC-ARCHITECTURE
- **Managed identity RBAC needed** → Admin runs Admin-AssignRBAC.ps1 (DK-AZURE-RBAC-ARCHITECTURE patterns)
- **Configuration management** → Use DK-CONFIGURATION-MANAGEMENT patterns (azure-resources.json)
- **Script development** → Load configuration via AzureResourceConfig.ps1
- **C# application updates** → Sync appsettings.json with Update-AppSettings.ps1
- **Azure service selection** → Check free tier capabilities and monitoring requirements
- **Making technical claims** → Apply empirical-validation fact-checking discipline
- **Uncertain about approach** → Deploy dev infrastructure first (infrastructure-first strategy)
- **Cost optimization needed** → Reference right-sizing strategies for ≤100 users
- **Monitoring setup** → Reference alert thresholds from upgrade decision matrix
- **Need resource names** → Check azure-resources.json or AZURE-RESOURCES-QUICK-REFERENCE
- **Debugging deployment** → Use configuration system for correct resource identification

---

*Qualtrics Dashboard Project Instructions - Development patterns with infrastructure optimization operational*
