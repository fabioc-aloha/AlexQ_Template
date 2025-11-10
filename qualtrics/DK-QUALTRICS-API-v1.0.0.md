# Domain Knowledge: Qualtrics API Integration v1.0.0

**Version**: 1.2.0 UNNILBINILNIL (un-nil-bi-nil-nil)
**Domain**: Survey Platform API Integration
**Status**: Active - Production Ready with Complete Endpoint Documentation
**Last Updated**: 2025-11-10

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

## 📡 Complete API Endpoint Reference

### **API Response Structure**
All Qualtrics API responses follow this standard format:

```json
{
  "result": { /* API-specific data */ },
  "meta": {
    "httpStatus": "200 - OK",
    "requestId": "74768340-3902-4f6d-9327-f5fdc2cdb9ec",
    "notice": "Additional information (optional)"
  }
}
```

**Key Fields**:
- `result`: Contains API response data (absent if no data returned)
- `meta.requestId`: Unique identifier for troubleshooting (log this!)
- `meta.httpStatus`: HTTP status code and message
- Default pagination: 100 items per page (some endpoints allow override)

**HTTP Status Codes**:
- `200 OK` - Success
- `202 Accepted` - Upload accepted
- `400 Bad Request` - Invalid request format
- `401 Unauthorized` - Invalid/missing API token
- `403 Forbidden` - Valid auth but insufficient permissions
- `404 Not Found` - Resource doesn't exist
- `429 Too Many Requests` - Rate limit exceeded (use exponential backoff)
- `500/503 Server Error` - Internal Qualtrics issue (contact support)
- `504 Gateway Timeout` - Request timeout (retry for reads, verify writes before retry)

---

## 📋 Survey Management Endpoints

### 1. List Surveys
**Endpoint**: `GET https://{datacenter}.qualtrics.com/API/v3/surveys`

**Purpose**: Retrieve all surveys owned by or collaborated with user (individual collaborations only, not groups)

**Response**:
```json
{
  "result": {
    "elements": [
      {
        "id": "SV_1234567890",
        "name": "Spring Survey",
        "ownerId": "UR_abcdefghij",
        "isActive": true,
        "lastModified": "2025-11-10T15:01:02Z"
      }
    ],
    "nextPage": "url-to-next-page-or-null"
  }
}
```

**Use Case**: Survey selection, dashboard filtering, metadata display

---

### 2. Get Survey Definition
**Endpoint**: `GET /surveys/{surveyId}`

**Purpose**: Retrieve complete survey structure (questions, flow, blocks, embedded data)

**Response Includes**:
- Survey metadata (name, owner, creation/modification dates, expiration)
- Questions object (all questions with QIDs, types, choices)
- Blocks object (survey structure and organization)
- Flow array (survey logic and branching)
- Embedded data fields
- Comments/notes on questions
- Response counts (auditable, deleted, generated)

**Note**: This returns survey DESIGN, not response data. See Response Export APIs for actual responses.

**Use Case**: Survey structure analysis, question mapping, dashboard context

---

### 3. Get Survey Metadata
**Endpoint**: `GET /survey-definitions/{surveyId}/metadata`

**Purpose**: Lightweight metadata without full definition (faster than Get Survey)

**Response**:
```json
{
  "result": {
    "SurveyID": "SV_xxx",
    "SurveyName": "Customer Satisfaction Q4",
    "SurveyDescription": "Quarterly NPS survey",
    "SurveyStatus": "Active",
    "SurveyCreationDate": "2025-10-01T00:00:00Z",
    "SurveyStartDate": "2025-11-01T00:00:00Z",
    "SurveyExpirationDate": "2025-12-31T23:59:59Z",
    "LastModified": "2025-11-10T14:30:00Z",
    "LastAccessed": "2025-11-10T15:00:00Z"
  }
}
```

**SurveyStatus Values**: `Active`, `Inactive`, `Pending`, `LibBlock` (library block), `Deactive`, `Temporary`

**Use Case**: Dashboard headers, status filtering, lightweight polling

---

### 4. Update Survey
**Endpoint**: `PUT /surveys/{surveyId}`

**Purpose**: Update survey metadata (name, active status, expiration dates)

**Request Body**:
```json
{
  "name": "New Survey Name",
  "isActive": true,
  "expiration": {
    "startDate": "2025-11-15T00:00:00Z",
    "endDate": "2025-12-31T23:59:59Z"
  }
}
```

**Use Case**: Survey administration, activation/deactivation from dashboard

---

## 📊 Distribution Endpoints (CRITICAL for Disposition Tracking)

### 5. List Distributions
**Endpoint**: `GET /distributions?surveyId={surveyId}`

**Rate Limit**: 3000/min

**Purpose**: Get all distributions for a survey with aggregate statistics

**Query Parameters**:
- `surveyId` (required): Survey ID to filter distributions
- `distributionRequestType`: Filter by type (`Invite`, `ThankYou`, `Reminder`, `Email`, `Portal`, `PortalInvite`, `GeneratedInvite`)
- `mailingListId`: Filter by mailing list/contact group ID (e.g., `CG_012345678901234`)
- `sendStartDate`: ISO 8601 date filter (e.g., `2025-11-01T00:00:00Z`)
- `sendEndDate`: ISO 8601 date filter (e.g., `2025-11-10T23:59:59Z`)
- `pageSize`: Results per page (1-100, default: 100)
- `offset`: Starting offset for pagination (default: 0) - **DEPRECATED**
- `skipToken`: Pagination token (string-based pagination) - **RECOMMENDED**
- `useNewPaginationScheme`: Set to `true` for performance improvements (string-based pagination)

**⚠️ Breaking Change** (Effective June 1, 2022):
- `messageText` field **no longer returned** in List Distributions response
- Use `messageType` to identify message source:
  - `messageType: "Library"` → Get content via `GET /libraries/{libraryId}/messages/{messageId}`
  - `messageType: "Inline"` → Get content via `GET /distributions/{distributionId}` (includes full message text)

**Pagination Best Practice**:
- Use `useNewPaginationScheme=true` with `skipToken` for better performance
- Legacy offset-based pagination still works but is slower

**Response**:
```json
{
  "result": {
    "elements": [
      {
        "id": "EMD_xxx",
        "parentDistributionId": null,
        "requestType": "Invite",
        "requestStatus": "Done",
        "sendDate": "2025-11-05T10:00:00Z",
        "headers": {
          "fromEmail": "survey@company.com",
          "fromName": "Survey Team",
          "subject": "Please take our survey"
        },
        "recipients": {
          "mailingListId": "CG_xxx",
          "libraryId": "UR_xxx"
        },
        "surveyLink": {
          "surveyId": "SV_xxx",
          "expirationDate": "2025-12-31T23:59:59Z",
          "linkType": "Individual"
        },
        "stats": {
          "sent": 1000,
          "failed": 12,
          "started": 450,
          "finished": 380,
          "bounced": 8,
          "opened": 520,
          "skipped": 3,
          "complaints": 1,
          "blocked": 2
        },
        "embeddedData": {},  // Returns null if multiple distributions exist
        "message": {
          "libraryId": "UR_xxx",
          "messageId": "MS_xxx",
          "messageType": "Library"  // "Library" or "Inline"
          // messageText field REMOVED as of June 1, 2022
        }
      }
    ],
    "nextPage": "string"  // URL for next page or null if last page
  },
  "meta": {
    "httpStatus": "200 OK",
    "requestId": "unique-request-id"
  }
}
```

**Key Fields**:
- `id`: Distribution ID (e.g., `EMD_1234567890abcde`)
- `ownerId`: Distribution owner user ID (e.g., `UR_1M4aHozEkSxUfCl`)
- `organizationId`: Organization identifier
- `requestType`: Distribution type
  - `Invite`: Initial survey invitation
  - `Reminder`: Follow-up reminder
  - `ThankYou`: Thank you message after completion
  - `Email`: General email distribution
  - `Portal`: Portal distribution
  - `PortalInvite`: Portal invitation
  - `GeneratedInvite`: Auto-generated invitation
- `requestStatus`: Distribution status (`Pending`, `Done`, `Generated`)
- `sendDate`: When distribution was/will be sent (ISO 8601)
- `createdDate`: When distribution was created (ISO 8601)
- `modifiedDate`: Last modification timestamp (ISO 8601)
- `parentDistributionId`: Links reminders/thank-yous to original invite (null for primary invites)
- `headers`: Email headers
  - `fromEmail`: Sender email address
  - `replyToEmail`: Reply-to email address
  - `fromName`: Display name for sender
  - `subject`: Email subject line (text or message ID like `MS_xxx`)
- `recipients`: Distribution recipients
  - `mailingListId`: Contact group ID (e.g., `CG_012345678901234`)
  - `contactId`: Individual contact ID (e.g., `CGC_012345678901234`)
  - `libraryId`: Library ID containing message
  - `sampleId`: Sample ID for distribution
- `surveyLink`: Survey link configuration
  - `surveyId`: Associated survey ID
  - `expirationDate`: Link expiration date (ISO 8601)
  - `linkType`: Link generation type
    - `Individual`: Unique link per recipient (tracked responses)
    - `Anonymous`: Shared anonymous link (untracked)
    - `Multiple`: Reusable link allowing multiple responses
- **`stats` object**: **THE KEY FOR DISPOSITION TRACKING** ⭐
  - `sent`: Total emails sent ≥ 0 (default: 0)
  - `started`: Survey started count ≥ 0 (default: 0)
  - `finished`: Survey completed count ≥ 0 (default: 0) ← **PRIMARY DISPOSITION METRIC**
  - `bounced`: Email bounces ≥ 0 (default: 0)
  - `opened`: Email opens ≥ 0 (default: 0) - web beacon tracking (may undercount)
  - `failed`: Invalid email addresses ≥ 0 (default: 0)
  - `skipped`: Rate-limited recipients ≥ 0 (default: 0)
  - `complaints`: Spam complaints ≥ 0 (default: 0)
  - `blocked`: Blocked emails ≥ 0 (default: 0)
- `message`: Message configuration
  - `libraryId`: Library containing message
  - `messageId`: Message ID (e.g., `MS_0Vdgn7nLGSQBlYN`)
  - `messageType`: `Library` or `Inline`
  - `messageText`: **DEPRECATED** - Removed June 1, 2022
- `embeddedData`: Embedded data for distribution (returns `{}` or `null` if multiple distributions)

**Response Metadata**:
- `nextPage`: Pagination - URL string for next page, or `null` if last page
- `meta.httpStatus`: HTTP status code
- `meta.requestId`: Unique request identifier
- `meta.notice`: Optional informational notice

**Calculated Metrics**:
- **Completion Rate**: `(finished / sent) × 100`
- **Response Rate**: `(started / sent) × 100`
- **Email Deliverability**: `((sent - bounced - blocked) / sent) × 100`
- **Email Health Score**: Track bounces, blocks, complaints trends

**Use Case**: **PRIMARY ENDPOINT for disposition dashboard aggregate metrics**

---

### 6. Get Distribution
**Endpoint**: `GET /distributions/{distributionId}?surveyId={surveyId}`

**Rate Limit**: 3000/min

**Purpose**: Get complete details for a single distribution including full message text

**Parameters**:
- `distributionId` (path, required): Distribution ID (e.g., `EMD_1234567890abcde`)
- `surveyId` (query, required): Survey ID (e.g., `SV_cHbKMOdeT8NetF3`)

**Response**: Same structure as List Distributions element, **BUT** includes additional fields:

**Key Differences from List Distributions**:
- ✅ **`messageText` IS INCLUDED** for inline messages (not removed like in List Distributions)
- ✅ **`embeddedData` returns full object** with up to 10 key-value pairs (not null)
  - Each key: max 200 characters
  - Each value: max 1024 characters

**Response Example**:
```json
{
  "result": {
    "id": "EMD_1234567890abcde",
    "requestType": "Invite",
    "requestStatus": "Done",
    "stats": { /* same as List Distributions */ },
    "message": {
      "libraryId": "UR_1M4aHozEkSxUfCl",
      "messageId": "MS_0Vdgn7nLGSQBlYN",
      "messageText": "Example Message Text",  // ✅ INCLUDED for Inline messages
      "messageType": "Inline"  // or "Library"
    },
    "embeddedData": {
      "recipientName": "John Doe",
      "accountId": "ACC-12345",
      "customField1": "value1"
      // Up to 10 key-value pairs
    }
  },
  "meta": {
    "httpStatus": "200 OK",
    "requestId": "unique-request-id"
  }
}
```

**When to Use Get Distribution vs. List Distributions**:
- **List Distributions**: Aggregate stats for all distributions (fast, summary view)
- **Get Distribution**: Full details including message text and embedded data (detailed view)

**Use Case**:
- Drill-down into specific distribution for detailed analysis
- Retrieve full message text for inline messages
- Access embedded data for individual distribution
- Debugging distribution configuration

---

### 7. List Distribution History (⚠️ XM Directory Only)
**Endpoint**: `GET /distributions/{distributionId}/history`

**Rate Limit**: 300/min (lower than other distribution endpoints!)

**Purpose**: Get individual-level disposition tracking for each contact in a distribution

**⚠️ Important Limitations**:
- **XM Directory ONLY** - Not supported for legacy Genesis Contacts
- Lower rate limit (300/min vs. 3000/min for other distribution endpoints)
- Use for detailed contact-level analysis, not real-time dashboard aggregates

**Parameters**:
- `distributionId` (path, required): Distribution ID (e.g., `EMD_1234567890abcde`)
- `skipToken` (query, optional): Pagination token for string-based pagination

**Response**:
```json
{
  "result": {
    "elements": [
      {
        "contactId": "CID_6SvNjhDzWKKWdCt",
        "contactLookupId": "CGC_2SvBjhAzwZK4dEx",
        "distributionId": "EMD_m3ox030by7ydblg",
        "status": "SurveyFinished",
        "surveyLink": "https://yul1.qualtrics.com/jfe/form/SV_xxx?Q_DL=...",
        "contactFrequencyRuleId": null,
        "responseId": "R_YXIPQimT0z0A3i9",
        "responseCompletedAt": "2025-11-10T14:05:30Z",
        "sentAt": "2025-11-10T10:00:00Z",
        "openedAt": "2025-11-10T11:30:00Z",
        "responseStartedAt": "2025-11-10T14:00:00Z",
        "surveySessionId": "FS_1CwF4quYDr7AzoD"
      }
    ],
    "nextPage": "string"  // URL or null
  },
  "meta": {
    "httpStatus": "200 OK",
    "requestId": "unique-request-id"
  }
}
```

**Key Fields**:
- `contactId` (required): Contact ID (e.g., `CID_6SvNjhDzWKKWdCt`)
- `contactLookupId`: Contact lookup ID (e.g., `CGC_2SvBjhAzwZK4dEx`)
- `distributionId` (required): Distribution ID
- **`status` (required)**: Individual contact disposition status (17 possible values):

  **Distribution Statuses**:
  - `Pending`: Scheduled but not yet sent
  - `Success`: Successfully delivered to contact
  - `Error`: Error occurred while sending
  - `Opened`: Email opened by contact
  - `Complaint`: Contact marked as spam
  - `Skipped`: Skipped due to frequency rules or blacklist
  - `Blocked`: Blocked by contact or spam circuit breaker
  - `Failure`: Failed to deliver
  - `Unknown`: Failed for unknown reason
  - `SoftBounce`: Bounced but can be retried
  - `HardBounce`: Bounced, should not retry

  **Survey Interaction Statuses**:
  - `SurveyStarted`: Contact started survey
  - `SurveyPartiallyFinished`: Submitted partial response
  - `SurveyFinished`: Submitted completed response ⭐
  - `SurveyScreenedOut`: Contact screened out
  - `SessionExpired`: Survey session expired

- `surveyLink` (required, nullable): Individual survey link sent to contact (null if no link sent)
- `contactFrequencyRuleId` (required, nullable): Frequency rule ID if status is `Skipped`, or `"RULE_DELETED"` if rule was deleted
- `responseId` (required, nullable): Survey response ID (e.g., `R_YXIPQimT0z0A3i9`), `"Anonymous"` if anonymized, `null` if not submitted
- **Timestamps** (all ISO 8601, nullable):
  - `sentAt`: When email was sent
  - `openedAt`: When email was opened (null if not opened)
  - `responseStartedAt`: When survey was started (null if not started)
  - `responseCompletedAt`: When response was completed (null if not completed)
- `surveySessionId` (required, nullable): Session identifier (e.g., `FS_1CwF4quYDr7AzoD`)

**Pagination**:
- `nextPage`: URL for next page or `null` if last page

**Status Flow Analysis**:
```
Pending → Success → Opened → SurveyStarted → SurveyFinished
          ↓
       Failure/Blocked/HardBounce (terminal states)
          ↓
       SoftBounce (retry possible)
```

**Calculated Metrics** (per contact):
- **Time to Open**: `openedAt - sentAt`
- **Time to Start**: `responseStartedAt - sentAt`
- **Time to Complete**: `responseCompletedAt - sentAt`
- **Survey Duration**: `responseCompletedAt - responseStartedAt`

**Use Cases**:
- **Individual-level disposition tracking** for contact-level dashboards
- Identify specific contacts with bounces, complaints, or failures
- Calculate engagement timelines (sent → opened → started → completed)
- Audit trail for distribution delivery
- Contact reachability analysis
- Frequency rule impact analysis

**⚠️ Performance Considerations**:
- **Rate limit**: 300/min (10x lower than other distribution endpoints)
- Use for **detailed analysis**, not real-time aggregate dashboard
- For aggregate stats, use `GET /distributions?surveyId=...` (3000/min)
- Consider caching results for frequently accessed distributions

**Dashboard Integration Strategy**:
- **Tier 1 (Aggregate)**: Use distribution `stats` object (fast, 3000/min)
- **Tier 2 (Contact-level)**: Use distribution history (detailed, 300/min)
- Cache history data and refresh periodically (e.g., every 15-30 minutes)

---

## 🎯 Response Data Endpoints

### 7. Individual Response Retrieval
**Endpoint**: `GET /surveys/{surveyId}/responses/{responseId}`

**Purpose**: Get complete data for a single response

**Response**:
```json
{
  "result": {
    "responseId": "R_xxx",
    "values": {
      "startDate": "2025-11-10T14:00:00Z",
      "endDate": "2025-11-10T14:05:30Z",
      "status": 0,
      "ipAddress": "192.168.1.1",
      "progress": 100,
      "duration": 330,
      "finished": 1,
      "recordedDate": "2025-11-10T14:05:31Z",
      "distributionChannel": "email",
      "userLanguage": "EN",
      "locationLatitude": "45.5115",
      "locationLongitude": "-73.5683",
      "QID1": 2,
      "QID2": "Strongly Agree",
      "QID3": 5
    },
    "labels": {
      "status": "IP Address",
      "finished": "True",
      "QID1": "Choice 2",
      "QID2": "Strongly Agree"
    },
    "displayedFields": ["QID1", "QID2", "QID3"],
    "displayedValues": {
      "QID1": [1, 2, 3],
      "QID2": [1, 2, 3, 4, 5]
    }
  }
}
```

**Status Codes**:
- `0` = Normal completion
- `1` = Preview (test response)
- `2` = Survey test mode
- `4` = Imported response
- `8` = Spam/low quality
- `16` = Offline response
- `17` = Offline preview

**Use Case**: Webhook handler processing, response detail view, drill-down from distribution stats

---

### 8. Bulk Response Export (Asynchronous 3-Step Process)

#### Step 8a: Create Response Export
**Endpoint**: `POST /surveys/{surveyId}/export-responses`

**Rate Limit**: 100/min (LOWEST rate limit of all export endpoints!)

**Purpose**: Start asynchronous export of survey responses

**⚠️ Critical Constraints**:
- **Max file size**: 1.8 GB (exports exceeding this will fail)
- **HTTP 200 required**: Only poll for progress if you receive HTTP 200 status
- **Large files**: Use `compress: true` (default) to avoid timeouts
- **Continuation tokens**: Expire after 7 days

**Request Body** (Minimal):
```json
{
  "format": "csv"  // Required - only required field
}
```

**Request Body** (Comprehensive):
```json
{
  "format": "ndjson",
  "compress": true,
  "startDate": "2025-11-01T00:00:00Z",
  "endDate": "2025-11-10T23:59:59Z",
  "filterId": "9b67fbb7-ef89-430d-8ddf-f17f44de9254",
  "limit": 5000,
  "useLabels": false,
  "includeLabelColumns": false,
  "seenUnansweredRecode": -1,
  "multiselectSeenUnansweredRecode": 99,
  "timeZone": "America/Chicago",
  "sortByLastModifiedDate": true,
  "exportResponsesInProgress": false,
  "allowContinuation": true,
  "questionIds": ["QID1", "QID2"],
  "embeddedDataIds": ["userId", "accountId"],
  "surveyMetadataIds": ["startDate", "endDate", "finished"],
  "breakoutSets": true,
  "includeDisplayOrder": false,
  "formatDecimalAsComma": false,
  "newlineReplacement": " ",
  "includeWaveWeights": false
}
```

**Format Options** (required):
- `csv` (default): Comma-separated values
- `tsv`: Tab-separated values
- `json`: JSON format
- `ndjson`: Newline-delimited JSON (recommended for streaming)
- `spss`: SPSS statistical format
- `xml`: XML format

**⚠️ JSON/NDJSON Format Restrictions**:
When using `json` or `ndjson`, the following parameters are **NOT ALLOWED**:
- `includeDisplayOrder`
- `useLabels`
- `formatDecimalAsComma`
- `seenUnansweredRecode`
- `multiselectSeenUnansweredRecode`
- `timeZone`
- `newlineReplacement`
- `breakoutSets`

**Core Parameters**:
- `format` (required): File format (see options above)
- `compress` (boolean, default: `true`): Compress as ZIP - **RECOMMENDED for large files**
- `limit` (integer ≥ 0): Maximum number of responses to export
- `startDate` (ISO 8601, default: `1970-01-01T01:00:00Z`): Filter responses after date (inclusive)
- `endDate` (ISO 8601, default: `2100-01-01T01:00:00Z`): Filter responses before date (exclusive)
- `filterId` (string): Apply pre-created filter (see List Filters API)

**Data Formatting Parameters**:
- `useLabels` (boolean, default: `false`): Export text labels instead of numeric recode values
- `includeLabelColumns` (boolean, default: `false`): Export BOTH labels and numeric values (cannot use with `useLabels`)
- `seenUnansweredRecode` (integer): Recode value for unanswered questions (e.g., `-1`, `99`)
- `multiselectSeenUnansweredRecode` (integer): Recode for unanswered multi-select choices (defaults to `seenUnansweredRecode`)
- `formatDecimalAsComma` (boolean, default: `false`): Use comma as decimal separator
- `newlineReplacement` (string): Replace newlines with this value (CSV/TSV only)
- `breakoutSets` (boolean, default: `true`): Split multi-value fields into columns

**Field Selection Parameters**:
- `questionIds` (array[string]): Only export specific questions (e.g., `["QID1", "QID2"]`)
- `embeddedDataIds` (array[string]): Only export specific embedded data fields
- `surveyMetadataIds` (array[string]): Only export specific metadata fields
  - Available metadata: `startDate`, `endDate`, `status`, `ipAddress`, `progress`, `duration`, `finished`, `recordedDate`, `_recordId`, `locationLatitude`, `locationLongitude`, `recipientLastName`, `recipientFirstName`, `recipientEmail`, `externalDataReference`, `distributionChannel`

**Advanced Filtering**:
- `exportResponsesInProgress` (boolean, default: `false`): Only export incomplete responses
- `sortByLastModifiedDate` (boolean, default: `false`): Sort by modified date instead of creation date
  - When `true`, `startDate`/`endDate` filter by modified date
  - Adds `LastModifiedDate` column to export
  - **Cannot be used with `filterId`**
  - **Recommended for incremental exports with `continuationToken`**

**Incremental Export Parameters** (for periodic syncing):
- `allowContinuation` (boolean, default: `false`): Request continuation token for next export
  - **Cannot be used with `filterId`**
  - Token expires after 7 days
- `continuationToken` (string): Get responses since previous export (implies `allowContinuation`)
  - Example: `UQhcCBAIGwgGCFkIEBscGhIcHxkZHxwGCEQIEBwYGxoaGhoaGgYITwgQGxwaExgcGhkYE1c`
  - Use with `sortByLastModifiedDate: true` for best results

**Display & Metadata Parameters**:
- `includeDisplayOrder` (boolean, default: `false`): Include randomization display order (fields have `_DO` suffix)
- `timeZone` (string, default: `UTC`): Convert dates to local timezone (e.g., `America/Chicago`)
- `includeWaveWeights` (boolean, default: `false`): Include `Wave Name` and `Weight Segment` fields (if defined)

**Response**:
```json
{
  "result": {
    "progressId": "ES_0d2n60qVHB9jSLz",
    "percentComplete": 0.0,
    "status": "inProgress",
    "continuationToken": "UQhcCBAIGwgGCFkI..."  // Only if allowContinuation=true
  },
  "meta": {
    "requestId": "7a9150e0-08bb-4953-89cf-ef8a157b8aa7",
    "httpStatus": "200 - OK"
  }
}
```

**Response Fields**:
- `progressId` (required): Job ID for polling (e.g., `ES_0d2n60qVHB9jSLz`)
- `percentComplete` (required): Progress percentage (0.0 to 100.0)
- `status` (required): `inProgress`, `complete`, `failed`
- `continuationToken`: Token for next incremental export (only if requested)

**⚠️ Error Handling**:
- **Non-200 status**: Do NOT start polling - export failed to start
- **1.8 GB exceeded**: Use filters, date ranges, or `limit` to reduce size
- **Timeout risk**: Always use `compress: true` for exports > 100 MB

#### Step 8b: Check Export Progress
**Endpoint**: `GET /surveys/{surveyId}/export-responses/{exportProgressId}`

**Rate Limit**: 1000/min

**Purpose**: Poll export job status until completion

**Parameters**:
- `surveyId` (path, required): Survey ID
- `exportProgressId` (path, required): Progress ID from Step 8a response (`progressId` field)

**⚠️ Critical Polling Requirements**:
1. **Check for null progressId** before polling - avoid infinite loops!
2. **Stop polling on HTTP 404** - export job no longer exists
3. **Wait for `status: "complete"`** before downloading - `percentComplete: 100` alone is NOT sufficient
4. **`fileId` only returned when complete** - don't try to download until you have it
5. **Record `requestId` if `status: "failed"`** - needed for support troubleshooting

**Response (In Progress)**:
```json
{
  "result": {
    "fileId": null,
    "percentComplete": 45.0,
    "status": "inProgress"
  },
  "meta": {
    "requestId": "27c54e41-6e60-4b1c-9bd2-d64f29f289ba",
    "httpStatus": "200 - OK"
  }
}
```

**Response (Complete)**:
```json
{
  "result": {
    "fileId": "1dc4c492-fbb6-4713-a7ba-bae9b988a965-def",
    "percentComplete": 100.0,
    "status": "complete",
    "continuationToken": "UQhcCBAIGwgGCFkI..."  // Only if requested in Step 8a
  },
  "meta": {
    "requestId": "27c54e41-6e60-4b1c-9bd2-d64f29f289ba",
    "httpStatus": "200 - OK"
  }
}
```

**Response (Failed)**:
```json
{
  "result": {
    "fileId": null,
    "percentComplete": 100,  // May be 100 even when failed!
    "status": "failed"
  },
  "meta": {
    "requestId": "27c54e41-6e60-4b1c-9bd2-d64f29f289ba",
    "httpStatus": "200 - OK"
  }
}
```

**Status Values**:
- `inProgress`: Export still processing
- `complete`: Export finished successfully, `fileId` available for download
- `failed`: Export failed, record `requestId` and retry

**Response Fields**:
- `fileId` (string, nullable): File ID for download (only present when `status: "complete"`)
- `percentComplete` (number, required): Progress percentage (0.0 to 100.0)
  - ⚠️ **Convenience field only** - Don't rely on this alone!
  - May show 100% even when status is `failed`
- `status` (string, required): Current job status (see values above)
- `continuationToken` (string, optional): Token for incremental exports (if requested in Step 8a)

**Polling Strategy with Exponential Backoff**:
```python
import time

def poll_export_progress(survey_id, progress_id, max_retries=10):
    """
    Poll export progress with exponential backoff.

    Args:
        survey_id: Survey ID
        progress_id: Progress ID from start export response
        max_retries: Maximum polling attempts (default: 10)

    Returns:
        file_id: File ID for download
        continuation_token: Token for next export (if applicable)

    Raises:
        ValueError: If progress_id is None
        Exception: On export failure or timeout
    """
    # CRITICAL: Check for null progress_id
    if progress_id is None:
        raise ValueError("progress_id cannot be null - check start export response")

    retry_count = 0
    base_interval = 2  # Start with 2 seconds

    while retry_count < max_retries:
        response = requests.get(
            f"https://{{datacenter}}.qualtrics.com/API/v3/surveys/{survey_id}/export-responses/{progress_id}",
            headers={"X-API-TOKEN": api_token}
        )

        # Check for 404 - stop polling immediately
        if response.status_code == 404:
            raise Exception("Export job not found (404) - job may have expired")

        result = response.json()["result"]
        status = result["status"]
        percent = result.get("percentComplete", 0)

        print(f"Export progress: {percent}% - Status: {status}")

        # Check status (NOT just percentComplete!)
        if status == "complete":
            file_id = result.get("fileId")
            if file_id is None:
                raise Exception("Export complete but fileId is null")

            continuation_token = result.get("continuationToken")
            return file_id, continuation_token

        elif status == "failed":
            request_id = response.json()["meta"]["requestId"]
            raise Exception(f"Export failed - Contact support with requestId: {request_id}")

        # Still in progress - exponential backoff
        sleep_interval = base_interval * (2 ** retry_count)  # 2s, 4s, 8s, 16s, 32s...
        sleep_interval = min(sleep_interval, 60)  # Cap at 60 seconds
        time.sleep(sleep_interval)

        retry_count += 1

    raise Exception(f"Export timeout after {max_retries} attempts")
```

**Best Practices**:
- ✅ Always check `status` field, not just `percentComplete`
- ✅ Use exponential backoff (2s, 4s, 8s, 16s...) capped at 60s
- ✅ Stop polling on HTTP 404 immediately
- ✅ Record `requestId` from `meta` if export fails
- ✅ Validate `progressId` is not null before polling
- ✅ Set reasonable max retries (10-15 attempts = ~10 minutes)
- ✅ Save `continuationToken` for next incremental export

#### Step 8c: Download Export File
**Endpoint**: `GET /surveys/{surveyId}/export-responses/{fileId}/file`

**Purpose**: Download ZIP file containing exported responses

**Response**: Binary ZIP file stream

**Decompression**:
```python
import zipfile
import io
zipfile.ZipFile(io.BytesIO(response.content)).extractall("output_dir")
```

**Use Case**: Initial dashboard data load, historical analysis, bulk processing, backup

---

### 9. List Survey Filters
**Endpoint**: `GET /surveys/{surveyId}/filters`

**Purpose**: Get filterId values for filtered exports

**Response**:
```json
{
  "result": {
    "elements": [
      {
        "filterId": "94ec2e58-2b42-45e8-a52f-5615b5e93033",
        "filterName": "Only non-spam responses",
        "creationDate": "2025-01-05T03:37:31Z"
      }
    ]
  }
}
```

**Use Case**: Identify filters for export operations, exclude spam/test responses

---

## 🔔 Real-Time Event Subscriptions (Webhooks)

### 10. Create Event Subscription
**Endpoint**: `POST /eventsubscriptions`

**Rate Limit**: 120/min

**Purpose**: Subscribe to real-time survey events via webhooks

**⚠️ Administrator Requirement**: Brand Administrator access required

**⚠️ Critical Webhook Requirements**:
- **publicationUrl must handle HTTP GET and POST** (not just POST!)
- **Receives `application/x-www-form-urlencoded`** data (NOT JSON)
- Must return HTTP 200 within reasonable time
- Publicly accessible HTTPS endpoint strongly recommended

**Request Body (Minimal)**:
```json
{
  "publicationUrl": "https://your-app.azurewebsites.net/api/webhook",
  "topics": "surveyengine.completedResponse.SV_abc123"
}
```

**Request Body (With Security)**:
```json
{
  "publicationUrl": "https://your-app.azurewebsites.net/api/webhook",
  "topics": "surveyengine.completedResponse.SV_*",
  "encrypt": false,
  "sharedKey": "your-32-byte-secret-key-here!!"
}
```

**Request Parameters**:
- `publicationUrl` (string, required): Fully qualified webhook endpoint URL
  - Must handle HTTP GET (verification) and POST (events)
  - Must accept `application/x-www-form-urlencoded` data
  - HTTPS strongly recommended (encryption optional if using HTTPS)

- `topics` (string, required): Event topic pattern to subscribe to
  - Specific survey: `surveyengine.completedResponse.SV_abc123`
  - All surveys: `surveyengine.completedResponse.SV_*` (wildcard)
  - Survey activation: `controlpanel.activateSurvey.SV_abc123`
  - Survey deactivation: `controlpanel.deactivateSurvey.SV_abc123`
  - 360 events: `threesixty.*` (all 360 events)
  - **Wildcard notation**: Use `*` to subscribe to all events in category

- `sharedKey` (string, optional): Secret key for HMAC signature validation
  - **Highly recommended for security**
  - Used to verify message authenticity
  - Also used for encryption if `encrypt: true`
  - Recommended length: 32 bytes for AES-256

- `encrypt` (boolean, optional, default: false): Encrypt webhook payload
  - `true`: Payload encrypted with AES using `sharedKey`
  - `false`: Plain text payload (secure if using HTTPS)
  - Encryption type depends on `sharedKey` length:
    - 16 bytes = AES-128
    - 32 bytes = AES-256 (recommended)
  - Encrypted payload is Base64 encoded for transport
  - **Not necessary if using HTTPS `publicationUrl`**

**Response**:
```json
{
  "result": {
    "id": "ES_0VxzQZ9K3BsYmxT"
  },
  "meta": {
    "httpStatus": "200 - OK",
    "requestId": "unique-request-id",
    "notice": null
  }
}
```

**Response Fields**:
- `id` (string): Subscription ID for future management (list, delete)

**Supported Event Topics**:

**Survey Response Events** (Primary for Disposition Dashboard):
- `surveyengine.completedResponse.{SurveyID}` - Response completed ⭐
- `surveyengine.completedResponse.SV_*` - All survey responses (wildcard)

**Survey Lifecycle Events**:
- `controlpanel.activateSurvey.{SurveyID}` - Survey activated
- `controlpanel.deactivateSurvey.{SurveyID}` - Survey deactivated

**360 Feedback Events**:
- `threesixty.created` - 360 project created
- `threesixty.*` - All 360 events (wildcard)

**Webhook Payload Structure** (form-urlencoded):
```
CompletedDate=2025-11-10+16:00:00
Status=Completed
ResponseID=R_2wi681bbsyaTItU
BrandID=samplebrand
Topic=samplebrand.surveyengine.completedResponse.SV_abc123
SurveyID=SV_abc123
X-Qualtrics-Signature=sha256=abcdef1234567890...  # If sharedKey provided
```

**Webhook Payload Fields**:
- `CompletedDate`: ISO 8601 timestamp (URL encoded, spaces as `+`)
- `Status`: Response status (typically `"Completed"`)
- `ResponseID`: Response ID (e.g., `R_2wi681bbsyaTItU`) - **Use for deduplication**
- `BrandID`: Brand identifier
- `Topic`: Full topic path including brand
- `SurveyID`: Survey ID that triggered the event
- `X-Qualtrics-Signature`: HMAC-SHA256 signature (if `sharedKey` provided)

**HMAC Signature Validation** (Security Best Practice):
```python
import hmac
import hashlib
from urllib.parse import parse_qs

def validate_qualtrics_webhook(request_body, signature_header, shared_key):
    """
    Validate HMAC signature from Qualtrics webhook.

    Args:
        request_body: Raw request body bytes (form-urlencoded)
        signature_header: Value of X-Qualtrics-Signature header
        shared_key: Shared secret key (string)

    Returns:
        bool: True if signature is valid
    """
    # Generate HMAC from message body
    expected_signature = hmac.new(
        shared_key.encode('utf-8'),
        request_body,
        hashlib.sha256
    ).hexdigest()

    # Extract signature from header (format: "sha256=abcdef123...")
    provided_signature = signature_header.replace("sha256=", "")

    # Constant-time comparison to prevent timing attacks
    return hmac.compare_digest(expected_signature, provided_signature)

# Azure Function example
def webhook_handler(req):
    # Validate signature FIRST
    signature = req.headers.get("X-Qualtrics-Signature")
    if not validate_qualtrics_webhook(req.get_body(), signature, SHARED_KEY):
        return func.HttpResponse("Invalid signature", status_code=401)

    # Parse form data
    data = parse_qs(req.get_body().decode('utf-8'))
    response_id = data.get('ResponseID', [None])[0]
    survey_id = data.get('SurveyID', [None])[0]

    # Process webhook (return 200 quickly!)
    return func.HttpResponse("OK", status_code=200)
```

**Webhook Endpoint Requirements**:
1. **Must handle HTTP GET**: Qualtrics may send verification requests
2. **Must handle HTTP POST**: Actual event delivery
3. **Must accept `application/x-www-form-urlencoded`**: NOT JSON!
4. **Must return HTTP 200**: Indicate successful receipt
5. **Must respond quickly**: Avoid timeouts (< 5 seconds recommended)
6. **Must be idempotent**: Qualtrics retries on failure

**Retry Behavior**:
- Qualtrics retries failed deliveries (non-200 responses)
- Uses exponential backoff (exact timing not documented)
- Multiple retry attempts (at least 5)
- **Implement deduplication**: Check `ResponseID` to prevent duplicate processing

**Encryption Handling** (if `encrypt: true`):
```python
import base64
from Crypto.Cipher import AES
from Crypto.Util.Padding import unpad

def decrypt_qualtrics_payload(encrypted_msg, shared_key):
    """
    Decrypt encrypted webhook payload from Qualtrics.

    Args:
        encrypted_msg: Base64-encoded encrypted message
        shared_key: Shared secret key (16 bytes = AES-128, 32 bytes = AES-256)

    Returns:
        dict: Decrypted JSON payload
    """
    # Base64 decode the encrypted message
    encrypted_bytes = base64.b64decode(encrypted_msg)

    # Extract IV (first 16 bytes) and ciphertext
    iv = encrypted_bytes[:16]
    ciphertext = encrypted_bytes[16:]

    # Decrypt using AES CBC mode
    cipher = AES.new(shared_key.encode('utf-8'), AES.MODE_CBC, iv)
    decrypted = unpad(cipher.decrypt(ciphertext), AES.block_size)

    # Parse JSON
    return json.loads(decrypted.decode('utf-8'))
```

**Best Practices**:
- ✅ **Always use `sharedKey`** for HMAC validation (security)
- ✅ **Use HTTPS `publicationUrl`** (no need for encryption if using HTTPS)
- ✅ **Return HTTP 200 immediately** (< 5 seconds) - queue processing asynchronously
- ✅ **Implement deduplication** using `ResponseID`
- ✅ **Validate HMAC signature** before processing
- ✅ **List subscriptions first** to avoid creating duplicates
- ✅ **Use specific survey topics** instead of wildcards when possible (better performance)
- ✅ **Log webhook failures** for debugging retry behavior
- ⚠️ **Never use `encrypt: true` without understanding decryption** (adds complexity)

**Azure Function Webhook Handler Example**:
```python
import azure.functions as func
import hmac
import hashlib
from urllib.parse import parse_qs

SHARED_KEY = "your-32-byte-secret-key-here!!"

def main(req: func.HttpRequest) -> func.HttpResponse:
    # Handle GET requests (verification)
    if req.method == "GET":
        return func.HttpResponse("OK", status_code=200)

    # Validate HMAC signature
    signature = req.headers.get("X-Qualtrics-Signature", "")
    if not validate_signature(req.get_body(), signature, SHARED_KEY):
        return func.HttpResponse("Unauthorized", status_code=401)

    # Parse form-urlencoded data
    body = req.get_body().decode('utf-8')
    data = parse_qs(body)

    response_id = data.get('ResponseID', [None])[0]
    survey_id = data.get('SurveyID', [None])[0]

    # Return 200 immediately - process asynchronously
    # Send to Service Bus for processing
    service_bus_client.send_message({
        "responseId": response_id,
        "surveyId": survey_id
    })

    return func.HttpResponse("OK", status_code=200)

def validate_signature(body, signature, key):
    expected = hmac.new(key.encode(), body, hashlib.sha256).hexdigest()
    provided = signature.replace("sha256=", "")
    return hmac.compare_digest(expected, provided)
```

**Common Errors**:
- **400 Bad Request**: Invalid `publicationUrl` or `topics` format
- **401 Unauthorized**: Not a Brand Administrator
- **Webhook not receiving events**: Check firewall, verify subscription exists, test with webhook.site

**Use Case**: **PRIMARY FOR REAL-TIME DISPOSITION TRACKING** - instant updates without polling

---

### 11. List Event Subscriptions
**Endpoint**: `GET /eventsubscriptions`

**Rate Limit**: 120/min

**Purpose**: Retrieve all active webhook subscriptions for your brand

**⚠️ Administrator Requirement**:
- **Brand Administrator access required** to use this endpoint
- Regular users will receive authorization errors

**Query Parameters**:
- `offset` (integer ≥ 0, default: 0): Starting position for pagination

**Response**:
```json
{
  "result": {
    "elements": [
      {
        "id": "ES_0VxzQZ9K3BsYmxT",
        "scope": "brand",
        "topics": "surveyengine.completedResponse.SV_abc123",
        "publicationUrl": "https://your-app.azurewebsites.net/api/webhook",
        "encrypted": false,
        "successfulCalls": 1247
      },
      {
        "id": "ES_8HpQmN7R2CdXwYv",
        "scope": "brand",
        "topics": "surveyengine.completedResponse.SV_*",
        "publicationUrl": "https://your-app.azurewebsites.net/api/webhook-all",
        "encrypted": true,
        "successfulCalls": 5892
      }
    ],
    "nextPage": null
  },
  "meta": {
    "httpStatus": "200 - OK",
    "requestId": "unique-request-id",
    "notice": null
  }
}
```

**Response Fields**:
- `id` (string): Subscription ID (e.g., `ES_0VxzQZ9K3BsYmxT`)
- `scope` (string): Subscription scope (`brand` for brand-level subscriptions)
- `topics` (string): Event topic pattern subscribed to
  - Specific: `surveyengine.completedResponse.SV_abc123`
  - Wildcard: `surveyengine.completedResponse.SV_*` (all surveys)
- `publicationUrl` (string): Webhook endpoint URL
- `encrypted` (boolean): Whether webhook payload is encrypted
  - `true`: Payload encrypted with shared secret
  - `false`: Plain text payload (less secure)
- `successfulCalls` (integer ≥ 0): Count of successful webhook deliveries
  - Useful for monitoring webhook health
  - Does NOT include failed/retried calls

**Pagination**:
- `nextPage` (string or null): URL for next page, or `null` if last page
- Use `offset` parameter to navigate pages

**Use Cases**:
- **Audit active subscriptions** for compliance and monitoring
- **Monitor webhook health** via `successfulCalls` metric
- **Identify duplicate subscriptions** before creating new ones
- **Inventory webhook endpoints** for infrastructure management
- **Troubleshoot missing webhooks** (check if subscription exists)

**Best Practices**:
- ✅ List subscriptions before creating to avoid duplicates
- ✅ Monitor `successfulCalls` to detect webhook failures
- ✅ Use `scope: "brand"` to find all brand-level subscriptions
- ✅ Check for wildcard subscriptions (`SV_*`) that may conflict

**Common Scenarios**:
```python
# Check if subscription already exists for survey
subscriptions = get_event_subscriptions()
existing = [s for s in subscriptions if survey_id in s["topics"]]
if existing:
    print(f"Subscription already exists: {existing[0]['id']}")
else:
    create_event_subscription(survey_id, webhook_url)

# Monitor webhook health
unhealthy = [s for s in subscriptions if s["successfulCalls"] == 0]
if unhealthy:
    print(f"Warning: {len(unhealthy)} subscriptions with zero successful calls")
```

---

### 12. Get Event Subscription
**Endpoint**: `GET /eventsubscriptions/{subscriptionId}`

**Rate Limit**: 120/min

**Purpose**: Retrieve details for a specific webhook subscription

**⚠️ Administrator Requirement**: Brand Administrator access required

**Parameters**:
- `subscriptionId` (path, required): Subscription ID
  - Format: `^[\w\*]+(\.[\w\*]+)*$` (pattern validation)
  - Example: `ES_0VxzQZ9K3BsYmxT`
  - Get ID from List Subscriptions or Create Subscription response

**Response**:
```json
{
  "result": {
    "id": "ES_0VxzQZ9K3BsYmxT",
    "scope": "brand",
    "topics": "surveyengine.completedResponse.SV_abc123",
    "publicationUrl": "https://your-app.azurewebsites.net/api/webhook",
    "encrypted": false,
    "successfulCalls": 1247
  },
  "meta": {
    "httpStatus": "200 - OK",
    "requestId": "unique-request-id",
    "notice": null
  }
}
```

**Response Fields**: Same structure as List Subscriptions element
- `id`: Subscription ID
- `scope`: Subscription scope (`brand`)
- `topics`: Event topic pattern
- `publicationUrl`: Webhook endpoint URL
- `encrypted`: Whether payload is encrypted
- `successfulCalls`: Count of successful webhook deliveries

**Use Cases**:
- **Verify subscription configuration** after creation
- **Audit webhook endpoint** for specific subscription
- **Check encryption status** for security compliance
- **Monitor webhook health** via `successfulCalls` metric
- **Retrieve details before deletion** to confirm correct subscription

**Best Practices**:
- ✅ Use to verify subscription was created correctly
- ✅ Check `successfulCalls` to monitor webhook health
- ✅ Confirm `encrypted` status matches security requirements
- ✅ Validate `publicationUrl` before making changes

**Common Use Case - Verify After Creation**:
```python
# Create subscription
response = create_event_subscription(survey_id, webhook_url)
subscription_id = response["result"]["id"]

# Verify configuration
details = get_event_subscription(subscription_id)
assert details["publicationUrl"] == webhook_url
assert details["topics"] == f"surveyengine.completedResponse.{survey_id}"
print(f"Subscription verified: {subscription_id}")
```

---

### 13. Delete Event Subscription
**Endpoint**: `DELETE /eventsubscriptions/{subscriptionId}`

**Rate Limit**: 120/min

**Purpose**: Remove webhook subscription (stops webhook deliveries immediately)

**⚠️ Administrator Requirement**: Brand Administrator access required

**⚠️ Warning**: Deletion is **immediate and irreversible**. No confirmation prompt.

**Parameters**:
- `subscriptionId` (path, required): Subscription ID to delete
  - Format: `^[\w\*]+(\.[\w\*]+)*$` (pattern validation)
  - Example: `ES_0VxzQZ9K3BsYmxT`
  - Get ID from List Subscriptions or Create Subscription response
  - **Verify ID before deleting** - wrong ID = wrong subscription deleted!

**Response (Success)**:
```json
{
  "meta": {
    "httpStatus": "200 - OK",
    "requestId": "unique-request-id",
    "notice": null
  }
}
```

**Response Structure**:
- Empty result object (no data returned on successful deletion)
- `meta.httpStatus`: `"200 - OK"` confirms successful deletion
- `meta.requestId`: Request identifier for logging/troubleshooting
- `meta.notice`: Optional informational message (typically null)

**HTTP Status Codes**:
- **200 OK**: Subscription successfully deleted
- **401 Unauthorized**: Not a Brand Administrator
- **404 Not Found**: Subscription ID doesn't exist (already deleted or invalid)

**Use Cases**:
- **Cleanup old subscriptions** when decommissioning webhooks
- **Stop webhook deliveries** for testing or maintenance
- **Remove duplicate subscriptions** found via List Subscriptions
- **Rotate webhook endpoints** (delete old, create new)
- **Decommission surveys** (delete associated subscriptions)
- **Emergency webhook shutdown** (stop deliveries immediately)

**Best Practices**:
- ✅ **List subscriptions first** to get correct subscription IDs
- ✅ **Get subscription details** before deleting to verify correct subscription
- ✅ **Verify subscription ID** carefully (deletion is irreversible!)
- ✅ **Update application configuration** after deletion (remove subscription ID)
- ✅ **Handle 404 errors gracefully** (subscription already deleted or doesn't exist)
- ✅ **Log deletion operations** for audit trail
- ✅ **Delete old before creating new** when rotating endpoints (prevents duplicates)
- ⚠️ **Never delete without verification** - wrong ID = wrong subscription deleted!

**Safe Deletion Workflow**:
```python
def safe_delete_subscription(survey_id, subscription_id):
    """
    Safely delete webhook subscription with verification.

    Args:
        survey_id: Survey ID for verification
        subscription_id: Subscription ID to delete

    Returns:
        bool: True if deleted successfully
    """
    # Step 1: Verify subscription exists and matches survey
    try:
        details = get_event_subscription(subscription_id)
    except HTTPError as e:
        if e.response.status_code == 404:
            print(f"Subscription {subscription_id} already deleted")
            return False
        raise

    # Step 2: Verify subscription is for correct survey
    expected_topic = f"surveyengine.completedResponse.{survey_id}"
    if expected_topic not in details["topics"]:
        print(f"Warning: Subscription topic doesn't match survey {survey_id}")
        print(f"Expected: {expected_topic}")
        print(f"Actual: {details['topics']}")

        # Require explicit confirmation for mismatched subscriptions
        confirm = input("Delete anyway? (yes/no): ")
        if confirm.lower() != "yes":
            return False

    # Step 3: Log subscription details before deletion
    print(f"Deleting subscription:")
    print(f"  ID: {subscription_id}")
    print(f"  Topics: {details['topics']}")
    print(f"  URL: {details['publicationUrl']}")
    print(f"  Successful calls: {details['successfulCalls']}")

    # Step 4: Delete subscription
    try:
        delete_event_subscription(subscription_id)
        print(f"✓ Subscription {subscription_id} deleted successfully")
        return True
    except HTTPError as e:
        if e.response.status_code == 404:
            print(f"Subscription {subscription_id} was already deleted")
            return False
        raise

# Example: Rotate webhook endpoint
def rotate_webhook_endpoint(survey_id, old_subscription_id, new_webhook_url):
    """Safely rotate webhook endpoint (delete old, create new)."""
    # Delete old subscription first
    safe_delete_subscription(survey_id, old_subscription_id)

    # Create new subscription
    response = create_event_subscription(
        topics=f"surveyengine.completedResponse.{survey_id}",
        publication_url=new_webhook_url,
        shared_key="your-32-byte-secret-key"
    )

    new_subscription_id = response["result"]["id"]
    print(f"✓ New subscription created: {new_subscription_id}")

    return new_subscription_id
```

**Error Handling**:
```python
import requests

try:
    delete_event_subscription(subscription_id)
    print("Subscription deleted successfully")
except requests.HTTPError as e:
    if e.response.status_code == 401:
        print("Error: Brand Administrator access required")
    elif e.response.status_code == 404:
        print("Warning: Subscription not found (already deleted?)")
    else:
        print(f"Error deleting subscription: {e}")
```

**Common Scenarios**:

**Scenario 1: Cleanup duplicate subscriptions**
```python
# Find duplicates for a survey
subscriptions = list_event_subscriptions()
survey_subscriptions = [
    s for s in subscriptions
    if f"SV_{survey_id}" in s["topics"]
]

if len(survey_subscriptions) > 1:
    # Keep the one with most successful calls, delete others
    survey_subscriptions.sort(key=lambda x: x["successfulCalls"], reverse=True)
    keep = survey_subscriptions[0]
    delete = survey_subscriptions[1:]

    print(f"Keeping subscription {keep['id']} ({keep['successfulCalls']} successful calls)")
    for sub in delete:
        print(f"Deleting duplicate {sub['id']}")
        delete_event_subscription(sub["id"])
```

**Scenario 2: Decommission survey webhooks**
```python
def decommission_survey_webhooks(survey_id):
    """Delete all webhook subscriptions for a survey."""
    subscriptions = list_event_subscriptions()
    deleted_count = 0

    for sub in subscriptions:
        if survey_id in sub["topics"]:
            print(f"Deleting subscription {sub['id']}")
            delete_event_subscription(sub["id"])
            deleted_count += 1

    print(f"Deleted {deleted_count} subscription(s) for survey {survey_id}")
```

---

## 🏗️ Recommended Architecture for Real-Time Disposition Dashboard

### Three-Tier Data Strategy

```
┌─────────────────────────────────────────────────────────────────┐
│           TIER 1: HISTORICAL DATA (Initial Load)                 │
│   POST /export-responses → Poll → Download → Load to Cosmos DB  │
│   Use Case: Dashboard initialization, historical analysis        │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│           TIER 2: REAL-TIME UPDATES (Live Monitoring)            │
│   POST /eventsubscriptions → Webhook → Azure Function →         │
│   GET /responses/{responseId} → SignalR → Dashboard             │
│   Use Case: Live response tracking, instant updates             │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│           TIER 3: AGGREGATE METRICS (Distribution Stats)         │
│   GET /distributions?surveyId={id} → stats object →             │
│   Calculate completion/response rates → Dashboard KPIs          │
│   Use Case: High-level metrics, email health, campaign tracking │
└─────────────────────────────────────────────────────────────────┘
```

**Component Architecture**:
```
Qualtrics Webhook
    ↓
Azure Function (HTTP Trigger) ← Validate HMAC, return 200 fast
    ↓
Azure Service Bus ← Decouple processing
    ↓
Azure Function (Queue Trigger) ← Fetch full response
    ↓
Cosmos DB (responses collection) ← Store with responseId as partition key
    ↓
Azure SignalR ← Push to connected dashboard clients
    ↓
Dashboard Frontend (React/Blazor) ← Real-time updates
```

**Polling Strategy for Distributions**:
- Poll `/distributions` every 5-15 minutes for aggregate stats
- Use webhooks for individual response updates (much more efficient)
- Cache distribution metadata (changes infrequently)

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

### Rate Limiting (Official Limits - Verified 2025-11-10)

**Brand-Level Limits** (enforced at organization level):
- **Total API calls**: 3000 requests per minute across all endpoints
- **Per-endpoint limits**: Some endpoints have lower limits (see table below)
- Both limits enforced simultaneously (can hit endpoint limit before brand limit)

**Critical Endpoint Limits for Disposition Dashboard**:

| Category | Endpoint | Rate Limit (per minute) |
|----------|----------|-------------------------|
| **Distributions** | GET /distributions | 3000 |
| | GET /distributions/{distributionId} | 3000 |
| | POST /distributions | 3000 |
| **Event Subscriptions** | POST /eventsubscriptions | 120 |
| | GET /eventsubscriptions | 120 |
| | DELETE /eventsubscriptions/{id} | 120 |
| **Response Export** | POST /surveys/{surveyId}/export-responses | 100 |
| | GET /surveys/{surveyId}/export-responses/{progressId} | 1000 |
| | GET /surveys/{surveyId}/export-responses/{fileId}/file | 100 |
| | GET /surveys/{surveyId}/filters | 100 |
| **Single Response** | GET /surveys/{surveyId}/responses/{responseId} | 240 |
| | POST /surveys/{surveyId}/responses | 120 |
| | DELETE /surveys/{surveyId}/responses/{responseId} | 60 |
| **Survey Management** | GET /surveys | 3000 |
| | GET /surveys/{surveyId} | 3000 |
| | GET /survey-definitions/{surveyId}/metadata | 3000 |
| | PUT /surveys/{surveyId} | 3000 |

**Other Important Limits**:
- **API call timeout**: 5 seconds (very rare exceptions noted in API docs)
- **Survey response data**: Max 1M records per file (additional files created if exceeded)
- **File upload size**: Max 5 MB (unless endpoint specifies otherwise)
- **Mailing list names**: Max 100 characters

**Headers Returned**:
- `X-RateLimit-Limit`: Total requests allowed
- `X-RateLimit-Remaining`: Requests remaining in window
- `X-RateLimit-Reset`: Time when limit resets (epoch)

### Rate Limit Optimization Strategies

**1. Use Webhooks Over Polling** (95%+ API call reduction)
- Webhook subscriptions: 120/min limit (plenty for initial setup)
- Individual response retrieval: 240/min limit (sufficient for real-time)
- Eliminates continuous polling of distributions endpoint
- **Recommendation**: Primary approach for real-time tracking

**2. Strategic Distribution Polling** (stay well under 3000/min limit)
- Poll `/distributions` every 5-15 minutes (4-12 calls/hour)
- Use during business hours only (e.g., 8am-8pm)
- Single distribution endpoint supports 3000/min (no throttling risk)
- **Recommendation**: Aggregate metrics supplement to webhooks

**3. Efficient Export Operations** (respect 100/min limits)
- Export initiation: 100/min (sufficient for scheduled exports)
- Progress checks: 1000/min (poll every 30-60 seconds)
- File downloads: 100/min (one per completed export)
- Use exponential backoff: Start at 30s, increase to 60s, 120s
- **Recommendation**: Initial load + nightly batch updates

**4. Response Caching** (reduce redundant calls)
- Cache survey metadata (TTL: 1-4 hours, changes infrequently)
- Cache distribution metadata (TTL: 5-15 minutes, matches polling interval)
- Cache filter definitions (TTL: 1 hour, rarely change)
- Real-time response data: no caching (always fresh)

**5. Exponential Backoff for 429 Errors**
```python
import time
import random

def call_with_backoff(func, max_retries=5):
    for attempt in range(max_retries):
        try:
            return func()
        except RateLimitError as e:
            if attempt == max_retries - 1:
                raise
            # Exponential backoff: 2^attempt + jitter
            delay = (2 ** attempt) + random.uniform(0, 1)
            time.sleep(min(delay, 60))  # Cap at 60 seconds
```

**6. Batch Operations** (maximize efficiency within limits)
- Export API for bulk data (never call individual response API in loops)
- Use pagination efficiently (default 100 items, adjust if needed)
- Group webhook processing (Service Bus batching)
- **Anti-pattern**: Calling GET /responses/{responseId} for every response without webhooks

**7. Monitor Rate Limit Headers**
```python
response = requests.get(url, headers=headers)
remaining = int(response.headers.get('X-RateLimit-Remaining', 999))
reset_time = int(response.headers.get('X-RateLimit-Reset', 0))

if remaining < 100:  # Approaching limit
    logger.warning(f"Rate limit low: {remaining} remaining")
    # Implement circuit breaker or slow down
```

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

### Complete Endpoint Reference (140+ Endpoints)

**Base URL**: `https://{datacenter}.qualtrics.com/API/v3/`

**Legend**:
- ⭐ = Critical for Disposition Dashboard
- 📊 = Used for disposition tracking
- 🔧 = Administrative/setup
- ⚙️ = Advanced features

---

#### **Survey Management** (⭐ Critical)
```
GET  /surveys                                          # 3000/min - List surveys
GET  /surveys/{surveyId}                              # 3000/min - Get survey definition
GET  /survey-definitions/{surveyId}/metadata          # 3000/min - Get survey metadata ⭐
PUT  /surveys/{surveyId}                              # 3000/min - Update survey
POST /surveys                                          # 3000/min - Import survey
DELETE /surveys/{surveyId}                            # 3000/min - Delete survey
POST /survey-definitions                               # 3000/min - Create survey definition
GET  /survey-definitions/{surveyId}                   # 3000/min - Get survey definition
DELETE /survey-definitions/{surveyId}                 # 3000/min - Delete survey definition
PUT  /survey-definitions/{surveyId}/metadata          # 3000/min - Update survey metadata
```

#### **Survey Structure** (⚙️ Advanced)
```
POST /survey-definitions/{surveyId}/blocks            # 3000/min - Create block
GET  /survey-definitions/{surveyId}/blocks/{blockId}  # 3000/min - Get block
PUT  /survey-definitions/{surveyId}/blocks/{blockId}  # 3000/min - Update block
DELETE /survey-definitions/{surveyId}/blocks/{blockId}# 3000/min - Delete block
GET  /survey-definitions/{surveyId}/questions         # 3000/min - List questions
POST /survey-definitions/{surveyId}/questions         # 3000/min - Create question
GET  /survey-definitions/{surveyId}/questions/{qId}   # 3000/min - Get question
PUT  /survey-definitions/{surveyId}/questions/{qId}   # 3000/min - Update question
DELETE /survey-definitions/{surveyId}/questions/{qId} # 3000/min - Delete question
GET  /survey-definitions/{surveyId}/flow              # 3000/min - Get survey flow
PUT  /survey-definitions/{surveyId}/flow              # 3000/min - Update survey flow
PUT  /survey-definitions/{surveyId}/flow/{flowId}     # 3000/min - Update flow element
GET  /survey-definitions/{surveyId}/options           # 3000/min - Get survey options
PUT  /survey-definitions/{surveyId}/options           # 3000/min - Update survey options
```

#### **Survey Versions & Quotas** (⚙️ Advanced)
```
GET  /survey-definitions/{surveyId}/versions          # 3000/min - List versions
POST /survey-definitions/{surveyId}/versions          # 3000/min - Create version
GET  /survey-definitions/{surveyId}/versions/{vId}    # 3000/min - Get version
GET  /survey-definitions/{surveyId}/quotas            # 3000/min - List quotas
POST /survey-definitions/{surveyId}/quotas            # 3000/min - Create quota
GET  /survey-definitions/{surveyId}/quotas/{quotaId}  # 3000/min - Get quota
PUT  /survey-definitions/{surveyId}/quotas/{quotaId}  # 3000/min - Update quota
DELETE /survey-definitions/{surveyId}/quotas/{quotaId}# 3000/min - Delete quota
GET  /survey-definitions/{surveyId}/quotagroups       # 3000/min - List quota groups
POST /survey-definitions/{surveyId}/quotagroups       # 3000/min - Create quota group
GET  /survey-definitions/{surveyId}/quotagroups/{gId} # 3000/min - Get quota group
PUT  /survey-definitions/{surveyId}/quotagroups/{gId} # 3000/min - Update quota group
DELETE /survey-definitions/{surveyId}/quotagroups/{gId}# 3000/min - Delete quota group
```

#### **Survey Languages & Translations** (⚙️ Advanced)
```
GET  /surveys/{surveyId}/languages                    # 3000/min - List languages
PUT  /surveys/{surveyId}/languages                    # 3000/min - Update languages
GET  /surveys/{surveyId}/translations/{langCode}      # 2000/min - Get translations
PUT  /surveys/{surveyId}/translations/{langCode}      # 2000/min - Update translations
```

#### **Distributions** (⭐ Critical for Disposition Tracking)
```
GET  /distributions                                    # 3000/min - List all distributions 📊
POST /distributions                                    # 3000/min - Create distribution
GET  /distributions?surveyId={surveyId}               # 3000/min - List by survey ⭐📊
GET  /distributions/{distributionId}                  # 3000/min - Get distribution ⭐📊
DELETE /distributions/{distributionId}                # 3000/min - Delete distribution
POST /distributions/{distributionId}/reminders        # 3000/min - Send reminders
POST /distributions/{distributionId}/thankyous        # 3000/min - Send thank yous
GET  /distributions/{distributionId}/links            # 500/min - Get distribution links
GET  /distributions/{distributionId}/history          # 300/min - Get distribution history
```

#### **SMS & WhatsApp Distributions** (⚙️ Advanced)
```
POST /distributions/sms                                # 1000/min - Create SMS distribution
GET  /distributions/sms                                # 1000/min - List SMS distributions
GET  /distributions/sms/{smsDistributionId}           # 1000/min - Get SMS distribution
DELETE /distributions/sms/{smsDistributionId}         # 1000/min - Delete SMS distribution
POST /distributions/whatsapp                           # 1000/min - Create WhatsApp distribution
GET  /distributions/whatsapp                           # 1000/min - List WhatsApp distributions
GET  /distributions/whatsapp/{whatsAppDistributionId} # 1000/min - Get WhatsApp distribution
DELETE /distributions/whatsapp/{whatsAppDistributionId}# 1000/min - Delete WhatsApp distribution
```

#### **Survey Responses - Individual** (⭐ Critical for Webhooks)
```
POST /surveys/{surveyId}/responses                    # 120/min - Create response
GET  /surveys/{surveyId}/responses/{responseId}       # 240/min - Get response ⭐
DELETE /surveys/{surveyId}/responses/{responseId}     # 60/min - Delete response
PUT  /responses/{responseId}                          # 3000/min - Update response
GET  /surveys/{surveyId}/responses/{rId}/uploaded-files/{fId} # 120/min - Get uploaded file
GET  /surveys/{surveyId}/response-schema              # 60/min - Get response schema
```

#### **Survey Responses - Bulk Export** (⭐ Critical for Initial Load)
```
POST /surveys/{surveyId}/export-responses             # 100/min - Start export ⭐
GET  /surveys/{surveyId}/export-responses/{progressId}# 1000/min - Check progress ⭐
GET  /surveys/{surveyId}/export-responses/{fileId}/file # 100/min - Download file ⭐
GET  /surveys/{surveyId}/filters                      # 100/min - List filters ⭐
POST /surveys/{surveyId}/import-responses             # 100/min - Import responses
GET  /surveys/{surveyId}/import-responses/{progressId}# 100/min - Check import progress
```

#### **Survey Responses - Batch Operations** (⚙️ Advanced)
```
POST /surveys/{surveyId}/update-responses             # 10/min - Batch update responses
GET  /surveys/{surveyId}/update-responses/{progressId}# 240/min - Check update progress
POST /surveys/{surveyId}/delete-responses             # 10/min - Batch delete responses
GET  /surveys/{surveyId}/delete-responses/{progressId}# 240/min - Check delete progress
```

#### **Legacy Response Export** (⚙️ Legacy)
```
POST /responseexports                                  # 3000/min - Create export (legacy)
GET  /responseexports/{responseExportId}              # 3000/min - Get export status (legacy)
GET  /responseexports/{responseExportId}/file         # 3000/min - Download file (legacy)
POST /responseimports                                  # 3000/min - Import responses (legacy)
GET  /responseimports/{responseImportId}              # 3000/min - Get import status (legacy)
```

#### **Event Subscriptions (Webhooks)** (⭐ Critical for Real-Time)
```
GET  /eventsubscriptions                              # 120/min - List subscriptions
POST /eventsubscriptions                              # 120/min - Create subscription ⭐
GET  /eventsubscriptions/{subscriptionId}             # 120/min - Get subscription
DELETE /eventsubscriptions/{subscriptionId}           # 120/min - Delete subscription
```

#### **Survey Taking APIs** (⚙️ Advanced)
```
POST /surveys/{surveyId}/sessions                     # 3000/min - Create session
GET  /surveys/{surveyId}/sessions/{sessionId}         # 3000/min - Get session
POST /surveys/{surveyId}/sessions/{sessionId}         # 3000/min - Update session
DELETE /surveys/{surveyId}/sessions/{sessionId}       # 3000/min - Delete session
```

#### **Directories & Contacts** (🔧 Administrative)
```
GET  /directories                                      # 3000/min - List directories
GET  /directories/{directoryId}/contacts/optedOutContacts # 3000/min - List opted out
GET  /directories/{directoryId}/contacts              # 3000/min - List contacts
POST /directories/{directoryId}/contacts              # 500/min - Create contact
GET  /directories/{directoryId}/contacts/{contactId}  # 3000/min - Get contact
PUT  /directories/{directoryId}/contacts/{contactId}  # 500/min - Update contact
DELETE /directories/{directoryId}/contacts/{contactId}# 500/min - Delete contact
POST /directories/{directoryId}/contacts/search       # 500/min - Search contacts
GET  /directories/{directoryId}/contacts/{cId}/history# 3000/min - Get contact history
POST /directories/{directoryId}/export-contacts       # 10/min - Export contacts
GET  /directories/{directoryId}/export-contacts/{pId}/status # 10/min - Check export
GET  /directories/{directoryId}/export-contacts/{fId}/file # 10/min - Download export
```

#### **Mailing Lists** (🔧 Administrative)
```
GET  /directories/{directoryId}/mailinglists          # 3000/min - List mailing lists
POST /directories/{directoryId}/mailinglists          # 500/min - Create mailing list
GET  /directories/{directoryId}/mailinglists/{mlId}   # 3000/min - Get mailing list
PUT  /directories/{directoryId}/mailinglists/{mlId}   # 500/min - Update mailing list
DELETE /directories/{directoryId}/mailinglists/{mlId} # 500/min - Delete mailing list
POST /directories/{dirId}/mailinglists/{mlId}/contacts # 500/min - Add contact to list
GET  /directories/{dirId}/mailinglists/{mlId}/contacts # 3000/min - List contacts in list
GET  /directories/{dirId}/mailinglists/{mlId}/bouncedContacts # 3000/min - List bounced
GET  /directories/{dirId}/mailinglists/{mlId}/optedOutContacts # 3000/min - List opted out
GET  /directories/{dirId}/mailinglists/{mlId}/contacts/{cId} # 3000/min - Get contact
PUT  /directories/{dirId}/mailinglists/{mlId}/contacts/{cId} # 500/min - Update contact
DELETE /directories/{dirId}/mailinglists/{mlId}/contacts/{cId} # 500/min - Remove contact
GET  /directories/{dirId}/mailinglists/{mlId}/contacts/{cId}/history # 3000/min - History
```

#### **Research Core Contacts (Legacy)** (⚙️ Legacy)
```
GET  /mailinglists                                     # 3000/min - List mailing lists
POST /mailinglists                                     # 3000/min - Create mailing list
GET  /mailinglists/{mailingListId}                    # 3000/min - Get mailing list
PUT  /mailinglists/{mailingListId}                    # 3000/min - Update mailing list
DELETE /mailinglists/{mailingListId}                  # 3000/min - Delete mailing list
GET  /mailinglists/{mailingListId}/contacts           # 3000/min - List contacts
POST /mailinglists/{mailingListId}/contacts           # 3000/min - Add contact
GET  /mailinglists/{mlId}/contacts/{contactId}        # 3000/min - Get contact
PUT  /mailinglists/{mlId}/contacts/{contactId}        # 3000/min - Update contact
DELETE /mailinglists/{mlId}/contacts/{contactId}      # 3000/min - Delete contact
POST /mailinglists/{mlId}/contactimports              # 3000/min - Import contacts
GET  /mailinglists/{mlId}/contactimports/{ciId}       # 3000/min - Get import status
GET  /mailinglists/{mlId}/contactimports/{ciId}/summary # 3000/min - Get import summary
GET  /mailinglists/{mlId}/samples                     # 3000/min - List samples
GET  /mailinglists/{mlId}/samples/{sampleId}          # 3000/min - Get sample
```

#### **Contact Imports** (🔧 Administrative)
```
POST /directories/{dirId}/mailinglists/{mlId}/transactioncontacts # 100/min - Import
GET  /directories/{dirId}/mailinglists/{mlId}/transactioncontacts/{iId} # 500/min - Status
GET  /directories/{dirId}/mailinglists/{mlId}/transactioncontacts/{iId}/summary # 3000/min - Summary
GET  /directories/{dirId}/imports/api-import/jobs/{iId}/report # Rate limit varies
```

#### **Contact Transactions** (⚙️ Advanced)
```
GET  /directories/{dirId}/contacts/{cId}/transactions # 3000/min - List transactions
POST /directories/{directoryId}/transactions          # 500/min - Create transaction
GET  /directories/{dirId}/transactions/{transactionId}# 3000/min - Get transaction
POST /directories/{dirId}/transactions/{transactionId}# 500/min - Update transaction
PUT  /directories/{dirId}/transactions/{transactionId}# 500/min - Replace transaction
DELETE /directories/{dirId}/transactions/{transactionId}# 500/min - Delete transaction
POST /directories/{dirId}/transactions/{tId}/enrichments # Rate limit varies
```

#### **Transaction Batches** (⚙️ Advanced)
```
GET  /directories/{dirId}/transactionbatches          # 3000/min - List batches
POST /directories/{dirId}/transactionbatches          # 500/min - Create batch
GET  /directories/{dirId}/transactionbatches/{bId}    # 3000/min - Get batch
DELETE /directories/{dirId}/transactionbatches/{bId}  # 500/min - Delete batch
GET  /directories/{dirId}/transactionbatches/{bId}/transactions # 3000/min - List
POST /directories/{dirId}/transactionbatches/{bId}/transactions # 3000/min - Add
DELETE /directories/{dirId}/transactionbatches/{bId}/transactions/{tId} # 500/min - Remove
```

#### **Samples & Sample Definitions** (⚙️ Advanced)
```
GET  /directories/{dirId}/samples/definitions         # 3000/min - List definitions
POST /directories/{dirId}/samples/definitions         # 500/min - Create definition
GET  /directories/{dirId}/samples/definitions/{sdId}  # 3000/min - Get definition
PUT  /directories/{dirId}/samples/definitions/{sdId}  # 3000/min - Update definition
DELETE /directories/{dirId}/samples/definitions/{sdId}# 500/min - Delete definition
GET  /directories/{directoryId}/samples               # 3000/min - List samples
POST /directories/{directoryId}/samples               # 500/min - Create sample
GET  /directories/{dirId}/samples/{sampleId}          # 3000/min - Get sample
PUT  /directories/{dirId}/samples/{sampleId}          # 3000/min - Update sample
DELETE /directories/{dirId}/samples/{sampleId}        # 3000/min - Delete sample
GET  /directories/{dirId}/samples/{sId}/contacts      # 3000/min - List contacts
GET  /directories/{dirId}/samples/progress/{progressId}# 3000/min - Check progress
```

#### **Segments** (⚙️ Advanced)
```
GET  /directories/{directoryId}/segments              # 60/min - List segments
POST /directories/{directoryId}/segments              # 60/min - Create segment
GET  /directories/{dirId}/segments/{segmentId}        # 60/min - Get segment
PUT  /directories/{dirId}/segments/{segmentId}        # 60/min - Update segment
DELETE /directories/{dirId}/segments/{segmentId}      # 60/min - Delete segment
GET  /directories/{dirId}/segments/{sId}/contacts     # 3000/min - List segment contacts
GET  /directories/{dirId}/segments/{sId}/contacts/{cId}# 3000/min - Get segment contact
POST /directories/{dirId}/segments/{sId}/refresh-jobs # 60/min - Refresh segment
GET  /directories/{dirId}/segments/{sId}/refresh-jobs/{pId}# 1000/min - Check refresh
POST /directories/{dirId}/export-contact-segment-memberships # 1/min - Export memberships
GET  /directories/{dirId}/export-contact-segment-memberships/{eId}# 50/min - Check export
GET  /directories/{dirId}/export-contact-segment-memberships/{fId}/file# 50/min - Download
```

#### **Contact Frequency Rules** (⚙️ Advanced)
```
GET  /directories/{dirId}/frequencyrules              # 3000/min - List rules
POST /directories/{dirId}/frequencyrules              # 3000/min - Create rule
GET  /directories/{dirId}/frequencyrules/{ruleId}     # 3000/min - Get rule
PUT  /directories/{dirId}/frequencyrules/{ruleId}     # 3000/min - Update rule
DELETE /directories/{dirId}/frequencyrules/{ruleId}   # 3000/min - Delete rule
```

#### **Libraries** (🔧 Administrative)
```
GET  /libraries                                        # 3000/min - List libraries
GET  /libraries/{libraryId}/survey/blocks             # 3000/min - List library blocks
GET  /libraries/{libraryId}/survey/questions          # 3000/min - List library questions
GET  /libraries/{libraryId}/survey/surveys            # 3000/min - List library surveys
GET  /libraries/{libraryId}/messages                  # 3000/min - List messages
POST /libraries/{libraryId}/messages                  # 3000/min - Create message
GET  /libraries/{libraryId}/messages/{messageId}      # 3000/min - Get message
PUT  /libraries/{libraryId}/messages/{messageId}      # 3000/min - Update message
DELETE /libraries/{libraryId}/messages/{messageId}    # 3000/min - Delete message
POST /libraries/{libraryId}/graphics                  # 3000/min - Upload graphic
DELETE /libraries/{libraryId}/graphics/{graphicId}    # 3000/min - Delete graphic
```

#### **Groups** (🔧 Administrative)
```
GET  /groups                                           # 600/min - List groups
POST /groups                                           # 600/min - Create group
GET  /groups/{groupId}                                # 600/min - Get group
PUT  /groups/{groupId}                                # 600/min - Update group
DELETE /groups/{groupId}                              # 600/min - Delete group
POST /groups/{groupId}/members                        # 600/min - Add member
GET  /groups/{groupId}/members                        # 1000/min - List members
DELETE /groups/{groupId}/members/{userId}             # 3000/min - Remove member
```

#### **Users** (🔧 Administrative)
```
GET  /whoami                                           # 3000/min - Get current user ⭐
GET  /users                                            # 3000/min - List users
POST /users                                            # 3000/min - Create user
GET  /users/{userId}                                  # 3000/min - Get user
PUT  /users/{userId}                                  # 3000/min - Update user
DELETE /users/{userId}                                # 3000/min - Delete user
GET  /users/{userId}/apitoken                         # 3000/min - Get API token
POST /users/{userId}/apitoken                         # 3000/min - Generate API token
```

#### **Divisions & Organizations** (🔧 Administrative)
```
POST /divisions                                        # 3000/min - Create division
GET  /divisions/{divisionId}                          # 3000/min - Get division
PUT  /divisions/{divisionId}                          # 3000/min - Update division
GET  /organizations/{organizationId}                  # 5/min - Get organization (LOW LIMIT!)
```

#### **Collaboration & Permissions** (🔧 Administrative)
```
POST /surveys/{surveyId}/permissions/collaborations   # 3000/min - Add collaborator
POST /surveys/{surveyId}/embeddeddatafields           # 3000/min - Add embedded data field
GET  /surveys/{surveyId}/quotas                       # 3000/min - List quotas (legacy)
POST /conjoint-maxdiff/{projectId}/permissions/collaborations # 100/min - Add collaborator
```

#### **Datasets (XM Directory)** (⚙️ Advanced)
```
POST /datasets                                         # 500/min - Create dataset
GET  /datasets/{datasetId}                            # 500/min - Get dataset
POST /datasets/{datasetId}/data                       # 500/min - Add data
GET  /datasets/{datasetId}/data/{id}                  # 500/min - Get data
PUT  /datasets/{datasetId}/data/{id}                  # 500/min - Update data
DELETE /datasets/{datasetId}/data/{id}                # 500/min - Delete data
```

#### **Imported Data Projects** (⚙️ Advanced)
```
POST /imported-data-projects                           # 500/min - Create IDP
GET  /imported-data-projects/{idpSourceId}            # 500/min - Get IDP
POST /imported-data-projects/{idpSourceId}            # 500/min - Update IDP
POST /imported-data-projects/{idpId}/exports          # 100/min - Export data
GET  /imported-data-projects/{idpId}/exports/{jobId}  # 1000/min - Check export
GET  /imported-data-projects/{idpId}/exports/{fId}/file # 100/min - Download export
POST /imported-data-projects/{idpId}/record           # 500/min - Add record
POST /imported-data-projects/{idpId}/records          # 500/min - Add records (bulk)
GET  /imported-data-projects/{idpId}/records/{uField} # 500/min - Get record
PUT  /imported-data-projects/{idpId}/records/{uField} # 500/min - Update record
DELETE /imported-data-projects/{idpId}/records/{uField}# 500/min - Delete record
```

#### **EX (Employee Experience) APIs** (⚙️ EX-Specific)
```
GET  /employee-directories/{dirId}/participants/{pId} # 75/min - Get participant
GET  /employee-directories/{dirId}/participants       # 75/min - List participants
POST /employee-directories/{dirId}/participants       # 75/min - Create participant
POST /employee-directories/{dirId}/import-participants # 75/min - Import participants
GET  /employee-directories/{dirId}/import-participants/{jId} # 75/min - Check import
GET  /employee-directories/{dirId}/import-participants/results/{rId} # 75/min - Get results
POST /employee-directories/{dirId}/delete-participants # 75/min - Delete participants
GET  /employee-directories/{dirId}/delete-participants/{jId} # 75/min - Check delete
GET  /employee-directories/{dirId}/delete-participants/results/{rId} # 75/min - Get results
GET  /employee-directories/{dirId}/export-participants # 75/min - List exports
POST /employee-directories/{dirId}/export-participants # 75/min - Export participants
GET  /employee-directories/{dirId}/export-participants/{jId} # 75/min - Check export
GET  /employee-directories/{dirId}/export-participants/results/{rId}/file # 75/min - Download
```

*(EX Projects, Ticketing, Audit APIs, and other specialized endpoints omitted for brevity - 40+ additional endpoints available)*

#### **Data Access & Privacy** (🔧 Compliance)
```
GET  /customer-data-requests/{customerDataRequestId}  # 100/min - Get data request
POST /customer-data-requests                           # 100/min - Create data request
GET  /customer-data-requests/{cdId}/files/{fileId}    # 100/min - Download data file
GET  /op-erase-personal-data                          # 20/min - List erasure requests
POST /op-erase-personal-data                          # 20/min - Create erasure request
GET  /op-erase-personal-data/{requestId}              # 20/min - Get erasure status
```

#### **Audit & Logging** (🔧 Compliance)
```
GET  /logs/activitytypes                              # 3000/min - List activity types
GET  /logs                                             # 3000/min - Get audit logs
POST /audit-exports                                    # 30/min - Export audit logs
GET  /audit-exports/{exportId}                        # 30/min - Check export status
GET  /audit-exports/{exportId}/files/{fileId}         # 30/min - Download audit file
GET  /audit-events                                     # 120/min - Get audit events
```

#### **OAuth & Authentication** (🔧 Security)
```
GET  /oauthtokens/{tokenType}                         # 500/min - List OAuth tokens
POST /oauthtokens/{tokenType}/delete                  # 3000/min - Delete OAuth tokens
GET  /organizations/{orgId}/clientcertificates        # 120/min - List certificates
POST /organizations/{orgId}/clientcertificates        # 120/min - Upload certificate
POST /organizations/{orgId}/clientcertificates/{cId}  # 120/min - Update certificate
GET  /organizations/{orgId}/clientcertificates/{cId}  # 120/min - Get certificate
```

#### **Workflow Management** (⚙️ Advanced)
```
GET  /workflow-summaries                              # 120/min - List workflows
PUT  /workspaces/{wId}/workflows/{workflowId}         # 120/min - Transfer workflow
```

#### **Automations** (⚙️ Advanced)
```
GET  /automations/{automationId}/files                # 100/min - List automation files
```

#### **Bulk Entity Import** (🔧 Administrative)
```
POST /directories/{directoryId}/imports               # 10/min - Create bulk import
```

---

**Total Endpoint Count**: 140+ documented endpoints across 25+ categories

**For Disposition Dashboard**: Focus on ⭐ marked endpoints (14 critical endpoints)

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
This domain knowledge follows **Version Naming Convention** (UNNILBINILNIL = 1.2.0):
- **Major** (1.x.x): Breaking API changes, architecture shifts
- **Minor** (x.2.x): New Qualtrics API features, significant enhancements ← **Current: Complete endpoint documentation from official sources**
- **Patch** (x.x.0): Documentation updates, clarifications, examples

**Recent Updates**:
- **1.2.0** (2025-11-10): **MAJOR UPDATE** - Complete API endpoint documentation with verified paths, parameters, and response structures from official Qualtrics documentation. Added:
  - Complete survey management endpoints (List, Get, Get Metadata, Update)
  - Full distribution endpoints with disposition tracking stats object
  - Complete response export workflow (3-step async process)
  - Individual response retrieval for webhooks
  - Event subscription (webhook) documentation
  - Filter API for targeted exports
  - Standard API response structure and HTTP status codes
  - Three-tier architecture recommendation (historical + real-time + aggregate)
  - Webhook payload structure and requirements
  - Export parameters (format, filters, date ranges, labels)
  - Idempotency and retry patterns for webhooks
  - **Official rate limits documentation** with per-endpoint limits table
  - Enhanced rate limit optimization strategies (7 strategies with code examples)
  - API timeout limits (5 seconds standard)
  - Survey response file size limits (1M records max)
  - File upload limits (5 MB max)
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
