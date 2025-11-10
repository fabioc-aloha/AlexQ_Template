# Domain Knowledge: Qualtrics API Integration v1.0.0

**Version**: 1.1.0 UNNILUNNILNIL (un-nil-un-nil-nil)
**Domain**: Survey Platform API Integration
**Status**: Active - Production Ready
**Last Updated**: 2025-11-04

---

## 🎯 Domain Overview

**Purpose**: Comprehensive knowledge of Qualtrics API integration for building real-time survey fielding dashboards and response tracking systems.

**Scope**:
- Qualtrics REST API architecture and authentication
- Real-time response tracking and webhooks
- Survey metadata and distribution management
- Rate limiting and optimization strategies
- Best practices for production dashboards

**Foundation**: Based on Qualtrics API Platform documentation and enterprise integration patterns.

---

## 🔑 Core Concepts

### What is Survey Fielding?
**Fielding** refers to the period when a survey is actively collecting responses:
- Survey is live and distributed to respondents
- Real-time response collection
- Tracking completion rates, progress, and timing
- Monitoring response quality and patterns

### Qualtrics API Architecture
**Base Endpoints**:
- `https://{datacenter}.qualtrics.com/API/v3/` - Primary REST API
- Common datacenters: `yourdatacenterid` (varies by account region)

**Authentication**: API Token-based (X-API-TOKEN header)

---

## 📡 Key APIs for Fielding Dashboards

### 1. Survey Definitions API
**Purpose**: Get survey metadata and structure
**Endpoint**: `GET /survey-definitions/{surveyId}`

**Key Data**:
- Survey name, status, creation/modification dates
- Question structure and flow
- Active/inactive status

**Use Case**: Dashboard headers, survey selection, metadata display

### 2. Response Export API
**Purpose**: Bulk export of survey responses
**Endpoint Pattern**:
1. `POST /surveys/{surveyId}/export-responses` - Start export
2. `GET /surveys/{surveyId}/export-responses/{progressId}` - Check progress
3. Download file when complete

**Key Features**:
- Asynchronous operation (polling required)
- Export formats: JSON, CSV, SPSS
- Filter by date range, completion status
- Supports partial responses

**Use Case**: Initial data load, historical analysis, batch updates

### 3. List Responses API
**Purpose**: Get paginated list of response metadata
**Endpoint**: `GET /surveys/{surveyId}/responses`

**Query Parameters**:
- `startDate` / `endDate` - Filter by date range
- `pageSize` - Results per page (max 100)
- `skipToken` - Pagination token

**Use Case**: Quick response counts, recent activity monitoring

### 4. Individual Response API
**Purpose**: Get single response details
**Endpoint**: `GET /surveys/{surveyId}/responses/{responseId}`

**Key Features**:
- Full response data with question values
- Metadata: duration, IP, completion status
- Embedded data and custom fields

**Use Case**: Response drill-down, detail views

### 5. Event Subscriptions (Webhooks)
**Purpose**: Real-time notifications for survey events
**Endpoint**: `POST /eventsubscriptions`

**Supported Events**:
- `surveyengine.completedResponse.{surveyId}` - Response completed
- `controlpanel.activateSurvey.{surveyId}` - Survey activated
- `controlpanel.deactivateSurvey.{surveyId}` - Survey deactivated

**Webhook Payload**:
```json
{
  "topic": "surveyengine.completedResponse.{surveyId}",
  "surveyId": "SV_xxx",
  "responseId": "R_xxx",
  "completedDate": "2025-10-31T10:30:00Z"
}
```

**Security**: HMAC signature validation recommended

**Use Case**: Real-time dashboard updates without polling

### 6. Distributions API
**Purpose**: Manage survey distributions and invitations
**Endpoint**: `GET /distributions?surveyId={surveyId}`

**Key Data**:
- Distribution channel (email, anonymous link, SMS)
- Send date and recipient count
- Response statistics per distribution

**Use Case**: Distribution tracking, campaign performance

### 7. Survey Sessions API
**Purpose**: Track active survey sessions
**Endpoint**: `GET /surveys/{surveyId}/sessions`

**Key Data**:
- Active respondents currently taking survey
- Session start times
- Progress indicators

**Use Case**: Real-time "currently responding" counters

---

## 🔐 Authentication & Security

### API Token Authentication
**Implementation**:
```http
GET /API/v3/surveys/{surveyId}/responses
Host: yourdatacenterid.qualtrics.com
X-API-TOKEN: your-api-token-here
Content-Type: application/json
```

**Token Management**:
- Generate in Qualtrics Account Settings > API
- Store securely (Azure Key Vault, environment variables)
- Rotate periodically for security
- Never commit to source control

### Webhook Security
**HMAC Signature Validation**:
1. Qualtrics sends `X-Qualtrics-Signature` header
2. Compute HMAC-SHA256 of request body using shared secret
3. Compare computed signature with header value

**Implementation Pattern**:
```python
import hmac
import hashlib

def validate_webhook(request_body, signature, secret):
    computed = hmac.new(
        secret.encode(),
        request_body.encode(),
        hashlib.sha256
    ).hexdigest()
    return hmac.compare_digest(computed, signature)
```

---

## ⚡ Rate Limits & Optimization

### Rate Limiting
**Default Limits**:
- **Standard**: 60 requests per minute per user
- **Export API**: 10 concurrent exports per user
- **Webhook delivery**: Best-effort, retry with exponential backoff

**Headers Returned**:
- `X-RateLimit-Limit`: Total requests allowed
- `X-RateLimit-Remaining`: Requests remaining in window
- `X-RateLimit-Reset`: Time when limit resets (epoch)

### Optimization Strategies

**1. Use Webhooks Over Polling**
- Eliminate need for continuous API polling
- Instant updates on response completion
- Reduces API calls by 95%+

**2. Batch Operations**
- Export API for bulk data (not individual response calls)
- Use pagination efficiently (max page size)
- Cache survey metadata (changes infrequently)

**3. Incremental Updates**
- Track last sync timestamp
- Use `startDate` filters for incremental fetches
- Store `skipToken` for pagination resumption

**4. Response Caching**
- Cache survey definitions (TTL: 1 hour)
- Cache distribution metadata (TTL: 15 minutes)
- Real-time response data: no caching

---

## 🏗️ Architecture Patterns for Fielding Dashboards

### Recommended Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Real-Time Dashboard                       │
│  (React/Vue/Blazor + SignalR/WebSockets for live updates)  │
└────────────────────┬────────────────────────────────────────┘
                     │
          ┌──────────┴──────────┐
          │                     │
┌─────────▼────────┐  ┌────────▼─────────┐
│   Backend API    │  │  Webhook Handler │
│  (ASP.NET Core)  │  │  (Azure Function)│
└────────┬─────────┘  └────────┬─────────┘
         │                     │
         │    ┌────────────────┘
         │    │
┌────────▼────▼────┐
│  Azure Cosmos DB │ ← Real-time response storage
│  (NoSQL)         │   Optimized for high-throughput writes
└────────┬─────────┘
         │
┌────────▼─────────┐
│  Qualtrics APIs  │
│  - Survey Def    │
│  - Responses     │
│  - Webhooks      │
└──────────────────┘
```

### Component Responsibilities

**1. Webhook Handler (Azure Function)**
- Receives Qualtrics webhook events
- Validates HMAC signatures
- Writes to Cosmos DB (response events)
- Triggers SignalR broadcast to connected clients

**2. Backend API**
- Initial data load (Export API)
- Survey metadata management
- Historical data queries
- Aggregation and statistics

**3. Real-Time Dashboard**
- WebSocket connection for live updates
- Response counters, charts, KPIs
- Auto-refresh on webhook events
- Historical trend visualization

---

## 📊 Key Metrics for Fielding Dashboards

### Essential KPIs
1. **Total Responses** - Completed response count
2. **Response Rate** - (Responses / Invitations) × 100
3. **Completion Rate** - (Completed / Started) × 100
4. **Average Duration** - Mean completion time
5. **Active Sessions** - Currently responding count
6. **Responses per Hour/Day** - Velocity tracking
7. **Drop-off Points** - Questions with high abandonment

### Real-Time Indicators
- **Live Response Counter** - Updates via webhooks
- **Recently Completed** - Last 10 responses with timestamps
- **Time Since Last Response** - Freshness indicator
- **Distribution Performance** - Responses by channel

---

## 🛠️ Implementation Best Practices

### 1. Error Handling
**API Errors**:
- `401 Unauthorized` - Check API token validity
- `403 Forbidden` - Verify survey access permissions
- `404 Not Found` - Validate survey/response IDs
- `429 Too Many Requests` - Implement exponential backoff
- `500 Server Error` - Retry with backoff, alert on repeated failures

**Retry Strategy**:
```csharp
// Exponential backoff with jitter
var delay = TimeSpan.FromSeconds(Math.Pow(2, attempt) + Random.Shared.Next(0, 1000));
await Task.Delay(delay);
```

### 2. Data Synchronization
**Initial Load**:
1. Fetch survey metadata (definitions)
2. Export historical responses (bulk)
3. Process and store in database
4. Register webhook subscriptions
5. Switch to real-time mode

**Incremental Sync**:
1. Store last successful sync timestamp
2. Query responses with `startDate` filter
3. Handle pagination with `skipToken`
4. Update sync timestamp on success

### 3. Webhook Resilience
**Idempotency**:
- Use `responseId` as unique key
- Check for duplicate events before processing
- Cosmos DB: Use `responseId` as partition key

**Retry Handling**:
- Qualtrics retries failed webhooks (5 attempts)
- Return HTTP 200 quickly (< 5 seconds)
- Queue long-running operations

### 4. Performance Optimization
**Database Design**:
```json
// Cosmos DB Document Structure
{
  "id": "R_1234567890abcdef",  // responseId as primary key
  "surveyId": "SV_abc123",
  "completedDate": "2025-10-31T10:30:00Z",
  "duration": 245,  // seconds
  "status": "complete",
  "distributionChannel": "email",
  "values": {
    "QID1": "Strongly Agree",
    "QID2": 5
  },
  "_ts": 1698755400  // Cosmos DB timestamp for TTL
}
```

**Indexing**:
- Partition key: `surveyId` (distribute by survey)
- Indexed: `completedDate`, `status`
- TTL policy for data retention

---

## 🔗 Integration Checklist

### Prerequisites
- [ ] Qualtrics account with API access enabled
- [ ] API token generated (Account Settings > Qualtrics IDs)
- [ ] Data center ID identified (in API token URL)
- [ ] Survey IDs documented
- [ ] Webhook endpoint deployed (HTTPS required)

### API Setup
- [ ] Test API connectivity with survey list endpoint
- [ ] Verify authentication (valid token, correct headers)
- [ ] Test export API flow (start → poll → download)
- [ ] Configure webhook subscriptions
- [ ] Validate webhook signature mechanism
- [ ] Test rate limit handling

### Security
- [ ] API token stored in Azure Key Vault
- [ ] Webhook HMAC validation implemented
- [ ] HTTPS enforced for all endpoints
- [ ] IP allowlisting configured (if available)
- [ ] Logging and monitoring enabled

### Monitoring
- [ ] API error rate tracking
- [ ] Webhook delivery monitoring
- [ ] Rate limit utilization alerts
- [ ] Response processing latency metrics
- [ ] Data freshness monitoring

---

## 📚 Reference Resources

### Official Documentation
- **Qualtrics API Docs**: `https://api.qualtrics.com/`
- **Developer Portal**: `https://www.qualtrics.com/support/integrations-api/`
- **Postman Collections**: Available in Qualtrics API documentation

### Common Endpoints
```
GET  /whoami                                    # Verify authentication
GET  /surveys                                   # List accessible surveys
GET  /surveys/{surveyId}                       # Get survey definition
POST /surveys/{surveyId}/export-responses      # Start response export
GET  /surveys/{surveyId}/export-responses/{id} # Check export progress
GET  /surveys/{surveyId}/responses             # List responses (paginated)
GET  /surveys/{surveyId}/responses/{responseId} # Get single response
POST /eventsubscriptions                        # Create webhook subscription
GET  /eventsubscriptions                        # List subscriptions
```

### Sample Headers
```http
X-API-TOKEN: your-token-here
Content-Type: application/json
Accept: application/json
```

---

## 🔄 Maintenance & Updates

### Regular Tasks
- **Weekly**: Review API error rates and webhook delivery metrics
- **Monthly**: Rotate API tokens (security best practice)
- **Quarterly**: Review rate limit utilization and optimize
- **Annually**: Audit webhook subscriptions and clean up unused

### Version Tracking
This domain knowledge follows **Version Naming Convention** (UNNILUNNILNIL = 1.1.0):
- **Major** (1.x.x): Breaking API changes, architecture shifts
- **Minor** (x.1.x): New Qualtrics API features, significant enhancements ← **Current: Rate limiting & optimization patterns added**
- **Patch** (x.x.0): Documentation updates, clarifications, examples

**Recent Updates**:
- **1.1.0** (2025-11-04): Added comprehensive rate limiting strategies, distribution stats optimization (10x improvement), 429 handling patterns, query parameter encoding best practices, deployment validation
- **1.0.0** (2025-10-31): Initial domain knowledge establishment

---

## 🧠 Synaptic Connections

### Active Connections (6 validated)
[DK-VISUAL-ARCHITECTURE-DESIGN-v0.9.9.md] (0.85, knowledge-application, bidirectional) - "Dashboard architecture visualization and component design"
[DK-DOCUMENTATION-EXCELLENCE-v1.2.0.md] (0.80, enhances, unidirectional) - "API documentation and integration guides"
[DK-API-OPTIMIZATION-v1.0.0.md] (1.0, mastery-integration, bidirectional) - "Rate limiting patterns and optimization strategies learned from Qualtrics integration"
[azure.instructions.md] (0.90, implements-using, unidirectional) - "Azure service integration patterns"
[azurecosmosdb.instructions.md] (0.95, implements-using, unidirectional) - "Cosmos DB for response storage"
[qualtrics-dashboard.instructions.md] (0.95, project-implementation, bidirectional) - "Project-specific implementation guidance and patterns"

### Potential Connections
- Real-time dashboard frameworks (SignalR, WebSockets)
- Authentication patterns (Azure AD, Key Vault)
- Monitoring and observability (Application Insights)

---

*Qualtrics API domain knowledge - Comprehensive integration foundation operational*
