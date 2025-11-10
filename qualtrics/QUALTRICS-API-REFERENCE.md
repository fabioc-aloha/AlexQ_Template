# Qualtrics API Reference - QualticsDashboard

**Version**: 1.1.0
**Last Updated**: November 4, 2025
**API Base URL**: `https://{datacenterId}.qualtrics.com/API/v3`
**Authentication**: X-API-TOKEN header

---

## � API Overview

Qualtrics provides APIs under **two different namespaces** with different purposes:

### `/surveys/` Namespace (Survey Management)
- **Purpose**: Retrieve survey metadata and basic structure
- **Operations**: List, Get, Update (metadata only), Import, Delete
- **Use Cases**: Survey discovery, metadata management, basic operations
- **What You Get**: Survey ID, name, owner, dates, active status, basic structure
- **What You DON'T Get**: Granular CRUD operations for survey elements

### `/survey-definitions/` Namespace (Survey Definition API)
- **Purpose**: Programmatic creation and editing of survey design
- **Operations**: Full CRUD (Create, Read, Update, Delete) for all survey elements
- **Use Cases**: Building applications around surveys, survey lifecycle automation
- **What You Get**: Complete control over Questions, Blocks, Flow, Options, Quotas, Translations
- **Granularity**: More detailed format with complete element-level operations

**Important**: These two namespaces represent surveys in **different formats**. The `/survey-definitions/` API provides more granularity and completeness.

### Survey Definition API Capabilities

The Survey Definition API facilitates all steps in the survey lifecycle leading up to response collection:

| Element | Purpose | Operations |
|---------|---------|------------|
| **Question** | Prompts, inputs, and configurations | GET, LIST, POST, PUT, DELETE |
| **Flow** | Order of presentation and integrations | GET, PUT (flow & elements) |
| **Block** | Grouping of questions with config | GET, POST, PUT, DELETE |
| **Options** | Survey behavior (back button, theming, etc.) | GET, PUT |
| **Quota Groups** | Multiple quota configurations | GET, POST, PUT, DELETE |
| **Quotas** | Response counting and screening | GET, LIST, POST, PUT, DELETE |
| **Metadata** | Links to Qualtrics entities (User, Brand) | GET |
| **Survey Definition** | Container for all elements | GET, POST, DELETE |
| **Version** | Survey version management | GET, LIST, POST |
| **Languages** | Localization language options | GET, PUT |
| **Translations** | Localized text for questions | GET, PUT |

### HTTP Methods & Status Codes

**HTTP Methods**:
- `GET` - Retrieve resource(s)
- `POST` - Create new resource
- `PUT` - Update existing resource (also used to remove in some endpoints)
- `DELETE` - Remove resource

**Common Status Codes**:
- `200 OK` - Request successful
- `400 Bad Request` - Malformed request or invalid parameters
- `401 Unauthorized` - Invalid credentials or wrong datacenter
- `403 Forbidden` - Authenticated but unauthorized for operation
- `404 Not Found` - Endpoint or resource does not exist
- `500 Internal Server Error` - Qualtrics system error

---

## �📋 Table of Contents

1. [Survey APIs](#survey-apis) - `/surveys/` namespace (metadata & management)
2. [Distribution APIs](#distribution-apis)
3. [Distribution History APIs](#distribution-history-apis)
4. [Mailing List APIs](#mailing-list-apis)
5. [Directory APIs](#directory-apis)
6. [Common Patterns](#common-patterns)
7. [Implementation Notes](#implementation-notes)

---

## Survey APIs

**Namespace**: `/surveys/` (Survey Management)

Survey APIs allow you to manage survey metadata and design. These APIs return survey structure and configuration, **not survey responses** (use Response Export APIs for that).

**Note**: For programmatic survey creation and element-level editing, use the `/survey-definitions/` API instead (see Overview above).

### List Surveys

**Endpoint**: `GET /surveys`
**Purpose**: Get all surveys owned by or collaborated with you (individual collaborations only)
**Used In**: Not currently used in QualticsDashboard

#### Request

```http
GET /surveys
X-API-TOKEN: {your-api-token}
```

#### Response (200 OK)

```json
{
  "result": {
    "elements": [
      {
        "id": "SV_1234567890",
        "isActive": true,
        "lastModified": "2017-05-23T15:01:02Z",
        "name": "Spring Survey",
        "ownerId": "UR_abcdefghij"
      },
      {
        "id": "SV_2345678901",
        "isActive": false,
        "lastModified": "2017-05-18T19:49:31Z",
        "name": "Summer Survey",
        "ownerId": "UR_bcdefghijklmno"
      }
    ],
    "nextPage": null
  },
  "meta": {
    "httpStatus": "200 - OK",
    "requestId": "req_123456"
  }
}
```

#### Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Survey identifier (format: `SV_*`) |
| `isActive` | boolean | Whether survey is currently active (not expired or paused) |
| `lastModified` | string | Date/time of last change (ISO 8601 format) |
| `name` | string | Survey name (also referred to as project name) |
| `ownerId` | string | Survey owner's user ID |
| `nextPage` | string/null | URL of next page of results (null if no more) |

#### Important Notes

- ℹ️ **Individual Collaborations Only**: Returns surveys you own + surveys collaborated with individual users (not group collaborations)
- ℹ️ **Discovery**: Use this to find available surveys before calling Get Survey
- ℹ️ **Metadata Only**: Returns basic info (id, name, owner, dates, active status)
- ℹ️ **Use Case**: Survey selection UI, admin dashboards, survey inventory

---

### Get Survey

**Endpoint**: `GET /surveys/{surveyId}`
**Purpose**: Retrieve complete survey design and metadata (not responses)
**Used In**: `QualtricsService.GetSurveyAsync()`

#### Request

```http
GET /surveys/{surveyId}
X-API-TOKEN: {your-api-token}
```

#### Path Parameters

| Parameter | Type | Required | Description | Format |
|-----------|------|----------|-------------|--------|
| `surveyId` | string | ✅ | Survey identifier | `^SV_[0-9a-zA-Z]{11,15}$` |

#### Response (200 OK)

The response contains two main categories of information:

**1. Survey Metadata**:
- Survey ID, name, owner ID, organization ID
- Active status, creation date, last modified date, expiration dates

**2. Survey Design**:
- Questions (types, text, answer options)
- Blocks (survey sections)
- Flow (order of survey elements)
- Embedded data
- Comments
- Loop & merge configuration
- Response counts

```json
{
  "result": {
    "id": "SV_eajskCRbMSRKkRf",
    "name": "My Survey",
    "ownerId": "UR_1M4aHozEkSxUfCl",
    "organizationId": "apidocs",
    "isActive": true,
    "creationDate": "2017-05-16T17:59:31Z",
    "lastModifiedDate": "2017-05-16T17:59:55Z",
    "expiration": {
      "startDate": "2017-05-22T00:00:00Z",
      "endDate": "2017-05-24T00:00:00Z"
    },
    "questions": {
      "QID1": {
        "questionType": {
          "type": "MC",
          "selector": "SAVR",
          "subSelector": "TX"
        },
        "questionText": "Multiple choice<div><br></div>",
        "questionLabel": null,
        "questionName": "Q1",
        "validation": {
          "doesForceResponse": false
        },
        "choices": {
          "1": {
            "analyze": true,
            "choiceText": "Click to write Choice 1",
            "description": "Click to write Choice 1",
            "imageDescription": null,
            "recode": "1",
            "variableName": null
          },
          "2": {
            "analyze": true,
            "choiceText": "Click to write Choice 2",
            "description": "Click to write Choice 2",
            "imageDescription": null,
            "recode": "2",
            "variableName": null
          }
        }
      }
    },
    "exportColumnMap": {
      "Q1": {
        "question": "QID1"
      }
    },
    "blocks": {
      "BL_1234567890": {
        "description": "Block 1",
        "elements": [
          {
            "type": "Question",
            "questionId": "QID1"
          }
        ]
      }
    },
    "flow": [
      {
        "type": "Block",
        "id": "BL_1234567890"
      }
    ],
    "embeddedData": [
      {
        "name": "customField1",
        "defaultValue": "defaultValue1"
      }
    ],
    "comments": {
      "QID1": {
        "commentList": [
          {
            "message": "Some note text for question Q1",
            "timestamp": 1495745520,
            "userId": "UR_1234567890"
          }
        ]
      }
    },
    "loopAndMerge": {
      "BL_1234567890": {
        "loopType": "Question",
        "columnNames": {
          "field1": ["value1", "value2"],
          "field2": ["value3", "value4"]
        },
        "loopQuestionMeta": {
          "questionId": "QID1",
          "questionType": "MC"
        },
        "randomizationMeta": {}
      }
    },
    "responseCounts": {
      "auditable": 150,
      "deleted": 5,
      "generated": 10
    }
  },
  "meta": {
    "httpStatus": "200 - OK",
    "requestId": "req_123456"
  }
}
```

#### Metadata Fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Survey identifier |
| `name` | string | Survey name (also project name) |
| `ownerId` | string | Survey owner's user ID |
| `organizationId` | string | Organization/brand ID (same as data center) |
| `isActive` | boolean | Whether survey is currently active |
| `creationDate` | string | Date/time survey created (ISO 8601 format) |
| `lastModifiedDate` | string | Date/time last modified (ISO 8601 format) |
| `expiration` | object | Start/end dates for survey validity |

#### Design Structure Fields

| Field | Type | Description |
|-------|------|-------------|
| `questions` | object | All survey questions with types, text, choices |
| `blocks` | object | Survey sections containing question elements |
| `flow` | array | Order of blocks/elements in survey |
| `exportColumnMap` | object | Maps question names (Q1) to internal IDs (QID1) |
| `embeddedData` | array | Custom data fields with default values |
| `comments` | object | Notes/comments on questions |
| `loopAndMerge` | object | Loop configuration for repeated blocks |
| `responseCounts` | object | Counts: auditable, deleted, generated responses |

#### blocks Object

Block IDs (e.g., `BL_1234567890`) contain:

| Field | Type | Description |
|-------|------|-------------|
| `description` | string | Block description/name |
| `elements` | array | Array of objects with `type` and `questionId` |

#### comments Object

Question IDs with comments contain `commentList` array:

| Field | Type | Description |
|-------|------|-------------|
| `message` | string | Comment text |
| `timestamp` | number | Unix epoch time (seconds since 1970-01-01) |
| `userId` | string | User who created comment |

#### exportColumnMap Object

Maps display names to internal IDs:
- **Keys**: Question names as shown in UI (e.g., `Q1`)
- **Values**: Object with `question` field containing internal ID (e.g., `QID1`)
- **Use Case**: Essential for mapping survey responses to questions

#### loopAndMerge Object

Block IDs with loop configuration:

| Field | Type | Description |
|-------|------|-------------|
| `loopType` | string | `Static` (fixed) or `Question` (dynamic based on answers) |
| `columnNames` | object | Fields and their values for loop iterations |
| `loopQuestionMeta` | object | Question driving the loop (questionId, questionType) |
| `randomizationMeta` | object | Loop randomization settings |

**Loop Types**:
- **Static**: Always loops the same regardless of previous answers
- **Question**: Loop based on criterion (e.g., "UnselectedChoices", "SelectedChoices")

#### questions Object

Each question ID (e.g., `QID1`) contains:

| Field | Type | Description |
|-------|------|-------------|
| `questionType` | object | Type (`MC`, `TE`, etc.), selector, subSelector |
| `questionText` | string | Question text (may contain HTML) |
| `questionName` | string | Display name (e.g., `Q1`) |
| `questionLabel` | string/null | Optional label |
| `validation` | object | Validation rules (e.g., `doesForceResponse`) |
| `choices` | object | Answer choices (for multiple choice, etc.) |

**Question Types**: Multiple Choice, Text Entry, Matrix Table, Slider, Rank Order, Side by Side, Net Promoter Score, Constant Sum, Descriptive Text, Timer, Captcha, and many more.

#### Important Notes

- ⚠️ **Does NOT return survey responses** - Use Response Export Workflow APIs for actual response data
- ⚠️ **Format incompatibility**: Output cannot be re-imported (use Import Survey API with .qsf, .txt, or .doc files)
- ⚠️ **Complex structure**: Response contains extensive survey design details
- ℹ️ **Use case**: Understanding survey structure, mapping responses to questions
- ℹ️ Survey ID format: `SV_` followed by 11-15 alphanumeric characters

---

### Get Survey Quotas

**Endpoint**: `GET /surveys/{surveyId}/quotas`
**Purpose**: Retrieve survey response quota information
**Used In**: Not currently used in QualticsDashboard

#### Request

```http
GET /surveys/{surveyId}/quotas?offset=0
X-API-TOKEN: {your-api-token}
```

#### Path Parameters

| Parameter | Type | Required | Description | Format |
|-----------|------|----------|-------------|--------|
| `surveyId` | string | ✅ | Survey identifier | `^SV_[0-9a-zA-Z]{11,15}$` |

#### Query Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `offset` | integer | ❌ | 0 | Starting position for pagination (>= 0) |

#### Response (200 OK)

```json
{
  "result": {
    "elements": [
      {
        "id": "QO_1234567890abcde",
        "name": "Age 18-25 Quota",
        "count": 45,
        "quota": 100,
        "logicType": "Simple"
      },
      {
        "id": "QO_0987654321fedcb",
        "name": "Location Cross Quota",
        "count": 230,
        "quota": 500,
        "logicType": "Cross"
      }
    ],
    "nextPage": "string_or_null"
  },
  "meta": {
    "httpStatus": "200",
    "requestId": "req_123456"
  }
}
```

#### Quota Fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Unique quota identifier |
| `name` | string | Quota category name |
| `count` | integer | Number of responses received (>= 0) |
| `quota` | integer | Quota limit/target (>= 0) |
| `logicType` | string | `Simple` (single condition) or `Cross` (multiple conditions) |

#### Important Notes

- ℹ️ **Quota Monitoring**: Track progress toward response targets
- ℹ️ **Simple vs Cross**: Simple quotas have one condition, Cross quotas combine multiple
- ℹ️ **Use Case**: Survey capacity planning, quota fulfillment tracking
- ⚠️ **Legacy Pagination**: Uses `offset` instead of `skipToken`
- 💡 **Future Feature**: Could add quota monitoring to dashboard for survey capacity alerts

---

### Update Survey

**Endpoint**: `PUT /surveys/{surveyId}`
**Purpose**: Update survey metadata (name, active status, expiration dates)
**Used In**: Not currently used in QualticsDashboard

#### Request

```http
PUT /surveys/{surveyId}
X-API-TOKEN: {your-api-token}
Content-Type: application/json

{
  "name": "Updated Survey Name",
  "isActive": true,
  "expiration": {
    "startDate": "2017-05-22T00:00:00Z",
    "endDate": "2017-05-24T00:00:00Z"
  }
}
```

#### Path Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `surveyId` | string | ✅ | Survey identifier (format: `SV_*`) |

#### Request Body Fields (All Optional)

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | New survey name |
| `isActive` | boolean | Set survey active/inactive |
| `expiration` | object | Survey validity date range with `startDate` and `endDate` (ISO 8601) |

#### Response (200 OK)

```json
{
  "result": {
    "id": "SV_eajskCRbMSRKkRf",
    "name": "Updated Survey Name",
    "isActive": true
  },
  "meta": {
    "httpStatus": "200 - OK",
    "requestId": "req_123456"
  }
}
```

#### Important Notes

- ℹ️ **Partial Updates**: All fields are optional - only include what you want to change
- ℹ️ **Metadata Only**: Only updates survey metadata, not design elements (use Survey Definition API for that)
- ℹ️ **Last Modified**: `lastModifiedDate` is automatically updated
- ℹ️ **Use Case**: Activate/deactivate surveys, update names, manage survey lifecycle

---

### Import Survey

**Endpoint**: `POST /surveys`
**Purpose**: Create new survey by importing from file (.qsf, .txt, .doc)
**Used In**: Not currently used in QualticsDashboard

#### Request

```http
POST /surveys
X-API-TOKEN: {your-api-token}
Content-Type: multipart/form-data

--boundary
Content-Disposition: form-data; name="file"; filename="Simple.qsf"
Content-Type: application/vnd.qualtrics.survey.qsf

[file contents]
--boundary
Content-Disposition: form-data; name="name"

New Survey Name
--boundary--
```

#### Request Body (Multipart Form)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `file` | file | ✅ | Survey file (.qsf, .txt, or .doc) |
| `name` | string | ✅ | Name for the new survey |

**Supported MIME Types**:
- `application/vnd.qualtrics.survey.qsf` - Qualtrics Survey Format (exported from UI)
- `text/plain` - Simple or Advanced Format TXT file
- `application/msword` - Word document

#### Response (200 OK)

```json
{
  "result": {
    "id": "SV_newsurveyid123",
    "name": "New Survey Name"
  },
  "meta": {
    "httpStatus": "200 - OK",
    "requestId": "req_123456"
  }
}
```

#### Important Notes

- ⚠️ **Format incompatibility**: Cannot import the JSON format returned by Get Survey API
- ⚠️ **Delay**: New survey may take several seconds to minutes to appear in dashboard
- ℹ️ **File Types**: .qsf (recommended), .txt (simple or advanced format), .doc
- ℹ️ **Use Case**: Programmatic survey creation from templates, bulk survey creation
- 💡 **Finding Survey ID**: After import, use List Surveys API or check UI to find the new survey ID

---

### Import Survey from URL

**Endpoint**: `POST /surveys`
**Purpose**: Create new survey by importing from publicly accessible URL
**Used In**: Not currently used in QualticsDashboard

#### Request

```http
POST /surveys
X-API-TOKEN: {your-api-token}
Content-Type: multipart/form-data

--boundary
Content-Disposition: form-data; name="name"

New Survey Name
--boundary
Content-Disposition: form-data; name="contentType"

application/vnd.qualtrics.survey.qsf
--boundary
Content-Disposition: form-data; name="fileUrl"

https://example.com/survey-template.qsf
--boundary--
```

#### Request Body (Multipart Form)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | ✅ | Name for the new survey |
| `contentType` | string | ✅ | MIME type of file at URL |
| `fileUrl` | string | ✅ | Publicly accessible URL to survey file |

**Supported URLs**:
- Amazon S3 public files
- Dropbox shared files
- Public Google Drive files
- Any publicly accessible survey file

#### Response (200 OK)

Same as Import Survey response.

#### Important Notes

- ⚠️ **Public Access Required**: File must be accessible to Qualtrics servers (no authentication)
- ⚠️ **Delay**: New survey may take several minutes to appear in dashboard
- ℹ️ **Use Case**: Import from cloud storage, shared templates, external survey libraries
- 💡 **Library Required (Python)**: Use `requests_toolbelt` for multipart encoding

---

### Delete Survey

**Endpoint**: `DELETE /surveys/{surveyId}`
**Purpose**: Delete a survey permanently
**Used In**: Not currently used in QualticsDashboard

#### Request

```http
DELETE /surveys/{surveyId}
X-API-TOKEN: {your-api-token}
```

#### Path Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `surveyId` | string | ✅ | Survey identifier (format: `SV_*`) |

#### Response (200 OK)

```json
{
  "meta": {
    "httpStatus": "200 - OK",
    "requestId": "bb120589-c361-4a3b-bf69-fa3aa46ca400"
  }
}
```

#### Permissions Required

User needs `deleteSurveys` privilege **AND** one of the following:
- User is the survey owner, **OR**
- User is Brand Admin and survey is in this brand, **OR**
- User is Server Admin or MBA, **OR**
- User is Division Admin and survey is in this brand, **OR**
- User is EX Admin and survey is an EX survey in this brand

#### Important Notes

- ⚠️ **Permanent**: Deletion is permanent and cannot be undone
- ⚠️ **Permissions**: Complex permission requirements (see above)
- ℹ️ **Use Case**: Survey cleanup, removing test surveys
- 💡 **Alternative**: Consider deactivating surveys instead of deleting for data retention

---

## Distribution APIs

Distributions represent email campaigns sent to survey recipients. There are three types:
- **Invites**: Initial invitation to take a survey
- **Reminders**: Reminders sent to those who haven't completed the survey
- **Thank Yous**: Thank you messages sent to respondents

### Get Distribution

**Endpoint**: `GET /distributions/{distributionId}?surveyId={surveyId}`
**Purpose**: Get complete information about a single distribution for a survey
**Used In**: `QualtricsService.GetDistributionStatsAsync()` (recommended approach)

#### Request

```http
GET /distributions/{distributionId}?surveyId={surveyId}
X-API-TOKEN: {your-api-token}
```

#### Path Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `distributionId` | string | ✅ | Distribution identifier (format: `EMD_*`) |

#### Query Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `surveyId` | string | ✅ | Survey identifier (format: `SV_*`) |

#### Response (200 OK)

```json
{
  "result": {
    "id": "EMD_Vhid09W3Z5ge89i",
    "parentDistributionId": null,
    "ownerId": "UR_cVcNH0elQesua8J",
    "organizationId": "apidocs",
    "requestStatus": "Pending",
    "requestType": "Invite",
    "sendDate": "2019-11-25T01:18:51Z",
    "createdDate": "2019-11-25T01:18:51Z",
    "modifiedDate": "2019-11-24T18:18:52Z",
    "customHeaders": {},
    "headers": {
      "fromEmail": "noreply@example.com",
      "fromName": "John Smith",
      "replyToEmail": "jsmith@example.com",
      "subject": "Survey Request"
    },
    "recipients": {
      "mailingListId": "BT_01gl1yEFWKZZ8y9",
      "contactId": null,
      "libraryId": "UR_cVcNH0elQesua8J",
      "sampleId": null
    },
    "message": {
      "libraryId": "UR_cVcNH0elQesua8J",
      "messageId": "MS_9KAQTRZOeKY9zp3",
      "messageText": null
    },
    "surveyLink": {
      "surveyId": "SV_eajskCRbMSRKkRf",
      "expirationDate": "2020-01-23T22:52:00Z",
      "linkType": "Individual"
    },
    "embeddedData": null,
    "stats": {
      "sent": 0,
      "failed": 0,
      "started": 0,
      "bounced": 0,
      "opened": 0,
      "skipped": 0,
      "finished": 0,
      "complaints": 0,
      "blocked": 0
    }
  },
  "meta": {
    "httpStatus": "200 - OK",
    "requestId": "ab324f2e-0b3e-4366-89d6-0830c6d9040d"
  }
}
```

#### Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Distribution identifier (format: `EMD_*`) |
| `parentDistributionId` | string/null | Parent distribution ID (initial invite). For invites this is null. Reminders/ThankYous reference the original invite. |
| `ownerId` | string | User ID of the distribution owner |
| `organizationId` | string | Organization or brand ID |
| `requestStatus` | string | Status: `Pending` (scheduled) or `Done` (sent) |
| `requestType` | string | Type: `Invite`, `Reminder`, `ThankYou`, `GeneratedInvite` |
| `sendDate` | string | Date/time sent or scheduled (ISO 8601 format) |
| `createdDate` | string | Date/time distribution created (ISO 8601 format) |
| `modifiedDate` | string | Date/time last modified (ISO 8601 format) |
| `headers` | object | Email headers (from/to/subject) - see below |
| `recipients` | object | Target contacts/mailing lists - see below |
| `message` | object | Email message body reference - see below |
| `surveyLink` | object | Survey link configuration - see below |
| `embeddedData` | object/null | Custom embedded data passed to survey |
| `stats` | object | ✅ **Aggregate email/survey statistics** - see below |

#### headers Object

| Field | Type | Description |
|-------|------|-------------|
| `fromEmail` | string | Sender email (default: `noreply@qemailserver.com`) |
| `fromName` | string | Sender name (typically account owner's name) |
| `replyToEmail` | string | Reply-to address for recipient replies |
| `subject` | string | Email subject line |

#### recipients Object

Describes the contacts or subset targeted by the distribution. For non-Invite types, all values may be null.

| Field | Type | Description |
|-------|------|-------------|
| `mailingListId` | string | Mailing list ID containing contacts |
| `contactId` | string/null | Single contact ID (if sent to one recipient only) |
| `libraryId` | string | Library ID containing the mailing list |
| `sampleId` | string/null | Sample ID (subset of mailing list) |

**Recipients Scenarios**:
- **Single recipient**: `contactId` and `mailingListId` are set, others null
- **Mailing list**: `libraryId` and `mailingListId` are set
- **Sample**: `sampleId` is set (sample = subset of mailing list contacts)

#### message Object

| Field | Type | Description |
|-------|------|-------------|
| `libraryId` | string | Library ID where message is saved |
| `messageId` | string | Message ID in library |
| `messageText` | string/null | Fixed message text (if used), otherwise null |

#### surveyLink Object

| Field | Type | Description |
|-------|------|-------------|
| `surveyId` | string | Survey identifier (always set) |
| `expirationDate` | string | Link expiration date (ISO 8601 format) |
| `linkType` | string | Link type: `Individual`, `Anonymous`, or `Multiple` |

**Note**: `expirationDate` and `linkType` are only set for Invite distributions.

#### stats Object ✅

**The stats object provides aggregate counts for both email delivery and survey participation.**

| Field | Type | Description |
|-------|------|-------------|
| `sent` | integer | Total emails successfully sent |
| `failed` | integer | Failed emails (improper formatting) |
| `started` | integer | Number of surveys started by recipients |
| `bounced` | integer | Emails rejected by destination mail server |
| `opened` | integer | Emails opened (tracked via web beacon image) |
| `skipped` | integer | Not delivered due to frequency limits or contact rules |
| `finished` | integer | Completed responses (including partial) |
| `complaints` | integer | Spam complaints or IP blacklist rejections |
| `blocked` | integer | Emails blocked by recipient or filters |

**Important Notes**:
- ✅ **This is the recommended approach**: Get aggregate stats directly without querying history
- **Email opened tracking**: Uses web beacon image, so may undercount if recipients disable external images
- **Finished vs Started**: `finished` includes partial responses; `started` counts all survey initiations
- **Use case**: Programmatically determine when to send reminders based on stats health

---

### List Distributions

**Endpoint**: `GET /distributions?surveyId={surveyId}`
**Purpose**: Get all distributions (email campaigns) for a survey
**Used In**: `QualtricsService.GetDistributionsForSurveyAsync()`

#### Request

```http
GET /distributions?surveyId={surveyId}
X-API-TOKEN: {your-api-token}
```

#### Query Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `surveyId` | string | ✅ | - | Survey identifier (format: `SV_*`) |

#### Response (200 OK)

```json
{
  "result": {
    "elements": [
      {
        "id": "EMD_vPSNvUyf7cevWSX",
        "parentDistributionId": null,
        "ownerId": "UR_cVcNH0elQesua8J",
        "organizationId": "testorg",
        "requestStatus": "Generated",
        "requestType": "GeneratedInvite",
        "sendDate": "2019-11-25T02:19:47Z",
        "createdDate": "2019-11-25T02:19:47Z",
        "modifiedDate": "2019-11-24T19:19:47Z",
        "customHeaders": {},
        "headers": {
          "fromEmail": null,
          "replyToEmail": null,
          "fromName": null
        },
        "recipients": {
          "mailingListId": "CG_er1pwJbK9BZuxo1",
          "contactId": null,
          "libraryId": "UR_cVcNH0elQesua8J",
          "sampleId": null
        },
        "message": {
          "libraryId": null,
          "messageId": null,
          "messageText": null
        },
        "surveyLink": {
          "surveyId": "SV_eajskCRbMSRKkRf",
          "expirationDate": "2019-12-24T07:00:00Z",
          "linkType": "Individual"
        },
        "embeddedData": null,
        "stats": {
          "sent": 0,
          "failed": 2,
          "started": 0,
          "bounced": 0,
          "opened": 0,
          "skipped": 0,
          "finished": 0,
          "complaints": 0,
          "blocked": 0
        }
      }
    ],
    "nextPage": null
  },
  "meta": {
    "httpStatus": "200 - OK",
    "requestId": "ed6656b0-a924-4a63-9534-dc75edc21ff6"
  }
}
```

#### Response Fields

**Collection Structure**:
- `elements`: Array of distribution objects (same structure as Get Distribution)
- `nextPage`: Pagination token (null if no more pages)

**Each distribution element has the same structure as Get Distribution response**, including:
- All distribution metadata fields
- `headers` object with email details
- `recipients` object with target contacts
- `message` object with email body reference
- `surveyLink` object with survey configuration
- ✅ **`stats` object with aggregate counts**

#### Important Notes

- ✅ **Stats included**: Each distribution includes aggregate stats directly
- ✅ **Overview capability**: Get distribution history overview for survey health monitoring
- ℹ️ **Use case**: Determine if survey needs attention based on participation across all distributions
- ⚠️ **Pagination**: Response includes `nextPage` for paginated results (though examples show null)

---

## Distribution History APIs

### List Distribution History

**Endpoint**: `GET /distributions/{distributionId}/history`
**Purpose**: Get contact-level email disposition data with detailed status tracking
**Used In**: `QualtricsService.GetDistributionStatsAsync()` (current implementation)

#### Request

```http
GET /distributions/{distributionId}/history?skipToken={token}
X-API-TOKEN: {your-api-token}
```

#### Path Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `distributionId` | string | ✅ | Distribution identifier (e.g., `EMD_1234567890abcde`) |

#### Query Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `skipToken` | string | ❌ | - | Pagination token for next page |

#### Response (200 OK)

```json
{
  "result": {
    "elements": [
      {
        "contactId": "CID_6SvNjhDzWKKWdCt",
        "contactLookupId": "CGC_2SvBjhAzwZK4dEx",
        "distributionId": "EMD_m3ox030by7ydblg",
        "status": "SurveyFinished",
        "surveyLink": "https://datacenter.qualtrics.com/WRQualtricsSurveyEngine?Q_DL=...",
        "contactFrequencyRuleId": "CFR_gNV8vMdKZtWbT34",
        "responseId": "R_YXIPQimT0z0A3i9",
        "responseCompletedAt": "2017-07-21T17:32:28Z",
        "sentAt": "2017-07-21T17:32:28Z",
        "openedAt": "2017-07-21T17:32:28Z",
        "responseStartedAt": "2017-07-21T17:32:28Z",
        "surveySessionId": "FS_1CwF4quYDr7AzoD"
      }
    ],
    "nextPage": "string_or_null"
  },
  "meta": {
    "httpStatus": "200",
    "requestId": "req_123456"
  }
}
```

#### Status Values

| Status | Description | Aggregate Mapping |
|--------|-------------|-------------------|
| `Pending` | Scheduled but not sent yet | - |
| `Success` | Successfully delivered | → `sent` |
| `Error` | Error during send | → `failed` |
| `Opened` | Email opened by contact | → `opened` |
| `Complaint` | Marked as spam | → `complaints` |
| `Skipped` | Skipped (frequency rules/blacklist) | → `skipped` |
| `Blocked` | Blocked by contact or spam filter | → `blocked` |
| `Failure` | Failed to deliver | → `failed` |
| `Unknown` | Failed for unknown reason | → `failed` |
| `SoftBounce` | Bounced (can retry) | → `bounced` |
| `HardBounce` | Bounced (permanent) | → `bounced` |
| `SurveyStarted` | Survey started | → `started` |
| `SurveyPartiallyFinished` | Partial response submitted | → `started` |
| `SurveyFinished` | Completed response submitted | → `finished` |
| `SurveyScreenedOut` | Screened out during survey | → `started` |
| `SessionExpired` | Survey session expired | - |

#### Timestamp Fields

| Field | Type | Description |
|-------|------|-------------|
| `sentAt` | datetime | When email was sent |
| `openedAt` | datetime | When email was opened (null if not opened) |
| `responseStartedAt` | datetime | When survey was started (null if not started) |
| `responseCompletedAt` | datetime | When survey was completed (null if not completed) |

#### Important Notes

- ⚠️ **XM Directory Only**: Not supported for Genesis Contacts
- ℹ️ **Contact-Level Detail**: One entry per contact in the distribution
- ℹ️ **Pagination Required**: Large distributions may have thousands of contacts
- ✅ **Rich Status Tracking**: 17 different status values for detailed analytics
- ⚠️ **Aggregation Needed**: Must count statuses yourself to get aggregate stats

---

### List Distribution Links

**Endpoint**: `GET /distributions/{distributionId}/links?surveyId={surveyId}`
**Purpose**: Get individual survey links for each contact
**Used In**: Not currently used in QualticsDashboard

#### Important Notes

- ⚠️ **Email Status Issue**: Always returns "Email not sent" - not useful for tracking
- ⚠️ **Better Alternative**: Use Distribution History API instead
- ⚠️ **XM Directory Only**: Not supported for Genesis Contacts
- ℹ️ **Use Case**: Retrieving links generated via Create Distribution API

---

## Mailing List APIs

### List Mailing Lists

**Endpoint**: `GET /directories/{directoryId}/mailinglists`
**Purpose**: Get all mailing lists (contact lists) in an XM Directory
**Used In**: `QualtricsService.GetMailingListsAsync()`

#### Request

```http
GET /directories/{directoryId}/mailinglists?pageSize=100&skipToken={token}
X-API-TOKEN: {your-api-token}
```

#### Path Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `directoryId` | string | ✅ | Directory ID (also called Pool ID, e.g., `POOL_012345678901234`) |

#### Query Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `pageSize` | integer | ❌ | 100 | Max items per page |
| `skipToken` | string | ❌ | - | Pagination token |
| `ownerId` | string | ❌ | - | Filter by owner (user or group ID like `GR_FJDKAXL`) |
| `includeCount` | boolean | ❌ | - | Include contact count (may impact performance) |
| `useNewPaginationScheme` | boolean | ❌ | false | Enable improved pagination |

#### Response (200 OK)

```json
{
  "result": {
    "elements": [
      {
        "contactCount": 1500,
        "mailingListId": "CG_012345678901234",
        "name": "Customer Email List",
        "lastModifiedDate": "1597321249000",
        "creationDate": "1597321249000",
        "ownerId": "GR_FJDKAXL"
      }
    ],
    "nextPage": "string_or_null"
  },
  "meta": {
    "httpStatus": "200",
    "requestId": "req_123456"
  }
}
```

#### Important Notes

- ⚠️ **XM Directory Only**: Not available for Genesis Contacts
- ⚠️ **Approximate Count**: `contactCount` is approximate - use List Contacts API for exact count
- ℹ️ **Shared Lists**: Set `ownerId` to a group ID to query shared mailing lists
- ⚠️ **Performance**: Including contact count may decrease performance for large lists

---

### Get Mailing List

**Endpoint**: `GET /directories/{directoryId}/mailinglists/{mailingListId}`
**Purpose**: Get details of a specific mailing list
**Used In**: Not currently used in QualticsDashboard

#### Request

```http
GET /directories/{directoryId}/mailinglists/{mailingListId}?includeCount=true
X-API-TOKEN: {your-api-token}
```

#### Path Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `directoryId` | string | ✅ | Directory ID (Pool ID) |
| `mailingListId` | string | ✅ | Mailing List ID (e.g., `CG_012345678901234`) |

#### Query Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `includeCount` | boolean | ❌ | Include contact count (may impact performance) |

#### Response (200 OK)

Same structure as individual mailing list element in List Mailing Lists.

#### Important Notes

- ⚠️ **XM Directory Only**: Not available for Genesis Contacts
- ⚠️ **Performance**: Including contact count may decrease performance for large lists

---

## Directory APIs

### List Directories

**Endpoint**: `GET /directories`
**Purpose**: Get all XM directories (contact pools) for the brand with summary information
**Used In**: `QualtricsService.GetDirectoriesAsync()` - Required for fetching mailing lists

#### Request

```http
GET /directories?includeCount=true
X-API-TOKEN: {your-api-token}
```

#### Query Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `includeCount` | boolean | ❌ | false | Include contact count (may impact performance) |

#### Response (200 OK)

```json
{
  "result": {
    "elements": [
      {
        "directoryId": "POOL_012345678901234",
        "name": "Customer Contacts",
        "contactCount": 0,
        "isDefault": true,
        "deduplicationCriteria": {
          "email": true,
          "firstName": true,
          "lastName": true,
          "externalDataReference": true,
          "phone": true
        }
      }
    ],
    "nextPage": "string_or_null"
  },
  "meta": {
    "requestId": "req_123456",
    "httpStatus": "200",
    "notice": "Optional informational message"
  }
}
```

#### Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `directoryId` | string | Directory ID (also called Pool ID, format: `POOL_*`) |
| `name` | string | Directory display name |
| `contactCount` | integer | Total contacts (only if `includeCount=true`) |
| `isDefault` | boolean | Whether this is the default directory for the brand |
| `deduplicationCriteria` | object | Fields used to identify duplicate contacts |
| `nextPage` | string/null | Pagination token (if more results exist) |

#### Important Notes

- ℹ️ **Default Directory**: Most brands have one directory marked `isDefault: true`
- ℹ️ **Required for Mailing Lists**: Must get directory ID before calling `/directories/{directoryId}/mailinglists`
- ⚠️ **Performance**: Setting `includeCount=true` may slow response for large directories
- ℹ️ **Deduplication**: Criteria determines which fields must match to consider contacts duplicates
- ℹ️ **Pool ID**: DirectoryId and Pool ID are synonymous terms in Qualtrics

#### Rate Limits

- **Estimated**: 3000 requests per minute (standard endpoint rate)
- Always implement 429 handling with Retry-After header

#### OAuth Scopes

- `read:directories` - Required for listing directories

#### Implementation Example

```csharp
public async Task<List<ContactDirectory>> GetDirectoriesAsync(CancellationToken cancellationToken = default)
{
    var response = await _httpClient.GetAsync("directories", cancellationToken);

    if (!response.IsSuccessStatusCode)
    {
        if (response.StatusCode == HttpStatusCode.TooManyRequests)
        {
            var retryAfter = response.Headers.RetryAfter?.Delta ?? TimeSpan.FromSeconds(60);
            _logger.LogWarning("Rate limit exceeded. Retry after {Seconds}s", retryAfter.TotalSeconds);
        }
        throw new QualtricsTransientException($"Failed to fetch directories: {response.StatusCode}");
    }

    var apiResponse = await response.Content.ReadFromJsonAsync<QualtricsApiResponse<QualtricsApiDirectoryList>>();

    return apiResponse.Result.Elements.Select(d => new ContactDirectory
    {
        Id = d.Id,
        Name = d.Name,
        IsDefault = d.IsDefault,
        ContactCount = d.Stats?.TotalContacts ?? 0
    }).ToList();
}
```

#### Usage Pattern

**Typical workflow for fetching mailing lists**:
```csharp
// Step 1: Get directories to find the default directory
var directories = await GetDirectoriesAsync();
var defaultDirectory = directories.FirstOrDefault(d => d.IsDefault)
    ?? directories.FirstOrDefault();

// Step 2: Use directory ID to fetch mailing lists
var mailingLists = await _httpClient.GetAsync(
    $"directories/{Uri.EscapeDataString(defaultDirectory.Id)}/mailinglists");
```

---

## Common Patterns

### Authentication

All API requests require authentication using either **X-API-TOKEN** (simpler but less secure) or **OAuth 2.0** (recommended for production).

#### X-API-TOKEN (Development/Testing)

```http
X-API-TOKEN: your-qualtrics-api-token-here
```

**Getting Your API Token**:
1. Log into Qualtrics using your Brand ID's login page
2. Navigate to Account Settings → Qualtrics IDs
3. Find the API section
4. Copy existing token OR click "Generate Token"

⚠️ **CRITICAL WARNINGS**:
- **"Generate Token" replaces existing token**: Your old token will be invalidated immediately, breaking any code using it
- **Keep it safe**: API Token is the "Key to the Throne" - anyone with it can manipulate your Qualtrics account
- **Never share in clear text**: Don't commit to source control, share in Slack, or email
- **Rotate regularly**: Recommended once per year minimum (but causes downtime with X-API-TOKEN)
- **NOT for production**: Less secure than OAuth 2.0 and harder to maintain

**Token Management Best Practices**:
- Store securely (Azure Key Vault, AWS Secrets Manager, environment variables)
- Use different tokens for dev/staging/production environments
- Document token rotation procedures
- Monitor token usage for suspicious activity

#### OAuth 2.0 (Production - Recommended)

OAuth 2.0 provides:
- ✅ Automatic token expiry (better security)
- ✅ Granular permission control
- ✅ No downtime during key rotation
- ✅ Better multi-user API access management
- ✅ Audit trails for who did what

**Migration**: Follow [OAuth 2.0 guide](https://api.qualtrics.com/ZG9jOjg3NzY3MA-o-auth-2-0) for seamless transition without downtime.

---

### Pagination

Qualtrics supports **two pagination schemes** depending on the underlying data structure.

#### Token-Based Pagination (Recommended)

Used when underlying data uses unique IDs. Provides better performance.

```http
GET /distributions?surveyId={id}&pageSize=100&skipToken={token}
```

**Parameters**:
- `skipToken`: ID of last item from previous page (omit for first page)
- `pageSize`: Items per page (recommended ≤ 100, max usually 500)

**Response**:
```json
{
  "result": {
    "elements": [...],
    "nextPage": "string_or_null"
  }
}
```

**Best Practices**:
- ✅ Always use the `nextPage` URL from response if provided (avoids breaking changes)
- ✅ Check if `nextPage` is `null` to detect last page
- ⚠️ Don't assume total page count - always iterate until `nextPage` is `null`

**Pagination Loop Pattern**:

```csharp
var allResults = new List<T>();
string? nextPageUrl = initialUrl;

do
{
    var response = await httpClient.GetAsync(nextPageUrl);
    var apiResponse = await response.Content.ReadFromJsonAsync<ApiResponse>();

    allResults.AddRange(apiResponse.Result.Elements);

    // Use the nextPage URL directly from response
    nextPageUrl = apiResponse.Result.NextPage;

} while (!string.IsNullOrWhiteSpace(nextPageUrl));
```

**Pseudo Code**:
```
GET results from API
ProcessResults()
while (nextPage != null){
    GET results from nextPage URL
    ProcessResults()
}
```

#### Numerical ID-Based Pagination (Legacy)

Used when underlying data has numeric sequential IDs.

```http
GET /surveys?offset=0&pageSize=100
```

**Parameters**:
- `offset`: Page number to retrieve (starting at 0)
- `pageSize`: Items per page (recommended ≤ 100, max usually 500)

**Response**:
```json
{
  "links": {
    "prev": {
      "href": "<REST URL TO PREVIOUS PAGE>"
    },
    "next": {
      "href": "<REST URL TO NEXT PAGE>"
    }
  },
  "result": {...}
}
```

**Best Practice**: ✅ Always use the URL from `links.next.href` field to avoid breaking changes if pagination schemes change.

---

### Idempotent Requests

Some endpoints enforce **idempotency** for safe request retries without duplicate operations.

**Use Case**: If a request fails due to network error, retry with the same idempotency key to guarantee operation happens only once.

**Example**: Adjusting incentive points for a contact - network failure during request could cause duplicate points if not idempotent.

**Behavior**: Qualtrics returns the same response for requests made with the same idempotency key.

**Implementation**: Check specific endpoint documentation for idempotency key header requirements.

---

### Date and Time Format

Qualtrics APIs use date and time values following the **ISO 8601 standard**. Some older endpoints feature **Unix time** instead.

#### ISO 8601 Date and Time Format

**Standard Format**: `YYYY-MM-DDThh:mm:ssZ` or `YYYY-MM-DDThh:mm:ss±HH:mm`

**Components**:
- `YYYY-MM-DD`: Year-Month-Day (e.g., `2019-03-21`)
- `T`: Separator between date and time
- `hh:mm:ss`: Hour (00-23 military time), minutes, seconds
- Optional: `.SSS` for milliseconds
- `Z`: UTC timezone
- `±HH:mm`: Timezone offset from UTC (alternative to Z)

**Examples**:
```
2019-03-21T10:16:12Z000       → March 21, 2019 at 10:16:12 AM and 0 milliseconds UTC
2016-04-01T07:31:43Z          → April 1, 2016 at 7:31:43 AM UTC
2017-02-07T14:02:11-08:00     → February 7, 2017 at 2:02:11 PM PST (UTC-8)
2025-11-04T18:15:00+00:00     → November 4, 2025 at 6:15 PM UTC
```

⚠️ **Milliseconds Warning**: Some APIs will **reject** date times with milliseconds. You may need to strip milliseconds before sending requests if you encounter errors.

**Default Behavior**: All API responses return dates in **UTC** unless endpoint supports local time parameter.

**Local Time Support**: Some endpoints (e.g., Create Response Export) support `localTime=true` parameter to return times in the timezone configured in Qualtrics admin settings.

#### Unix Time Format

Unix time tracks time as a **running total of seconds** since the Unix Epoch (January 1, 1970 at UTC).

**Format**: Integer representing seconds since epoch

**Examples**:
```
1553163372   → March 21, 2019 at 10:16:12 AM UTC
1459495903   → April 1, 2016 at 7:31:43 AM UTC
1486504931   → February 7, 2017 at 10:02:11 PM UTC
```

**Use Cases**: Older endpoints, timestamps in comment objects (see Get Survey comments)

**Conversion Tips**:
- From Unix to DateTime: Add seconds to Unix epoch (1970-01-01 00:00:00 UTC)
- From DateTime to Unix: Calculate seconds between date and Unix epoch
- Most programming languages have built-in Unix time converters

#### Time Zones

Some API calls accept a `timeZone` argument using these standard Time Zone IDs:

| Region | Time Zone ID |
|--------|--------------|
| **Pacific** | `Pacific/Midway`, `Pacific/Honolulu`, `Pacific/Auckland`, `Pacific/Fiji`, `Pacific/Tongatapu` |
| **Americas - West** | `America/Anchorage`, `America/Los_Angeles`, `America/Phoenix`, `America/Denver` |
| **Americas - Central** | `America/Chicago`, `America/Rio_Branco`, `Canada/East-Saskatchewan` |
| **Americas - East** | `America/New_York`, `Canada/Atlantic`, `Canada/Newfoundland` |
| **Americas - South** | `America/La_Paz`, `America/Montevideo`, `America/Argentina/Buenos_Aires`, `America/Noronha` |
| **Atlantic** | `Atlantic/Azores`, `Atlantic/Cape_Verde`, `Atlantic/Reykjavik` |
| **Europe** | `Europe/London`, `Europe/Berlin`, `Europe/Athens`, `Europe/Moscow` |
| **Africa** | `Africa/Bangui`, `Africa/Harare`, `Africa/Nairobi` |
| **Middle East** | `Asia/Tehran`, `Asia/Muscat`, `Asia/Baku`, `Asia/Kabul` |
| **Asia - West** | `Asia/Yekaterinburg`, `Asia/Karachi`, `Asia/Calcutta`, `Asia/Katmandu` |
| **Asia - Central** | `Asia/Dhaka`, `Asia/Novosibirsk`, `Asia/Rangoon` |
| **Asia - East** | `Asia/Krasnoyk`, `Asia/Yakutsk`, `Asia/Seoul`, `Asia/Bangkorwin` |
| **Australia** | `Australia/Daarsk`, `Australia/Adelaide`, `Australia/Brisbane`, `Australia/Canberra` |
| **Asia/Pacific** | `Asia/Magadan` |

**Usage**: Specify when creating reports, exporting responses, or scheduling distributions to ensure times are interpreted in the correct timezone.

#### Programming Best Practices

**Parsing & Storage**:
- ✅ Always parse as UTC first, then convert to local timezone if needed
- ✅ Store dates in UTC in databases (prevents daylight saving issues)
- ✅ Use timezone-aware datetime objects in your code
- ⚠️ Strip milliseconds if API rejects them (e.g., `.TrimEnd('0').TrimEnd('.')`)

**Display**:
- ✅ Display dates in user's local timezone in UI
- ✅ Always show timezone indicator (e.g., "EST", "PST", "UTC")
- ✅ Use consistent date format across application

**Validation**:
- ✅ Validate timezone IDs against allowed list before API calls
- ✅ Handle timezone conversion errors gracefully
- ✅ Test with different timezones (especially around DST transitions)

---

### JSON Object Order

⚠️ **Important**: According to [json.org](https://json.org): *"An object is an unordered set of name/value pairs."*

**What This Means**:
- JSON objects are **by definition unordered**
- Attribute ordering is **not guaranteed** to be stable
- Changes to JSON object ordering are **NOT breaking changes**
- **Don't rely on field order** in your parsing code

**Best Practice**: Access JSON fields by name, not by position.

---

### Data Center Routing

API calls must be made to the correct data center where your credentials were created.

#### Wrong Data Center Error (OAuth)

```json
{
  "meta": {
    "httpStatus": "401 - Unauthorized",
    "error": {
      "errorMessage": "Unrecognized X-API-TOKEN.",
      "errorCode": "DCD_7"
    },
    "requestId": ""
  }
}
```

#### Proxied Request Warning (X-API-TOKEN)

If using X-API-TOKEN and calling wrong data center, request may be **proxied** (significantly slower):

```json
{
  "result": {},
  "meta": {
    "httpStatus": "200 - OK",
    "requestId": "b698813c-bde1-4734-85e6-931b2db3e83a",
    "notice": "Request proxied. For faster response times, use this host instead: yourdatacenterid.qualtrics.com"
  }
}
```

**Best Practices**:
- ✅ Store data center ID with credentials (e.g., `yourdatacenterid.qualtrics.com`)
- ✅ Use correct data center from the start to avoid performance issues
- ⚠️ OAuth credentials MUST match data center (no proxying available)
- ⚠️ Watch for `notice` field in responses indicating proxying

**Finding Your Data Center**:
1. Check your Qualtrics URL (e.g., `https://yourdatacenterid.qualtrics.com`)
2. Account Settings → Qualtrics IDs → Data Center ID

---

### Breaking Changes

Qualtrics occasionally removes capabilities to support new scenarios. A **"Breaking Change"** requires you to update your application to avoid disruption.

**Definition**: A change that may require code modifications to maintain integration.

**Resources**:
- [Qualtrics API Evolution Philosophy](https://api.qualtrics.com/docs/api-evolution): Learn how Qualtrics handles breaking vs non-breaking changes
- Check API changelog regularly for deprecation notices
- Test in development environment before production updates

**Best Practices**:
- ✅ Use versioned endpoints when available
- ✅ Handle new optional fields gracefully
- ✅ Don't rely on undocumented API behavior
- ✅ Monitor Qualtrics API announcements
- ✅ Implement graceful degradation for removed features

```
2017-07-21T17:32:28Z
```

**Important**:
- Always use UTC times
- Include the `Z` suffix to indicate UTC
- For date ranges, use `sendStartDate` and `sendEndDate` query parameters

---

### API Response Structure

All API responses contain a JSON object with two fields: `result` and `meta`.

#### Standard Response Format

```json
{
  "result": {
    "...": "API-specific data"
  },
  "meta": {
    "httpStatus": "200 - OK",
    "requestId": "74768340-3902-4f6d-9327-f5fdc2cdb9ec"
  }
}
```

#### Response Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `result` | object | ❌ | Contains returned data (omitted if no results) |
| `meta` | object | ✅ | Contains status, requestId, and error information |

**meta Object**:
- `httpStatus`: HTTP status code with description (e.g., "200 - OK")
- `requestId`: Unique identifier for this API call
- `error`: Error details (present only on failures)
- `notice`: Optional informational messages (e.g., proxying warnings)

#### Pagination Defaults

Most paginated responses return **100 items by default** under the `result` field. Some APIs allow overriding the page size.

**Best Practices**:
- ✅ **Always log `requestId` and timestamp** for debugging and support
- ✅ `requestId` + time uniquely identifies calls (invaluable for support tickets)
- ✅ Check for `notice` field for important API changes or warnings
- ⚠️ `httpStatus` string may differ from HTTP response code

---

### Error Handling

#### HTTP Status Codes

Qualtrics API uses a subset of HTTP status codes:

| Code | Status | Description | Action |
|------|--------|-------------|--------|
| **2xx Success** |
| `200` | OK | Request succeeded | Process response normally |
| `202` | Accepted | Resource upload accepted | Check status endpoint if provided |
| `207` | Multi-Response | Multiple operations with mixed results | Check individual operation statuses in response |
| **4xx Client Errors** |
| `400` | Bad Request | Invalid request (malformed parameters) | Check request body, validate parameters |
| `401` | Unauthorized | Authentication failed | Verify API token, check datacenter |
| `403` | Forbidden | Valid request but unauthorized | Check user permissions for operation |
| `404` | Not Found | Resource not found | Verify resource ID, check if deleted |
| `409` | Conflict | Request conflicts with current state | Check resource state, resolve conflicts |
| `413` | Entity Too Large | Request body too large or malformed multipart | Reduce payload size, check multipart format |
| `414` | URI Too Long | URI exceeds server limits | Shorten URI, move params to body |
| `415` | Unsupported Media Type | Invalid Content-Type or Accept header | Check headers, use `application/json` |
| `429` | Too Many Requests | Rate limit exceeded | Implement retry with exponential backoff |
| **5xx Server Errors** |
| `500` | Internal Server Error | Qualtrics internal error | Contact support with requestId and errorCode |
| `503` | Temporary Server Error | Temporary outage | Retry with exponential backoff |
| `504` | Gateway Timeout | Request took too long to process | Retry read operations; check write completion before retry |

#### Error Response Format

```json
{
  "meta": {
    "httpStatus": "400 - Bad Request",
    "error": {
      "errorMessage": "Invalid survey ID format",
      "errorCode": "INVALID_SURVEY_ID"
    },
    "requestId": "ab324f2e-0b3e-4366-89d6-0830c6d9040d"
  }
}
```

#### Rate Limiting (429 Responses)

Qualtrics enforces **two-tier rate limiting** to ensure service health and stability:

##### Tier 1: Total Brand Limit
**3,000 API requests per minute** across all endpoints for your brand.

##### Tier 2: Endpoint-Specific Limits
Certain endpoints have **lower per-brand limits** (below 3,000 RPM). You may hit an endpoint limit but still make successful calls to other endpoints until reaching the brand limit.

**Example Scenario**:
- Your brand makes 2,500 requests/minute total (under brand limit ✅)
- But 500 requests/minute go to `/distributions/{id}/history` (limit: 300 RPM ❌)
- Result: History endpoint returns 429, but other endpoints still work

##### Key Endpoint Limits for QualticsDashboard

| Endpoint | Method | Limit (RPM) | Usage |
|----------|--------|-------------|-------|
| `/surveys` | GET | 3000 | List surveys |
| `/surveys/{surveyId}` | GET | 3000 | Get survey |
| `/surveys/{surveyId}/quotas` | GET | 3000 | Get quotas |
| `/distributions` | GET | 3000 | List distributions |
| `/distributions` | POST | 3000 | Create distribution |
| `/distributions/{distributionId}` | GET | 3000 | **Get distribution (recommended)** |
| `/distributions/{distributionId}/history` | GET | **300** | ⚠️ **Low limit - history** |
| `/distributions/{distributionId}/links` | GET | 500 | List links |
| `/directories/{directoryId}/mailinglists` | GET | 3000 | List mailing lists |
| `/directories/{directoryId}/mailinglists/{mailingListId}` | GET | 3000 | Get mailing list |
| `/surveys/{surveyId}/export-responses` | POST | 100 | Export responses |
| `/surveys/{surveyId}/export-responses/{exportProgressId}` | GET | 1000 | Check export status |

**Critical Note**: `/distributions/{distributionId}/history` has only **300 requests/minute** - another reason to use the simpler `/distributions/{distributionId}` endpoint with stats object (3000 RPM limit).

##### Complete Rate Limit Reference

<details>
<summary><strong>View All Endpoint Limits</strong> (100+ endpoints)</summary>

**Distribution Endpoints**:
- `GET /distributions` - 3000 RPM
- `POST /distributions` - 3000 RPM
- `GET /distributions/{distributionId}` - 3000 RPM
- `DELETE /distributions/{distributionId}` - 3000 RPM
- `POST /distributions/{distributionId}/reminders` - 3000 RPM
- `POST /distributions/{distributionId}/thankyous` - 3000 RPM
- `GET /distributions/{distributionId}/links` - 500 RPM
- `GET /distributions/{distributionId}/history` - **300 RPM** ⚠️

**Survey Endpoints**:
- `GET /surveys` - 3000 RPM
- `POST /surveys` - 3000 RPM
- `GET /surveys/{surveyId}` - 3000 RPM
- `PUT /surveys/{surveyId}` - 3000 RPM
- `DELETE /surveys/{surveyId}` - 3000 RPM
- `GET /surveys/{surveyId}/quotas` - 3000 RPM

**Survey Definition Endpoints** (all 3000 RPM):
- All `/survey-definitions/*` endpoints

**Response Export Endpoints**:
- `POST /surveys/{surveyId}/export-responses` - **100 RPM** ⚠️
- `GET /surveys/{surveyId}/export-responses/{exportProgressId}` - 1000 RPM
- `GET /surveys/{surveyId}/export-responses/{fileId}/file` - **100 RPM** ⚠️

**Contact/Directory Endpoints** (most 3000 RPM, writes 500 RPM):
- `GET /directories/{directoryId}/contacts` - 3000 RPM
- `POST /directories/{directoryId}/contacts` - 500 RPM
- `GET /directories/{directoryId}/mailinglists` - 3000 RPM
- `POST /directories/{directoryId}/mailinglists` - 500 RPM

**Low-Limit Endpoints** ⚠️:
- Organizations: `GET /organizations/{organizationId}` - **5 RPM**
- Audit Exports: All endpoints - **30 RPM**
- Segments: Most endpoints - **60 RPM**
- EX APIs: All participant endpoints - **75 RPM**
- Event Subscriptions: All endpoints - **120 RPM**
- Response Operations: Single response ops - **60-240 RPM**

</details>

##### Rate Limit Response

When you receive a `429 Too Many Requests` response:

**Response Headers**:
- `Retry-After`: Seconds to wait before retrying (always check this header)

**Response Body**:
```json
{
  "meta": {
    "httpStatus": "429 - Too Many Requests",
    "error": {
      "errorMessage": "Rate limit exceeded",
      "errorCode": "RATE_LIMIT_EXCEEDED"
    },
    "requestId": "req_123456"
  }
}
```

##### Retry Strategy

**Step-by-Step**:
1. Read the `Retry-After` header value
2. Wait for the specified duration
3. Retry the request
4. Implement exponential backoff for repeated 429s

**Example Implementation**:

```csharp
public async Task<HttpResponseMessage> SendRequestWithRetry(HttpRequestMessage request, int maxRetries = 3)
{
    int retryCount = 0;

    while (retryCount <= maxRetries)
    {
        var response = await httpClient.SendAsync(request);

        if (response.StatusCode != HttpStatusCode.TooManyRequests)
        {
            return response; // Success or non-rate-limit error
        }

        if (retryCount == maxRetries)
        {
            _logger.LogError("Max retries reached for rate limit");
            return response; // Give up
        }

        // Calculate delay: use Retry-After header or exponential backoff
        var retryAfter = response.Headers.RetryAfter?.Delta
            ?? TimeSpan.FromSeconds(Math.Pow(2, retryCount)); // 1s, 2s, 4s

        _logger.LogWarning(
            "Rate limited (attempt {Attempt}/{Max}). Retrying after {Seconds}s",
            retryCount + 1, maxRetries, retryAfter.TotalSeconds);

        await Task.Delay(retryAfter);
        retryCount++;
    }

    return await httpClient.SendAsync(request);
}
```

##### Rate Limiting Best Practices

**Prevention**:
- ✅ Track request counts per endpoint in your application
- ✅ Implement request queuing for high-volume operations
- ✅ Use batch operations where available
- ✅ Cache responses when appropriate (surveys, quotas, etc.)
- ✅ Spread requests over time (avoid bursts)
- ⚠️ Be aware of endpoint-specific limits (not just 3000 RPM)

**Retry Strategy**:
- ✅ Always respect `Retry-After` header (mandatory)
- ✅ Implement exponential backoff (e.g., 1s, 2s, 4s, 8s)
- ✅ Set maximum retry attempts (e.g., 3-5 retries)
- ✅ Add jitter to backoff (randomize slightly to avoid thundering herd)
- ✅ Log rate limit events for monitoring and alerting

**Monitoring**:
- ✅ Track 429 response rates
- ✅ Alert on sustained rate limiting
- ✅ Monitor per-endpoint usage patterns
- ✅ Identify bottleneck endpoints (especially low-limit ones)

**Architecture**:
- ✅ Use message queues for high-volume operations
- ✅ Implement circuit breakers for failing endpoints
- ✅ Consider background processing for non-urgent operations
- ✅ Use webhooks/subscriptions instead of polling where available

**Cost Optimization**:
- ⚠️ Avoid polling `/distributions/{id}/history` (300 RPM limit)
- ✅ Use `/distributions/{id}` with stats object instead (3000 RPM limit, 10x higher!)
- ✅ Cache mailing lists, surveys, quotas (rarely change)

##### Additional API Limits

**Call Duration**:
- Default timeout: **5 seconds** (most endpoints)
- Some endpoints may have longer timeouts (noted in endpoint docs)

**Survey Response Limits**:
- Maximum records per export file: **1,000,000 rows**
- Additional data files created if exceeded: `{surveyname}_{filenum}.{fileExtension}`

**File Upload Limits**:
- Maximum file size: **5 MB** (unless endpoint specifies otherwise)

**Mailing List Limits**:
- Mailing list names: **100 characters maximum**

**Best Practices for Limits**:
- ✅ Handle multi-file exports gracefully (check for additional files)
- ✅ Validate file sizes before upload
- ✅ Truncate mailing list names if needed
- ✅ Implement timeout handling (don't wait forever)

#### Server Error Handling (5xx)

**500 Internal Server Error**:
- Usually cannot be corrected by user
- Contact Qualtrics Support with `requestId` and `errorCode`
- Don't retry automatically (problem is server-side)

**503 Temporary Server Error**:
- Temporary outage
- Safe to retry with exponential backoff
- If problems persist, contact support

**504 Gateway Timeout**:
- Service took too long to process
- **Read operations**: Safe to retry
- **Write operations**: Check if write completed before retrying (avoid duplicates)

#### Error Handling Best Practices

**Logging**:
```csharp
_logger.LogError(
    "Qualtrics API error: {HttpStatus} | RequestId: {RequestId} | Error: {ErrorMessage} | Code: {ErrorCode}",
    meta.HttpStatus,
    meta.RequestId,
    meta.Error?.ErrorMessage,
    meta.Error?.ErrorCode
);
```

**Retry Logic**:
- ✅ Retry on: 429, 503, 504, network errors
- ❌ Don't retry on: 400, 401, 403, 404, 409, 500
- ✅ Use exponential backoff with jitter
- ✅ Set max retries (3-5 attempts)

**User Feedback**:
- Show user-friendly messages (don't expose technical details)
- For 500 errors, provide support contact info with `requestId`
- For rate limits, explain retry is happening automatically

---

### Response Metadata

All responses include a `meta` object with critical debugging information:

```json
{
  "result": { ... },
  "meta": {
    "httpStatus": "200 - OK",
    "requestId": "74768340-3902-4f6d-9327-f5fdc2cdb9ec",
    "notice": "Request proxied. For faster response times, use this host instead: datacenter.qualtrics.com"
  }
}
```

**Critical Fields**:
- `requestId`: Unique call identifier (required for support tickets)
- `httpStatus`: Status description (may include additional context)
- `notice`: Important informational messages (proxying, deprecations, etc.)

**Best Practices**:
- ✅ **Always log `requestId` + timestamp** (invaluable for support)
- ✅ Check `notice` field and log warnings
- ✅ Use `httpStatus` for user-facing messages
- ✅ Store `requestId` with transaction records for audit trails

---

### Language Codes

Qualtrics supports 80+ languages natively. APIs accept any language code, but contacts will only receive messages in the correct language if the code matches one from the list below or a customer-created language code.

**Usage**: Language codes are used for:
- Survey translations and localization
- Email distribution messages in multiple languages
- Contact language preferences
- Multi-language survey design

#### Supported Language Codes

| Code | English Name | Local Name |
|------|--------------|------------|
| `SQI` | Albanian | Shqip |
| `AR` | Arabic | العربية |
| `HYE` | Armenian (Eastern) | արևելահայերեն |
| `ASM` | Assamese | অসমীয়া |
| `AZ-AZ` | Azeri/Azerbaijani (Latin) | Azərbaycan dili |
| `ID` | Bahasa Indonesia | Bahasa Indonesia |
| `MS` | Bahasa Malaysia | Bahasa Melayu |
| `BEL` | Belarusian | Беларуская |
| `BN` | Bengali | বাঙালি |
| `BS` | Bosnian | bosanski |
| `PT-BR` | Brazilian Portuguese | Português Brasileiro |
| `BG` | Bulgarian | Български |
| `CA` | Catalan | català |
| `CEB` | Cebuano | Bisaya |
| `ZH-S` | Chinese (Simplified) | 简体中文 |
| `ZH-T` | Chinese (Traditional) | 繁體中文 |
| `HR` | Croatian | Hrvatski |
| `CS` | Czech | Čeština |
| `DA` | Danish | Dansk |
| `NL` | Dutch | Nederlands |
| `EN-GB` | English - UK | English - United Kingdom |
| `EN` | English - US | English |
| `EO` | Esperanto | Esperanto |
| `ET` | Estonian | Eesti |
| `FI` | Finnish | Suomi |
| `FR` | French | Français |
| `FR-CA` | French (Canada) | Français (Canada) |
| `KAT` | Georgian | ქართული |
| `DE` | German | Deutsch |
| `EL` | Greek | Ελληνικά |
| `GU` | Gujarati | ગુજરાતી |
| `HE` | Hebrew | עברית |
| `HI` | Hindi | हिन्दी |
| `HU` | Hungarian | Magyar |
| `ISL` | Icelandic | Íslenska |
| `HIL` | Ilonggo/Hiligaynon | Hiligaynon |
| `IT` | Italian | Italiano |
| `JA` | Japanese | 日本語 |
| `CKB` | Kurdish (Sorani) | Kurdî |
| `KAN` | Kannada | ಕನ್ನಡ |
| `KAZ` | Kazakh (Cyrillic) | Қазақ |
| `KM` | Khmer | ភាសាខ្មែរ |
| `KO` | Korean | 한국어 |
| `LV` | Latvian | Latviešu |
| `LT` | Lithuanian | Lietuviškai |
| `MK` | Macedonian | Mакедонски |
| `MAL` | Malayalam | മലയാളം |
| `MAR` | Marathi | मराठी |
| `MN` | Mongolian | Монгол |
| `SR-ME` | Montenegrin | Crnogorski |
| `MY` | Myanmar/Burmese | မြန်မာဘာသာ |
| `NO` | Norwegian | Norsk |
| `ORI` | Odia/Oriya | ଓଡ଼ିଆ ଭାଷା |
| `FA` | Persian | فارسی |
| `PL` | Polish | Polski |
| `PT` | Portuguese | Português |
| `PA-IN` | Punjabi | ਪੰਜਾਬੀ (ਗੁਰਮੁਖੀ) |
| `RO` | Romanian | Română |
| `RU` | Russian | Pyccĸий |
| `SR` | Serbian | Српски |
| `SIN` | Sinhalese | සිංහල |
| `SK` | Slovak | Slovenčina |
| `SL` | Slovenian | Slovenščina |
| `ES-ES` | European Spanish | Español |
| `ES` | Latin American Spanish | Español |
| `SW` | Swahili | Kiswahili |
| `SV` | Swedish | Svenska |
| `TGL` | Tagalog | Tagalog |
| `TA` | Tamil | தமிழ் |
| `TEL` | Telugu | తెలుగు |
| `TH` | Thai | ภาษาไทย |
| `TR` | Turkish | Tϋrkçe |
| `UK` | Ukrainian | Українська |
| `UR` | Urdu | اردو |
| `VI` | Vietnamese | tiếng Việt |
| `CY` | Welsh | Cymraeg |

#### Regional Variants

Some languages have regional variants with different codes:

| Language | Variants | Codes |
|----------|----------|-------|
| **English** | US, UK | `EN`, `EN-GB` |
| **Spanish** | Latin American, European | `ES`, `ES-ES` |
| **Portuguese** | Brazilian, European | `PT-BR`, `PT` |
| **French** | Standard, Canadian | `FR`, `FR-CA` |
| **Chinese** | Simplified, Traditional | `ZH-S`, `ZH-T` |
| **Azeri** | Latin script | `AZ-AZ` |
| **Punjabi** | Gurmukhi script | `PA-IN` |
| **Serbian** | Standard, Montenegrin | `SR`, `SR-ME` |

#### Language Code Best Practices

**Validation**:
- ✅ Validate language codes against this list before API calls
- ✅ Store contact language preferences using these codes
- ⚠️ Custom language codes work but require setup in Qualtrics admin

**Localization**:
- ✅ Use regional variants when targeting specific regions (e.g., `PT-BR` for Brazil, `ES` for Latin America)
- ✅ Match language codes to contact demographics for better engagement
- ✅ Provide fallback to default language if preferred language unavailable

**API Usage**:
- **Translations**: Use with Survey Definition API for multi-language surveys
- **Distributions**: Specify language for email campaigns
- **Contacts**: Store language preference in contact embedded data
- **Reports**: Filter and segment by language

**Common Patterns**:
```csharp
// Example: Setting contact language preference
var contact = new Contact
{
    Email = "user@example.com",
    Language = "ES",  // Latin American Spanish
    EmbeddedData = new Dictionary<string, string>
    {
        ["preferredLanguage"] = "ES"
    }
};
```

---

## Implementation Notes

### Current Implementation (QualticsDashboard)

#### GetDistributionsForSurveyAsync()

**Endpoint Used**: `GET /distributions?surveyId={surveyId}`
**Implementation**: Pagination with `skipToken`
**Returns**: List of `Distribution` objects with basic info (id, surveyId, description, sendDate, status)

**Code Location**: `QualtricsService.cs` lines 129-194

---

#### GetDistributionStatsAsync()

**Current Implementation** (as of Nov 4, 2025):
**Endpoint Used**: `GET /distributions/{distributionId}/history`
**Approach**: Fetch all contact-level history entries and aggregate statuses manually

**Code Location**: `QualtricsService.cs` lines 237-305

**⚠️ Issue Discovered**: This approach is more complex than needed!

**Recommended Alternative**:
**Endpoint**: `GET /distributions/{distributionId}?surveyId={surveyId}`
**Approach**: Use the `stats` object directly from the response

**Why Switch?**
- ✅ **Simpler**: Single API call vs. paginated history aggregation
- ✅ **Faster**: No need to fetch thousands of contact records
- ✅ **Less Code**: No manual aggregation logic needed
- ✅ **Same Data**: Stats object provides same aggregate metrics

**Trade-off**:
- ❌ Lose contact-level detail (who specifically opened/bounced)
- ❌ Lose timestamp granularity (when each action occurred)

**Recommendation**: Use simpler approach unless you need contact-level detail for future features.

---

#### GetSurveyAsync()

**Endpoint Used**: `GET /surveys/{surveyId}`
**Implementation**: Single survey retrieval
**Returns**: `Survey` object with basic info (id, name, status, dates, ownerId, brandId)

**Code Location**: `QualtricsService.cs` lines 77-127

---

#### GetMailingListsAsync()

**Endpoint Used**: `GET /directories/{directoryId}/mailinglists`
**Implementation**: Basic list retrieval (no pagination currently)
**Returns**: List of `MailingList` objects

**Code Location**: `QualtricsService.cs` lines 373-441

**⚠️ Note**: Current implementation doesn't handle pagination - may need update for large directory

---

### Stub Service Implementation

**Purpose**: Testing without real Qualtrics API
**File**: `StubQualtricsService.cs`
**Returns**: Hardcoded test data

**Important**:
- Stub service is used when no valid Qualtrics API token is configured
- Returns realistic-looking data for testing
- Distribution stats: Sent=1000, Bounced=25, Opened=650, Clicked=420, Finished=320

---

### Key Decisions

1. **Stats Approach**: Currently using `/history` endpoint with aggregation
   - **Consider switching** to simpler `GET /distributions/{id}` with stats object
   - Only use `/history` if contact-level detail needed

2. **Pagination**: Using new `skipToken`-based pagination
   - ✅ Correctly implemented in GetDistributionsForSurveyAsync
   - ✅ Correctly implemented in GetDistributionStatsAsync (history)
   - ⚠️ Missing in GetMailingListsAsync (may need fix)

3. **Error Handling**: Rate limiting handled with retry logic
   - See `ExecuteWithRateLimitAsync` wrapper method

---

## Quick Reference

### Distribution Stats Comparison

| Approach | Endpoint | Pros | Cons | Use When |
|----------|----------|------|------|----------|
| **Simple** | `GET /distributions/{id}` | Fast, easy, 1 API call | No contact detail | Aggregate stats sufficient |
| **Detailed** | `GET /distributions/{id}/history` | Contact-level detail, timestamps | Slower, complex, multiple API calls | Need who/when detail |

### ID Formats

| Resource | Format | Example |
|----------|--------|---------|
| Survey | `SV_{11-15 chars}` | `SV_cHbKMOdeT8NetF3` |
| Distribution | `EMD_{15 chars}` | `EMD_1234567890abcde` |
| Mailing List | `CG_{15 chars}` | `CG_012345678901234` |
| Contact | `CID_{15 chars}` or `CGC_{15 chars}` | `CID_6SvNjhDzWKKWdCt` |
| Directory | `POOL_{15 chars}` | `POOL_012345678901234` |
| User | `UR_{15 chars}` | `UR_1M4aHozEkSxUfCl` |
| Response | `R_{15 chars}` | `R_YXIPQimT0z0A3i9` |

---

## Additional Resources

- **Official Documentation**: https://api.qualtrics.com/
- **Managing Surveys Guide**: https://api.qualtrics.com/guides/managing-surveys
- **Getting Survey Responses**: https://api.qualtrics.com/guides/response-export
- **XM Directory Guide**: https://api.qualtrics.com/guides/xm-directory

---

**Document Version**: 1.0.0
**Last Updated**: November 4, 2025
**Maintainer**: QualticsDashboard Development Team
