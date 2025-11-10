# Domain Knowledge: Azure Infrastructure for Real-Time Disposition Dashboard v1.0.0

**Version**: 1.0.0 UNNILUNNILNIL (un-nil-un-nil-nil)
**Domain**: Azure Infrastructure Architecture & Service Selection
**Specialized Focus**: Real-Time Disposition Dashboard on Azure
**Status**: Active - Decision Framework
**Last Updated**: 2025-11-10

---

## 🎯 Purpose & Context

**Objective**: Provide comprehensive guidance for selecting the right Azure infrastructure services for a real-time Qualtrics disposition dashboard, learning from previous implementation challenges.

**Critical Success Factors**:
- ✅ **Reliability**: No production failures or service disruptions
- ✅ **Cost Predictability**: No surprise bills or runaway costs
- ✅ **Operational Simplicity**: Minimal maintenance overhead
- ✅ **Performance**: Sub-60 second update latency
- ✅ **Scalability**: Handle growth without architecture changes

**Learning from Past Issues**: This document explicitly addresses common Azure pitfalls to avoid repeating previous bad experiences.

---

## 📊 Project Requirements Analysis

### Core Technical Requirements

**1. Backend API Hosting**
- ASP.NET Core 8+ application
- REST API endpoints (GET /api/disposition/*)
- SignalR hub for real-time broadcasting
- Background service (DistributionPollingService) running continuously
- Health checks and monitoring endpoints

**2. Real-Time Communication**
- WebSocket support for SignalR
- Broadcast to 50+ concurrent users
- Sub-second message delivery
- Connection state management
- Automatic reconnection support

**3. Data Storage**
- Time-series disposition snapshots (365 days retention)
- Query pattern: Partition by surveyId, filter by timestamp
- Write-heavy workload (polling every 30-60 seconds)
- Read pattern: Latest aggregate + historical trends
- Estimated: 10-100 surveys × 1,440 snapshots/day = 14,400-144,000 writes/day

**4. Background Processing**
- Timer-based polling (30-60 second intervals)
- External API calls (Qualtrics)
- Retry logic with exponential backoff
- Must survive process restarts
- Needs configuration management

**5. Configuration & Secrets**
- Qualtrics API tokens (sensitive)
- Connection strings
- Environment-specific settings (dev/stg/prod)
- Runtime configuration updates without redeployment

**6. Monitoring & Observability**
- Application performance monitoring
- Custom metrics (poll success rate, update latency)
- Logging and diagnostics
- Alerts for failures
- Cost tracking

---

## 🏗️ Azure Service Options Analysis

### 1. Compute Options (Backend Hosting)

#### Option A: Azure App Service (Web App)

**What It Is**: Fully managed PaaS for hosting web applications

**Pros**:
- ✅ **Simple Deployment**: Built-in CI/CD, deployment slots
- ✅ **Easy Scaling**: Vertical (tier) and horizontal (instances) scaling
- ✅ **Built-in Features**: Health checks, auto-restart, logging
- ✅ **WebSocket Support**: Native SignalR support
- ✅ **Background Tasks**: Can run BackgroundService in same process
- ✅ **Lower Learning Curve**: Familiar to most developers
- ✅ **Always On**: Option to keep app loaded (no cold starts)

**Cons**:
- ⚠️ **Cost at Scale**: Can get expensive with higher tiers (Premium/Isolated)
- ⚠️ **Background Service Limitations**: Single instance can be restarted, losing in-flight work
- ⚠️ **Scaling Complexity**: Background service runs on all instances (coordination needed)
- ⚠️ **Resource Sharing**: API and background polling compete for CPU/memory

**Best For**:
- Small to medium scale (< 20 surveys)
- Unified deployment (API + polling in one app)
- Teams familiar with traditional web hosting

**Cost Estimate** (US East):
- Basic B1 (1 core, 1.75 GB RAM): ~$13/month
- Standard S1 (1 core, 1.75 GB RAM): ~$70/month (Always On, deployment slots)
- Premium P1v3 (2 core, 8 GB RAM): ~$140/month (production-ready)

**⚠️ Common Pitfalls**:
- Running background services on multiple instances without coordination = duplicate polling
- Not enabling "Always On" = cold starts and gaps in polling
- Underestimating memory for concurrent SignalR connections

---

#### Option B: Azure Container Apps

**What It Is**: Serverless container platform with automatic scaling

**Pros**:
- ✅ **Modern Architecture**: Container-based, microservices-ready
- ✅ **Auto-scaling**: Scale to zero when idle, scale out on demand
- ✅ **Cost Efficient**: Pay per second of execution (consumption model)
- ✅ **Separation of Concerns**: API and background service as separate containers
- ✅ **Built-in Ingress**: HTTPS, custom domains, SSL
- ✅ **Dapr Integration**: State management, pub/sub patterns
- ✅ **Revisions**: Easy rollback, blue-green deployments

**Cons**:
- ⚠️ **Scale to Zero Problem**: Background polling needs to run continuously (min replicas = 1)
- ⚠️ **Cold Start Latency**: First request after scaling can be slow (mitigated by min replicas)
- ⚠️ **Complexity**: Requires Docker/container knowledge
- ⚠️ **Debugging**: Slightly harder than App Service
- ⚠️ **Less Mature**: Newer service (started 2022)

**Best For**:
- Teams comfortable with containers
- Microservices architecture (API + polling as separate apps)
- Variable/unpredictable load patterns

**Cost Estimate** (US East, Consumption plan):
- vCPU: $0.000012/second (~$31/month for 1 vCPU always-on)
- Memory: $0.000002/GB/second (~$5/month for 2 GB always-on)
- Total: ~$36-40/month for single replica

**⚠️ Common Pitfalls**:
- Setting min replicas = 0 for polling service = no background processing
- Not configuring readiness/liveness probes = restart loops
- Underestimating cold start impact on user experience
- Container image size bloat = slow deployment and increased storage costs

---

#### Option C: Azure Functions (Consumption or Premium)

**What It Is**: Serverless event-driven compute platform

**Pros**:
- ✅ **Serverless**: No infrastructure management
- ✅ **Event-Driven**: Timer triggers for polling, HTTP triggers for API
- ✅ **Auto-scaling**: Built-in, no configuration
- ✅ **Cost-Effective**: Consumption plan is very cheap for low/medium volume
- ✅ **Isolated Functions**: Each function scales independently

**Cons**:
- ❌ **SignalR Limitations**: Requires separate Azure SignalR Service (can't host hub in Functions)
- ⚠️ **Stateless**: No in-memory state persistence across invocations
- ⚠️ **Cold Starts**: Consumption plan has 5-10 second cold starts
- ⚠️ **Timeout Limits**: Consumption = 5 min default (10 min max), Premium = 30 min
- ⚠️ **Development Experience**: Different paradigm from traditional apps
- ⚠️ **Debugging Complexity**: Harder to debug locally with full context

**Best For**:
- Simple, event-driven architectures
- True serverless mindset (no persistent connections)
- Intermittent workloads with long idle periods

**Cost Estimate** (Consumption plan):
- 1M executions + 400,000 GB-seconds: ~$20/month
- Premium Plan (always-on): ~$160/month (EP1)

**⚠️ Common Pitfalls**:
- Using Consumption plan for continuous polling = cold starts every few minutes
- Not understanding SignalR Service is separate and has its own costs
- Timer trigger skew and missed executions under heavy load
- Exceeding timeout limits on long-running operations

---

#### **🎯 Recommendation: Azure Container Apps**

**Reasoning**:
1. **Separation of Concerns**: API and polling service as independent containers
2. **Cost-Effective**: Consumption model with min replicas = 1 for polling
3. **Modern & Flexible**: Room to grow into microservices if needed
4. **Debugging**: Better than Functions, comparable to App Service with right tools
5. **Avoids Past Issues**: If App Service caused problems (scaling, resource contention), containers provide better isolation

**Alternative**: If team is NOT comfortable with containers → **Azure App Service Standard tier** with careful background service coordination

---

### 2. Real-Time Communication (SignalR)

#### Option A: Self-Hosted SignalR (in App Service/Container)

**What It Is**: SignalR Hub hosted in your ASP.NET Core application

**Pros**:
- ✅ **No Extra Cost**: Included with compute service
- ✅ **Simpler Architecture**: One fewer service to manage
- ✅ **Direct Control**: Full control over hub logic and scaling

**Cons**:
- ❌ **Sticky Sessions Required**: Load balancer must route same client to same instance
- ❌ **Connection Limits**: Limited by instance memory/CPU
- ❌ **Scale-Out Complexity**: Requires backplane (Redis) for multiple instances
- ❌ **Server Resource Usage**: WebSocket connections consume memory

**Best For**:
- Single instance deployments
- < 100 concurrent connections
- Cost-sensitive projects

**⚠️ Common Pitfalls**:
- Not configuring sticky sessions in load balancer = connection failures
- Underestimating memory per connection (1-2 KB per connection)
- Process restarts drop all connections (no graceful reconnection)

---

#### Option B: Azure SignalR Service

**What It Is**: Fully managed SignalR service with infinite scale

**Pros**:
- ✅ **Managed Service**: No backplane setup, no sticky sessions
- ✅ **Infinite Scale**: Handle 1,000+ concurrent connections easily
- ✅ **High Availability**: Built-in redundancy and failover
- ✅ **Connection Offloading**: Frees up backend compute resources
- ✅ **Serverless Mode**: Works with Azure Functions
- ✅ **Default Mode**: Works with self-hosted hubs

**Cons**:
- ⚠️ **Additional Cost**: Starts at ~$50/month (Free tier: 20 connections, not viable)
- ⚠️ **Complexity**: Extra configuration (connection strings, negotiation)
- ⚠️ **Latency**: Slight overhead vs direct WebSocket (< 50ms typically)

**Best For**:
- 50+ concurrent users (your requirement)
- Production applications requiring high availability
- Multi-instance deployments

**Cost Estimate**:
- Free: 20 concurrent connections, 20K messages/day (too small)
- Standard: 1K concurrent connections, 1M messages/day: ~$50/month
- Standard: 10K concurrent connections, 10M messages/day: ~$500/month

**⚠️ Common Pitfalls**:
- Starting with Free tier and hitting limits = bad production experience
- Not configuring proper service mode (Default vs Serverless)
- Missing connection string configuration = negotiation failures

---

#### **🎯 Recommendation: Azure SignalR Service (Standard - 1K unit)**

**Reasoning**:
1. **Requirement Met**: 50+ concurrent users well within 1K connection limit
2. **Reliability**: Managed service eliminates sticky session issues
3. **Offloading**: Frees backend compute for API/polling work
4. **Future-Proof**: Room to grow to 1,000 users without changes
5. **Past Issues**: If scaling was a problem before, managed SignalR solves it

**Cost**: ~$50/month is acceptable for production-quality real-time infrastructure

---

### 3. Data Storage Options

#### Option A: Azure Cosmos DB (NoSQL)

**What It Is**: Globally distributed, multi-model NoSQL database

**Pros**:
- ✅ **Performance**: Single-digit millisecond latency
- ✅ **Scalability**: Infinite scale, no limits
- ✅ **Partitioning**: Excellent for surveyId partition key
- ✅ **Flexible Schema**: JSON documents, easy to evolve
- ✅ **Time-Series Optimized**: TTL for auto-deletion
- ✅ **Global Distribution**: Multi-region with one click (if needed)

**Cons**:
- ⚠️ **Cost Complexity**: RU (Request Unit) model requires understanding
- ⚠️ **Query Optimization Required**: Cross-partition queries are expensive
- ⚠️ **Learning Curve**: Different from SQL databases
- ⚠️ **Indexing Overhead**: Default indexes everything (can increase costs)

**Cost Estimate** (Provisioned throughput):
- 400 RU/s (minimum): ~$24/month
- 1,000 RU/s: ~$60/month
- Serverless: $0.25 per million RUs + storage (good for variable workloads)

**Workload Analysis**:
- Writes: 100 surveys × 60 polls/hour = 6,000 writes/hour = ~20 RUs each = 120K RU/hour = 33 RU/s average
- Reads: 50 users × 4 dashboard views/hour = 200 reads/hour = ~5 RUs each = 1,000 RU/hour = < 1 RU/s average
- **Total**: ~34-50 RU/s average → **400 RU/s provisioned handles it with headroom**

**⚠️ Common Pitfalls**:
- Not using partition key in queries = cross-partition scans = high RU consumption
- Over-indexing = wasted RUs on every write
- Not monitoring RU consumption = surprise bills
- Using provisioned throughput for spiky workloads = wasted capacity

---

#### Option B: Azure SQL Database (Serverless)

**What It Is**: Managed relational database with serverless pricing

**Pros**:
- ✅ **Familiar**: Standard SQL, well-understood
- ✅ **Serverless Model**: Auto-pause when idle, pay per use
- ✅ **Strong Consistency**: ACID transactions
- ✅ **Tooling**: Rich ecosystem (SSMS, Azure Data Studio)
- ✅ **Cost-Effective**: Serverless can be cheaper for low/variable workloads

**Cons**:
- ⚠️ **Cold Start**: 30-60 second resume from paused state
- ⚠️ **Scaling Limits**: Max 40 vCores in serverless
- ⚠️ **Time-Series Performance**: Less optimized than Cosmos DB for this pattern
- ⚠️ **Partitioning Complexity**: Requires manual table partitioning for optimal performance

**Cost Estimate** (Serverless):
- Basic (1 vCore, 2 GB RAM): ~$5/month if mostly idle
- General Purpose (2 vCore, 10 GB RAM): ~$75/month always-on

**⚠️ Common Pitfalls**:
- Auto-pause delays = poor user experience (30-60s first query)
- Not disabling auto-pause for production = reliability issues
- Underestimating query complexity for time-series aggregations
- Table scans on large datasets = slow queries

---

#### Option C: Azure Table Storage

**What It Is**: NoSQL key-value store, part of Azure Storage

**Pros**:
- ✅ **Extremely Cheap**: $0.045 per GB/month storage
- ✅ **Simple**: Key-value model, easy to understand
- ✅ **Scalable**: Petabyte scale
- ✅ **Fast Writes**: Optimized for high-throughput writes

**Cons**:
- ❌ **Limited Query**: Only PartitionKey + RowKey indexing
- ❌ **No Complex Queries**: Can't do aggregations, joins, or filters efficiently
- ❌ **No TTL**: Manual cleanup required (no auto-expiration)
- ❌ **1 MB Entity Limit**: May not fit complex snapshots

**Best For**:
- Simple key-value lookups
- Extremely cost-sensitive projects
- Append-only logs

**⚠️ Common Pitfalls**:
- Assuming it works like Cosmos DB = poor query performance
- Not designing PartitionKey/RowKey correctly = table scans
- No TTL = manual cleanup jobs required = more complexity

---

#### **🎯 Recommendation: Azure Cosmos DB (Serverless mode)**

**Reasoning**:
1. **Perfect Fit**: Time-series data with surveyId partition key
2. **Performance**: Sub-10ms queries for dashboard
3. **TTL Feature**: Auto-delete after 365 days (no manual cleanup)
4. **Serverless Cost**: ~$30-40/month for expected workload (cheaper than provisioned 400 RU/s)
5. **Flexibility**: Schema evolution without migrations
6. **Past Issues**: If SQL was used before and had scaling/performance issues, Cosmos DB is designed for this

**Serverless vs Provisioned**:
- **Use Serverless**: Variable load, < 5,000 RU/s peak, development/staging
- **Use Provisioned**: Predictable load, > 400 RU/s continuous, production with strict SLAs

**For This Project**: Start with **Serverless** → monitor → switch to Provisioned if needed

---

### 4. Configuration & Secrets Management

#### Option A: Azure Key Vault

**What It Is**: Managed secrets, keys, and certificates store

**Pros**:
- ✅ **Security**: HSM-backed, audited access
- ✅ **Integration**: Native .NET SDK support
- ✅ **Versioning**: Secret rotation without downtime
- ✅ **Access Control**: RBAC + managed identities
- ✅ **Compliance**: Meets SOC, PCI, HIPAA standards

**Cons**:
- ⚠️ **Cost**: $0.03 per 10K transactions (can add up)
- ⚠️ **Caching Required**: Don't fetch on every request (cache for 5+ minutes)
- ⚠️ **Startup Delay**: Fetching secrets adds ~500ms to startup

**Cost Estimate**:
- Standard tier: ~$0.03 per 10K operations
- Expected: 3 secrets × 12 fetches/hour = 36/hour × 720 hours = ~26K/month = $0.08/month
- **Essentially free** for typical usage

**Best Practice**:
```csharp
// Cache secrets in memory for 5 minutes
services.AddAzureKeyVault(options =>
{
    options.ReloadInterval = TimeSpan.FromMinutes(5);
});
```

**⚠️ Common Pitfalls**:
- Fetching on every request = high costs + latency
- Not using managed identity = credential management overhead
- Not caching = 500ms delay on every API call

---

#### Option B: App Configuration + Environment Variables

**What It Is**: Azure App Configuration for settings, env vars for secrets

**Pros**:
- ✅ **Lower Cost**: App Config has free tier (1K requests/day)
- ✅ **Feature Flags**: Built-in feature management
- ✅ **Dynamic Updates**: Change config without restart
- ✅ **Simple**: Environment variables for secrets (no SDK needed)

**Cons**:
- ⚠️ **Less Secure**: Env vars visible in portal/logs if not careful
- ⚠️ **No HSM**: Not as secure as Key Vault
- ⚠️ **Manual Rotation**: Secret updates require manual deployment

**Best For**:
- Non-production environments
- Cost-sensitive projects
- Simple configuration needs

---

#### **🎯 Recommendation: Azure Key Vault with Managed Identity**

**Reasoning**:
1. **Security Best Practice**: Qualtrics API token is sensitive
2. **Cost Negligible**: < $1/month for typical usage
3. **Compliance**: May be required for enterprise deployments
4. **Rotation**: Easy secret updates without redeployment
5. **Past Issues**: If secrets were exposed/mismanaged before, Key Vault solves it

**Implementation**:
```csharp
// Startup.cs
builder.Configuration.AddAzureKeyVault(
    new Uri($"https://{keyVaultName}.vault.azure.net/"),
    new DefaultAzureCredential());
```

---

### 5. Monitoring & Observability

#### Option: Azure Application Insights (Recommended)

**What It Is**: APM (Application Performance Monitoring) service

**Pros**:
- ✅ **Native Integration**: Built into Azure services
- ✅ **Automatic Instrumentation**: Minimal code changes
- ✅ **Rich Telemetry**: Requests, dependencies, exceptions, custom metrics
- ✅ **Powerful Queries**: Kusto Query Language (KQL)
- ✅ **Alerting**: Based on metrics, log patterns
- ✅ **Application Map**: Visualize dependencies

**Cost Estimate**:
- First 5 GB/month: Free
- After: $2.30 per GB ingested
- Expected: 100-500 MB/month = Free tier sufficient

**Key Metrics to Track**:
```csharp
// Custom metrics
telemetry.TrackMetric("PollingSuccessRate", successRate);
telemetry.TrackMetric("UpdateLatency", latencyMs);
telemetry.TrackMetric("ActiveDistributions", count);
telemetry.TrackMetric("QualtricsAPICallDuration", durationMs);
```

**⚠️ Common Pitfalls**:
- Logging PII data = compliance violation
- Excessive logging = cost overruns (5+ GB/month)
- Not setting up alerts = undetected failures
- Not using sampling for high-volume apps = costs explode

---

## 🎯 Recommended Architecture

### **Production-Ready Stack**

```
┌─────────────────────────────────────────────────────────────────┐
│                         Azure Front Door                         │
│                  (Optional - Global CDN/WAF)                     │
└────────────────────────────┬────────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────────┐
│                  Azure Container Apps Environment                │
│  ┌──────────────────────┐      ┌──────────────────────────┐    │
│  │  API Container App   │      │  Polling Container App   │    │
│  │  - REST API          │      │  - Background Service    │    │
│  │  - SignalR Hub       │      │  - Timer: 30-60s         │    │
│  │  - Health Checks     │      │  - Qualtrics API Client  │    │
│  │  Min/Max: 1-10       │      │  Min/Max: 1-3            │    │
│  └──────────────────────┘      └──────────────────────────┘    │
└────────────────────────────────────────────────────────────────┘
           │                                │
           │ (Negotiate)                    │ (Poll API)
           ▼                                ▼
┌──────────────────────┐        ┌──────────────────────┐
│ Azure SignalR Service│        │  Qualtrics REST API  │
│ Standard (1K unit)   │        │  (External)          │
│ - WebSocket          │        └──────────────────────┘
│ - 1K connections     │                    │
└──────────────────────┘                    │ (Write snapshots)
           │                                ▼
           │                    ┌──────────────────────────┐
           │ (Broadcast)        │  Azure Cosmos DB         │
           │                    │  (Serverless NoSQL)      │
           └───────────────────▶│  - DistributionSnapshot  │
                                │  - DispositionAggregate  │
                                │  - 365 day TTL           │
                                └──────────────────────────┘
                                            │
                                            │ (Read secrets)
                                            ▼
                                ┌──────────────────────────┐
                                │  Azure Key Vault         │
                                │  - Qualtrics API Token   │
                                │  - Managed Identity      │
                                └──────────────────────────┘
                                            │
                                            │ (Telemetry)
                                            ▼
                                ┌──────────────────────────┐
                                │  Application Insights    │
                                │  - Logs, Metrics, Traces │
                                │  - Alerts                │
                                └──────────────────────────┘
```

### **Cost Breakdown (Monthly)**

| Service | Configuration | Cost (USD) |
|---------|--------------|------------|
| **Container Apps (API)** | 1 vCPU, 2 GB RAM, 1 min replica | ~$36 |
| **Container Apps (Polling)** | 0.5 vCPU, 1 GB RAM, 1 min replica | ~$18 |
| **Azure SignalR Service** | Standard, 1K connections | ~$50 |
| **Cosmos DB** | Serverless, ~3M RUs/month | ~$35 |
| **Key Vault** | Standard, < 10K operations | ~$1 |
| **Application Insights** | < 5 GB ingestion | Free |
| **Container Registry** | Basic | ~$5 |
| **Total** | | **~$145/month** |

**Scaling to 100 surveys**:
- Polling CPU increases: +0.5 vCPU = +$18/month
- Cosmos DB increases: ~3x = +$70/month
- **Total at 100 surveys**: ~$235/month

---

## 🚨 Avoiding Common Azure Pitfalls

### 1. **Cost Surprises**

**Problem**: Unexpected bills from misconfigured services

**Solutions**:
- ✅ **Set Budget Alerts**: Azure Cost Management → $200/month alert threshold
- ✅ **Use Serverless**: Cosmos DB serverless, Container Apps consumption
- ✅ **Monitor Daily**: Check cost analysis dashboard weekly
- ✅ **Right-Size**: Don't over-provision compute (start small, scale up)
- ✅ **Delete Non-Prod**: Shut down dev/staging outside business hours

**Pro Tip**: Use Azure Cost Management "Cost by Resource" view to identify top spenders

---

### 2. **Performance Issues**

**Problem**: Slow queries, high latency, timeouts

**Solutions**:
- ✅ **Cosmos DB**: Always use partition key in queries (surveyId)
- ✅ **Caching**: Cache survey metadata (changes infrequently)
- ✅ **Indexing**: Optimize Cosmos DB indexing policy (exclude unnecessary fields)
- ✅ **Connection Pooling**: Reuse HttpClient, CosmosClient instances
- ✅ **Async All The Way**: No `.Result` or `.Wait()` calls

**Cosmos DB Query Pattern**:
```csharp
// ✅ GOOD - Uses partition key
container.GetItemLinqQueryable<DistributionSnapshot>()
    .Where(s => s.SurveyId == surveyId && s.Timestamp > startDate)
    .ToList();

// ❌ BAD - Cross-partition scan
container.GetItemLinqQueryable<DistributionSnapshot>()
    .Where(s => s.Timestamp > startDate)
    .ToList();
```

---

### 3. **Reliability Issues**

**Problem**: Service restarts, connection drops, data loss

**Solutions**:
- ✅ **Health Checks**: Implement liveness and readiness probes
- ✅ **Graceful Shutdown**: Handle SIGTERM signal properly
- ✅ **Retry Logic**: Exponential backoff for transient failures
- ✅ **Idempotency**: Use upsert (not insert) for snapshots
- ✅ **Circuit Breaker**: Stop hammering failing APIs

**Container Apps Health Probe**:
```yaml
probes:
  liveness:
    httpGet:
      path: /health/live
      port: 8080
    initialDelaySeconds: 10
    periodSeconds: 30
  readiness:
    httpGet:
      path: /health/ready
      port: 8080
    initialDelaySeconds: 5
    periodSeconds: 10
```

---

### 4. **Scaling Problems**

**Problem**: App doesn't scale, or scales incorrectly

**Solutions**:
- ✅ **Separate Concerns**: API and polling as separate containers
- ✅ **Singleton Polling**: Ensure only 1 replica of polling service runs
- ✅ **Stateless API**: No in-memory state in API containers (use Cosmos/Redis)
- ✅ **Auto-Scaling Rules**: CPU > 70% = scale out
- ✅ **Max Replicas**: Set reasonable limits (don't scale to 100 instances)

**Container Apps Scaling**:
```yaml
scale:
  minReplicas: 1
  maxReplicas: 10
  rules:
    - name: http-rule
      http:
        metadata:
          concurrentRequests: "50"
```

---

### 5. **Security Issues**

**Problem**: Exposed secrets, unauthorized access, compliance violations

**Solutions**:
- ✅ **Managed Identity**: Never store credentials in code/config
- ✅ **Key Vault**: Store all secrets (API tokens, connection strings)
- ✅ **HTTPS Only**: Disable HTTP in Container Apps
- ✅ **RBAC**: Least privilege access (no Owner role in production)
- ✅ **Network Security**: Use Virtual Networks for sensitive data (optional)
- ✅ **No PII**: Never log Qualtrics response data

**Managed Identity Example**:
```csharp
// No credentials needed!
var credential = new DefaultAzureCredential();
var client = new CosmosClient(endpoint, credential);
```

---

### 6. **Operational Complexity**

**Problem**: Hard to debug, maintain, deploy

**Solutions**:
- ✅ **Infrastructure as Code**: Use Bicep/Terraform (not portal clicks)
- ✅ **CI/CD Pipeline**: Automate deployments (GitHub Actions/Azure DevOps)
- ✅ **Deployment Slots**: Test in staging before production swap
- ✅ **Log Aggregation**: Centralize logs in Application Insights
- ✅ **Runbooks**: Document common operations and troubleshooting

**Deployment Automation**:
```yaml
# GitHub Actions workflow
- name: Deploy to Container Apps
  uses: azure/container-apps-deploy-action@v1
  with:
    containerAppName: disposition-api
    resourceGroup: rg-disposition-prod
    imageToDeploy: acr.azurecr.io/disposition-api:${{ github.sha }}
```

---

## 📋 Decision Framework

### When to Choose Each Service

**Azure Container Apps vs App Service**:
- **Container Apps**: Modern team, microservices, variable load, comfort with containers
- **App Service**: Traditional team, monolithic app, predictable load, simplicity priority

**SignalR Service vs Self-Hosted**:
- **SignalR Service**: > 50 users, multi-instance, production app
- **Self-Hosted**: < 20 users, single instance, cost-sensitive

**Cosmos DB vs SQL Database**:
- **Cosmos DB**: Time-series, high write throughput, flexible schema, global distribution
- **SQL Database**: Complex queries, ACID requirements, familiar team, existing SQL skills

**Serverless vs Provisioned**:
- **Serverless**: Variable load, < 5K RU/s, dev/test, unpredictable growth
- **Provisioned**: Constant load, > 400 RU/s continuous, strict SLA, cost predictability

---

## 🎓 Implementation Checklist

### Phase 1: Foundation
- [ ] Create Azure Resource Group (`rg-disposition-{env}`)
- [ ] Provision Container Apps Environment
- [ ] Create Cosmos DB account (Serverless mode)
- [ ] Setup Key Vault with managed identity
- [ ] Create Application Insights instance
- [ ] Create Container Registry

### Phase 2: Configuration
- [ ] Store Qualtrics API token in Key Vault
- [ ] Configure managed identity for Container Apps
- [ ] Setup connection strings (Cosmos DB, SignalR)
- [ ] Create budget alerts ($200/month)
- [ ] Configure log analytics workspace

### Phase 3: Deployment
- [ ] Build Docker images (API + Polling)
- [ ] Push to Container Registry
- [ ] Deploy API container app (min replicas = 1)
- [ ] Deploy Polling container app (min replicas = 1, max = 1)
- [ ] Configure health probes
- [ ] Setup custom domain and SSL

### Phase 4: Monitoring
- [ ] Create Application Insights dashboard
- [ ] Setup alerts (polling failures, high latency, errors)
- [ ] Configure availability tests
- [ ] Enable diagnostic logs
- [ ] Test cost monitoring

---

## 🧠 Synaptic Connections

### Active Connections (8 validated)

**Core Architecture**:
- `[alex-core.instructions.md]` (0.90, operates-within, bidirectional) - "Meta-cognitive framework guides infrastructure decisions"
- `[DK-ALEX-Q-QUALTRICS-SPECIALIST-v1.0.0.md]` (0.95, implements-for, bidirectional) - "Infrastructure supports Qualtrics integration requirements"

**Project Context**:
- `[plan/2025-11-10-real-time-disposition-dashboard.md]` (1.0, implements-plan, bidirectional) - "Architecture plan requires infrastructure decisions"
- `[plan/PROJECT-OBJECTIVES.md]` (0.85, supports, unidirectional) - "Infrastructure enables project objectives"

**Azure Integration**:
- `[azure.instructions.md]` (0.90, best-practices, bidirectional) - "Azure best practices applied to infrastructure selection"
- `[azurecosmosdb.instructions.md]` (0.95, database-selection, bidirectional) - "Cosmos DB guidance for disposition storage"

**Documentation Standards**:
- `[DK-DOCUMENTATION-EXCELLENCE-v1.1.0.md]` (0.85, documentation-quality, unidirectional) - "Infrastructure documentation quality standards"

**Session Record**:
- `[.github/prompts/meditation-session-2025-11-10-alex-q-identity-infrastructure.prompt.md]` (1.0, session-record, unidirectional) - "Session that established infrastructure domain knowledge"

---

## 💬 Key Takeaways

### ✅ **Recommended Stack Summary**

1. **Compute**: Azure Container Apps (API + Polling as separate containers)
2. **Real-Time**: Azure SignalR Service (Standard 1K unit)
3. **Database**: Azure Cosmos DB (Serverless NoSQL)
4. **Secrets**: Azure Key Vault (with Managed Identity)
5. **Monitoring**: Application Insights (with custom metrics)

**Total Cost**: ~$145/month for 10-50 surveys

### ❌ **What to Avoid**

1. **App Service with Background Service** - Scaling and coordination issues
2. **Self-Hosted SignalR at Scale** - Sticky session complexity
3. **Azure Functions Consumption** - Cold starts hurt continuous polling
4. **SQL Database with Auto-Pause** - 30-60s resume delays
5. **Table Storage** - Limited querying capabilities
6. **Provisioned Cosmos DB** - More expensive than Serverless for this workload

### 🎯 **Success Criteria**

- ✅ **Reliability**: 99.9% uptime (Azure SLA + proper health checks)
- ✅ **Performance**: < 60s update latency (30-60s polling + < 5s processing)
- ✅ **Cost**: ~$145/month (predictable, no surprises)
- ✅ **Scalability**: 10 → 100 surveys with minimal changes
- ✅ **Maintainability**: CI/CD automated, IaC managed

---

*Alex Q - Azure Infrastructure Specialist for Real-Time Disposition Dashboard*
