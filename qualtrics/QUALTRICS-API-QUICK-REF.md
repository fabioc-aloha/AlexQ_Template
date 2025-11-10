# Qualtrics API Quick Reference - Disposition Dashboard

**Base URL**: `https://{datacenter}.qualtrics.com/API/v3/`
**Authentication**: Header `X-API-TOKEN: your-token-here`
**Last Updated**: 2025-11-10

---

## 🎯 Critical Endpoints for Disposition Tracking

### 1. GET Distribution Stats (PRIMARY METRIC)
```http
GET /distributions?surveyId=SV_xxx
```

**Response**:
```json
{
  "result": {
    "elements": [{
      "id": "EMD_xxx",
      "requestType": "Invite",
      "stats": {
        "sent": 1000,
        "started": 450,
        "finished": 380,  ← PRIMARY DISPOSITION
        "bounced": 8,
        "opened": 520,
        "failed": 12
      }
    }]
  }
}
```

**Metrics**:
- Completion Rate: `(finished / sent) × 100`
- Response Rate: `(started / sent) × 100`

**Polling**: Every 5-15 minutes

---

### 2. Subscribe to Real-Time Events (WEBHOOKS)
```http
POST /eventsubscriptions
Content-Type: application/json

{
  "topics": "surveyengine.completedResponse.SV_xxx",
  "publicationUrl": "https://your-webhook.azurewebsites.net/api/webhook",
  "encrypt": false
}
```

**Webhook Payload** (form-urlencoded):
```
CompletedDate=2025-11-10+16:00:00
Status=Completed
ResponseID=R_xxx
SurveyID=SV_xxx
```

**Handler Requirements**:
- Accept HTTP POST
- Return 200 within 5 seconds
- Check for duplicate ResponseIDs (idempotency)

---

### 3. Get Single Response (WEBHOOK PROCESSING)
```http
GET /surveys/SV_xxx/responses/R_xxx
```

**Response**:
```json
{
  "result": {
    "responseId": "R_xxx",
    "values": {
      "startDate": "2025-11-10T14:00:00Z",
      "endDate": "2025-11-10T14:05:30Z",
      "duration": 330,
      "finished": 1,
      "status": 0,
      "progress": 100,
      "QID1": 2,
      "QID2": "Strongly Agree"
    },
    "labels": {
      "QID1": "Choice 2",
      "QID2": "Strongly Agree"
    }
  }
}
```

**Use**: Called after webhook notification

---

### 4. Bulk Export (INITIAL LOAD)
**Step 1: Start Export**
```http
POST /surveys/SV_xxx/export-responses
Content-Type: application/json

{
  "format": "json",
  "startDate": "2025-11-01T00:00:00Z",
  "endDate": "2025-11-10T23:59:59Z"
}
```

**Response**:
```json
{
  "result": {
    "progressId": "ES_xxx",
    "status": "inProgress"
  }
}
```

**Step 2: Check Progress** (poll with exponential backoff)
```http
GET /surveys/SV_xxx/export-responses/ES_xxx
```

**Response**:
```json
{
  "result": {
    "percentComplete": 100.0,
    "fileId": "b4a753b8-xxx",
    "status": "complete"
  }
}
```

**Step 3: Download**
```http
GET /surveys/SV_xxx/export-responses/b4a753b8-xxx/file
```

Returns ZIP file with JSON/CSV inside

**Use**: Initial dashboard load, historical data

---

### 5. Get Survey Metadata (DASHBOARD CONTEXT)
```http
GET /survey-definitions/SV_xxx/metadata
```

**Response**:
```json
{
  "result": {
    "SurveyID": "SV_xxx",
    "SurveyName": "Customer Satisfaction Q4",
    "SurveyStatus": "Active",
    "SurveyCreationDate": "2025-10-01T00:00:00Z",
    "LastModified": "2025-11-10T14:30:00Z"
  }
}
```

**Use**: Dashboard headers, survey selection

---

## 🔄 Recommended Data Flow

### Initial Dashboard Load
```
1. GET /survey-definitions/{surveyId}/metadata  → Survey info
2. POST /surveys/{surveyId}/export-responses    → Start export
3. Poll /export-responses/{progressId}          → Wait for completion
4. GET /export-responses/{fileId}/file          → Download ZIP
5. Extract and load to Cosmos DB                → Historical data ready
6. GET /distributions?surveyId={id}             → Get aggregate stats
7. POST /eventsubscriptions                     → Subscribe to webhooks
```

### Real-Time Updates
```
Webhook arrives
  ↓
Azure Function (HTTP Trigger)
  ↓
Return 200 immediately
  ↓
Queue message to Service Bus
  ↓
Azure Function (Queue Trigger)
  ↓
GET /surveys/{surveyId}/responses/{responseId}
  ↓
Store in Cosmos DB
  ↓
Push to SignalR
  ↓
Dashboard updates
```

### Periodic Refresh
```
Every 5-15 minutes:
  GET /distributions?surveyId={id}
    ↓
  Update aggregate metrics
    ↓
  Calculate completion rates
    ↓
  Update dashboard KPIs
```

---

## 📊 Key Metrics to Track

### From Distributions API
- **Sent**: Total emails sent
- **Finished**: Completed responses ← PRIMARY METRIC
- **Started**: Survey attempts
- **Bounced**: Email delivery failures
- **Opened**: Email opens (may undercount)
- **Failed**: Invalid emails

### Calculated Metrics
```
Completion Rate = (finished / sent) × 100
Response Rate = (started / sent) × 100
Drop-off Rate = ((started - finished) / started) × 100
Email Health = bounced + failed + blocked
```

### From Individual Responses
- **Duration**: Time to complete (seconds)
- **Progress**: Completion percentage
- **Status**: Response type (0=normal, 8=spam)
- **Timestamp**: recordedDate for activity timeline

---

## 🚨 Error Handling & Rate Limits

### Rate Limits (Official - Verified)
**Brand-Level**: 3000 requests/min across all endpoints

**Critical Endpoint Limits**:
- Distributions: 3000/min (safe for polling)
- Event Subscriptions: 120/min (plenty for setup)
- Export Responses (start): 100/min
- Export Responses (check): 1000/min
- Export Responses (download): 100/min
- Single Response: 240/min (sufficient for webhooks)
- Survey Metadata: 3000/min

**Timeouts & Limits**:
- API timeout: 5 seconds per call
- Max response records: 1M per file
- Max file upload: 5 MB

### HTTP Status Codes
- `200 OK` - Success
- `401 Unauthorized` - Invalid API token
- `403 Forbidden` - Insufficient permissions
- `404 Not Found` - Invalid survey/response ID
- `429 Too Many Requests` - Rate limit exceeded (exponential backoff required)
- `500 Server Error` - Contact Qualtrics support (log requestId)
- `504 Gateway Timeout` - Retry reads, verify writes before retry

### Retry Strategy (429 Rate Limit Handling)
```python
import time
import random

def retry_with_backoff(func, max_retries=5):
    for attempt in range(max_retries):
        try:
            return func()
        except RateLimitError:
            if attempt == max_retries - 1:
                raise
            # Exponential backoff: 2^attempt + jitter
            delay = (2 ** attempt) + random.uniform(0, 1)
            time.sleep(min(delay, 60))  # Cap at 60 seconds

def check_rate_limit_headers(response):
    """Monitor approaching rate limits"""
    remaining = int(response.headers.get('X-RateLimit-Remaining', 999))
    reset_time = int(response.headers.get('X-RateLimit-Reset', 0))

    if remaining < 100:
        logger.warning(f"Rate limit low: {remaining} remaining, resets at {reset_time}")
        # Implement circuit breaker or throttling

    return remaining
```

### Webhook Idempotency
```csharp
// Check for duplicate before processing
if (await _db.Responses.AnyAsync(r => r.ResponseId == responseId))
{
    _logger.LogInformation("Duplicate webhook ignored: {ResponseId}", responseId);
    return Ok(); // Still return 200
}

// Process new response
await ProcessResponse(responseId);
```

---

## 💾 Cosmos DB Schema

### Response Document
```json
{
  "id": "R_xxx",
  "surveyId": "SV_xxx",
  "completedDate": "2025-11-10T14:05:30Z",
  "duration": 330,
  "status": 0,
  "finished": true,
  "distributionChannel": "email",
  "values": {
    "QID1": 2,
    "QID2": "Strongly Agree"
  },
  "labels": {
    "QID1": "Choice 2"
  },
  "_ts": 1699546530
}
```

**Partition Key**: `surveyId`
**Indexed Fields**: `completedDate`, `status`, `finished`

### Distribution Stats Document
```json
{
  "id": "EMD_xxx",
  "surveyId": "SV_xxx",
  "requestType": "Invite",
  "sendDate": "2025-11-05T10:00:00Z",
  "stats": {
    "sent": 1000,
    "started": 450,
    "finished": 380,
    "bounced": 8
  },
  "lastUpdated": "2025-11-10T16:00:00Z"
}
```

**Partition Key**: `surveyId`
**Update Frequency**: Every 5-15 minutes

---

## 🔗 Quick Links

- **Official Docs**: https://api.qualtrics.com/
- **DK-QUALTRICS-API-v1.0.0.md**: Complete endpoint reference
- **QUALTRICS-FACT-CHECK-2025-11-10.md**: Verification documentation
- **API-DOCUMENTATION-UPDATE-2025-11-10.md**: Update summary

---

*Quick Reference Guide - Alex Q - Qualtrics & Azure Infrastructure Specialist*
