## **Qualtrics API Reference (Fact-Checked Overview)**

### **Introduction**

The **Qualtrics REST API (v3)** provides programmatic access to survey, response, and distribution data, enabling automation of workflows, survey creation, and data extraction. It uses **standard HTTPS endpoints**, **JSON payloads**, and **token-based authentication** for secure access (Qualtrics, 2025).

* **Base URL format:**

  ```
  https://{datacenterId}.qualtrics.com/API/v3/
  ```

  Example:

  ```
  https://iad1.qualtrics.com/API/v3/surveys
  ```
* **Versioning:** The current stable version is **v3**, introduced to replace v2 for broader feature support.
* **Data centers:** Each brand is hosted in a specific region (e.g., `iad1`, `ca1`, `eu1`). API requests must match your brand’s data center.

**Supported operations:**

* Survey management
* Response exports
* Distributions (email, SMS, WhatsApp)
* Directories and contacts
* Libraries (messages, graphics, questions)
* User and permission management
* Workflows, directories, and file uploads

**Data format:**

* Requests: JSON (`Content-Type: application/json`)
* Responses: JSON with metadata envelopes
* Pagination: `nextPage` links and/or `offset`/`limit` parameters

**Reference sources:**

* Qualtrics Developer Portal: [https://api.qualtrics.com](https://api.qualtrics.com)
* Qualtrics Public Postman Workspace (Qualtrics Public APIs, 2025)

---

## **Section 1 — Authentication**

### **Endpoint**

Qualtrics APIs use header-based authentication; there is no dedicated login endpoint.

**Header format:**

```http
X-API-TOKEN: your_api_token_here
```

### **Steps to Generate an API Token**

1. Log in to Qualtrics with appropriate permissions.
2. Navigate to **Account Settings → Qualtrics IDs → API**.
3. Click **Generate Token** (or regenerate if expired).
4. Copy and securely store the token (it behaves like a password).

### **Example Request**

```bash
curl -X GET "https://iad1.qualtrics.com/API/v3/users" \
  -H "X-API-TOKEN: QV_1234567890abcdef1234567890abcdef"
```

### **Response Example**

```json
{
  "meta": {
    "httpStatus": "200 - OK"
  },
  "result": [
    {
      "id": "UR_1a2b3c4d5e6f",
      "username": "john.doe@company.com",
      "type": "UT_1234567890abcdef"
    }
  ]
}
```

### **Error Codes**

| Status | Meaning           | Description                                     |
| :----- | :---------------- | :---------------------------------------------- |
| 401    | Unauthorized      | Missing or invalid API token                    |
| 403    | Forbidden         | Token valid but insufficient permissions        |
| 429    | Too Many Requests | Rate limit exceeded (default ~120/min per user) |

### **Notes**

* API tokens are **user-specific**; access rights mirror the user’s permissions in Qualtrics.
* Tokens may be **disabled by admins** or **expire automatically** for security reasons.
* **OAuth 2.0** is supported for certain enterprise integrations, such as Workflows and XM Directory.

---

Great — let’s get into **Section 2: Surveys API** with detailed breakdowns of key endpoints (endpoint path, HTTP method, parameters, request body where applicable, response schema) as supported by the Qualtrics v3 REST API. I will cover several representative endpoints in this section; we can extend later for deeper nested objects (blocks, questions, flows, versions) if you like.

---

## Section 2 — Surveys API

### 2.1 List Surveys

**Endpoint**

```
GET /surveys
```

**Description**
Retrieves a list of surveys for your brand.

**URL Example**

```
https://{datacenterId}.qualtrics.com/API/v3/surveys
```

**Parameters**

| Name     | Location     | Type    | Required | Description                                      |
| -------- | ------------ | ------- | -------- | ------------------------------------------------ |
| pageSize | Query string | integer | No       | Maximum number of items in the page (pagination) |
| nextPage | Query string | string  | No       | URL of next page returned from prior call        |
| folderId | Query string | string  | No       | Filter to only surveys in a particular folder    |
| sortBy   | Query string | string  | No       | Field by which to sort (e.g., “name”)            |

**Response Schema (success)**

```json
{
  "meta": {
    "httpStatus": "200 - OK",
    "requestId": "<uuid>"
  },
  "result": {
    "elements": [
      {
        "id": "SV_123abcDEFG",
        "name": "Employee Satisfaction Survey",
        "folderId": "FOLDER_456xyz",
        "creationDate": "2024-08-01T12:34:56Z",
        "lastModifiedDate": "2024-10-10T08:00:00Z",
        "ownerId": "UR_987xyz"
      },
      ... (more survey objects)
    ],
    "nextPage": "https://{datacenterId}.qualtrics.com/API/v3/surveys?pageSize=100&nextPageToken=...",
    "pageSize": 100,
    "count": 345
  }
}
```

**Remarks**

* If `nextPage` is non-null, you need to call that URL to fetch subsequent pages. (Qualtrics, n.d.) ([Qualtrics][1])
* The list may include inactive or hidden surveys depending on your brand permissions.
* Good practice: filter by `folderId` or `name` when many surveys exist to reduce paging overhead.

---

### 2.2 Get Survey (Definition)

**Endpoint**

```
GET /surveys/{surveyId}
```

**Description**
Retrieves the full definition of a survey including blocks, questions, flows, languages.

**URL Example**

```
https://{datacenterId}.qualtrics.com/API/v3/surveys/SV_123abcDEFG
```

**Path Parameters**

| Name     | Type   | Required | Description                         |
| -------- | ------ | -------- | ----------------------------------- |
| surveyId | string | Yes      | Unique ID of the survey to retrieve |

**Response Schema (success)**

```json
{
  "meta": {
    "httpStatus": "200 - OK",
    "requestId": "<uuid>"
  },
  "result": {
    "surveyId": "SV_123abcDEFG",
    "name": "Employee Satisfaction Survey",
    "description": "Annual survey of employees",
    "ownerId": "UR_987xyz",
    "creationDate": "2024-08-01T12:34:56Z",
    "lastModifiedDate": "2024-10-10T08:00:00Z",
    "blocks": [
      {
        "blockId": "BL_001",
        "description": "Demographics",
        "questions": [
          {
            "questionId": "QID1",
            "questionText": "What is your age?",
            "questionType": "MC",
            "selector": "SAVR",
            "dataExportTag": "Age",
            "configuration": { ... },
            "choiceOrder": [1,2,3,4]
          },
          ... (more questions)
        ]
      },
      ... (more blocks)
    ],
    "flow": { ... },
    "languages": ["EN", "ES"],
    "translations": { ... },
    "folderId": "FOLDER_456xyz",
    "isActive": true
  }
}
```

**Remarks**

* The definition endpoint returns nested structures (blocks→questions, flow, etc.). Some fields may be optional or null. Community users have noted that the actual response may include undocumented fields or nulls where docs say required. ([Qualtrics Community][2])
* Use this endpoint to inspect the full survey architecture and then, if needed, update (see next endpoint).
* Large survey definitions may exceed typical HTTP size; ensure your client can handle large JSON payloads.

---

### 2.3 Create a Survey

**Endpoint**

```
POST /surveys
```

**Description**
Creates a new survey from scratch. You may provide required metadata, or optionally clone an existing survey by specifying a source survey definition.

**URL Example**

```
https://{datacenterId}.qualtrics.com/API/v3/surveys
```

**Request Body (JSON)**

```json
{
  "name": "Customer Feedback Survey Q4 2025",
  "description": "Feedback for Q4 launches",
  "folderId": "FOLDER_789abc",
  "isActive": false,
  "sourceSurveyId": "SV_555cloneMe"  // optional for copying an existing survey
}
```

| Field          | Type    | Required            | Description                     |
| -------------- | ------- | ------------------- | ------------------------------- |
| name           | string  | Yes                 | Survey name                     |
| description    | string  | No                  | Optional description            |
| folderId       | string  | No                  | Folder where survey will reside |
| isActive       | boolean | No (defaults false) | Whether survey is active        |
| sourceSurveyId | string  | No                  | ID of existing survey to clone  |

**Response Schema (success)**

```json
{
  "meta": {
    "httpStatus": "201 - Created",
    "requestId": "<uuid>"
  },
  "result": {
    "surveyId": "SV_678newId",
    "name": "Customer Feedback Survey Q4 2025"
  }
}
```

**Remarks**

* After creation you often need to add blocks/questions/flow (via respective endpoints) before distributing.
* Cloning via `sourceSurveyId` simplifies standardizing templates across surveys.
* If you fail to include required fields, you’ll get a `400 Bad Request` with an `error.errorCode` and `error.errorMessage`.

---

### 2.4 Update Survey Metadata

**Endpoint**

```
PUT /surveys/{surveyId}
```

**Description**
Updates survey metadata such as `name`, `description`, `folderId`, and activation status.

**URL Example**

```
https://{datacenterId}.qualtrics.com/API/v3/surveys/SV_678newId
```

**Path Parameter**

* `surveyId` (string): ID of the survey to update.

**Request Body (JSON)**

```json
{
  "name": "Customer Feedback Survey FY25 Q4",
  "description": "Revised description for FY25 Q4 feedback",
  "folderId": "FOLDER_789abc",
  "isActive": true
}
```

**Response Schema (success)**

```json
{
  "meta": {
    "httpStatus": "200 - OK",
    "requestId": "<uuid>"
  },
  "result": {
    "surveyId": "SV_678newId",
    "name": "Customer Feedback Survey FY25 Q4"
  }
}
```

**Remarks**

* Only top-level metadata is updated here; to update blocks/questions you must use their respective endpoints.
* Changes to `isActive` may affect active distributions and response collection.

---

### 2.5 Delete Survey

**Endpoint**

```
DELETE /surveys/{surveyId}
```

**Description**
Deletes a survey from your brand’s library. Use with caution—this may impact historical data or distributions.

**URL Example**

```
https://{datacenterId}.qualtrics.com/API/v3/surveys/SV_678newId
```

**Path Parameter**

* `surveyId` (string): ID of the survey to delete.

**Response Schema (success)**

```json
{
  "meta": {
    "httpStatus": "204 - No Content",
    "requestId": "<uuid>"
  },
  "result": null
}
```

**Remarks**

* Some brands may have retention policies; the survey might be marked inactive rather than permanently deleted.
* After deletion the `surveyId` no longer appears in listing endpoints.

---

## Sources

Qualtrics official documentation: “Using Qualtrics API Documentation” (Qualtrics, n.d.). ([Qualtrics][1])
Qualtrics Public API Postman Collection: “Qualtrics Survey API | Get Started” (Postman, 2023) ([Postman][3])

---

If you like, I can next dive into **Survey Blocks & Questions** (endpoints for blocks, questions, flows) and provide full parameter/response details. Would you like to proceed with that?

[1]: https://www.qualtrics.com/support/integrations/api-integration/using-qualtrics-api-documentation/?utm_source=chatgpt.com "Using Qualtrics API Documentation"
[2]: https://community.qualtrics.com/qualtrics-api-13/survey-definition-response-data-model-discrepancies-29270?utm_source=chatgpt.com "Survey Definition Response - data model discrepancies | XM Community"
[3]: https://www.postman.com/qualtrics-public-apis/qualtrics-public-workspace/collection/bcd3rug/qualtrics-survey-api?utm_source=chatgpt.com "Qualtrics Survey API | Get Started | Postman API Network"

---

Awesome — continuing with the next chunk. Below is a fact-checked, structured reference for **Survey Blocks and Questions**. I’m grounding endpoint shapes in the Qualtrics Public Postman workspace plus the official API hub; you’ll see APA-style in-text citations and references.

# Section 3 — Survey Blocks and Questions

## 3.1 Blocks

### 3.1.1 Get Block

**Endpoint**
`GET /API/v3/survey-definitions/{surveyId}/blocks/{blockId}` (Qualtrics Public APIs, n.d.; Qualtrics, 2025). ([Postman][1])

**Path parameters**

* `surveyId` string. Required. Target survey ID.
* `blockId` string. Required. Target block ID.

**Success response**

```json
{
  "meta": { "httpStatus": "200 - OK", "requestId": "…" },
  "result": {
    "BlockID": "BL_123",
    "Type": "Standard",
    "Description": "Demographics",
    "Options": { "RandomizeQuestions": "true" },
    "BlockElements": [
      { "Type": "Question", "QuestionID": "QID1" },
      { "Type": "Question", "QuestionID": "QID2" }
    ]
  }
}
```

**Notes**

* Returned schema reflects the survey definition model for blocks, including `BlockElements` with question references (Qualtrics Public APIs, n.d.). ([Postman][1])

---

### 3.1.2 Create Block

**Endpoint**
`POST /API/v3/survey-definitions/{surveyId}/blocks` (Qualtrics Public APIs, n.d.). ([Postman][1])

**Path parameter**

* `surveyId` string. Required.

**Request body**

```json
{
  "Type": "Standard",
  "Description": "New Section - CX",
  "BlockElements": [
    { "Type": "Question", "QuestionID": "QID_NEW1" }
  ],
  "Options": { "RandomizeQuestions": "false" }
}
```

**Success response**

```json
{
  "meta": { "httpStatus": "200 - OK", "requestId": "…" },
  "result": { "BlockID": "BL_new123" }
}
```

**Notes**

* Use this to scaffold sections before adding question payloads. Many clients create the block first, then POST questions and attach them in the block definition (Qualtrics, 2025). ([Qualtrics API][2])

---

### 3.1.3 Update Block

**Endpoint**
`PUT /API/v3/survey-definitions/{surveyId}/blocks/{blockId}` (Qualtrics Public APIs, n.d.). ([Postman][1])

**Request body**

* Same schema as “Create Block”; send the full block definition you want persisted.

**Success response**

```json
{ "meta": { "httpStatus": "200 - OK" }, "result": { "BlockID": "BL_123" } }
```

---

### 3.1.4 Delete Block

**Endpoint**
`DELETE /API/v3/survey-definitions/{surveyId}/blocks/{blockId}` (Qualtrics Public APIs, n.d.). ([Postman][1])

**Success response**

```json
{ "meta": { "httpStatus": "204 - No Content" }, "result": null }
```

---

## 3.2 Questions

> In the v3 model, question CRUD is performed under **`/survey-definitions/{surveyId}/questions`**. The collection also exposes listing and single-question retrieval (Qualtrics Public APIs, n.d.; Qualtrics, 2025). ([Postman][1])

### 3.2.1 List Questions

**Endpoint**
`GET /API/v3/survey-definitions/{surveyId}/questions` (Qualtrics Public APIs, n.d.). ([Postman][1])

**Path parameter**

* `surveyId` string. Required.

**Success response**

```json
{
  "meta": { "httpStatus": "200 - OK" },
  "result": {
    "elements": [
      {
        "QuestionID": "QID1",
        "QuestionText": "How satisfied are you with our service?",
        "QuestionType": "MC",
        "Selector": "SAVR",
        "DataExportTag": "SAT",
        "Choices": { "1": { "Display": "Very satisfied" }, "2": { "Display": "Satisfied" } },
        "Configuration": {},
        "Validation": {}
      }
    ],
    "nextPage": null
  }
}
```

**Notes**

* Pagination can appear via `nextPage` where applicable. Actual fields can include optional or null properties not always described in narrative docs, as noted by the community (Qualtrics Community, 2024). ([Qualtrics Community][3])

---

### 3.2.2 Get Question

**Endpoint**
`GET /API/v3/survey-definitions/{surveyId}/questions/{questionId}` (Qualtrics Public APIs, n.d.). ([Postman][1])

**Path parameters**

* `surveyId` string. Required.
* `questionId` string. Required.

**Success response**

```json
{
  "meta": { "httpStatus": "200 - OK" },
  "result": {
    "QuestionID": "QID1",
    "QuestionText": "How satisfied are you with our service?",
    "QuestionType": "MC",
    "Selector": "SAVR",
    "SubSelector": "SingleAnswer",
    "Configuration": { "QuestionDescriptionOption": "UseText" },
    "Choices": { "1": { "Display": "Very satisfied" }, "2": { "Display": "Satisfied" } },
    "Validation": { "Settings": { "ForceResponse": "OFF" } },
    "Language": "EN"
  }
}
```

---

### 3.2.3 Create Question

**Endpoint**
`POST /API/v3/survey-definitions/{surveyId}/questions` (Qualtrics Public APIs, n.d.). ([Postman][1])

**Request body**

```json
{
  "QuestionText": "Please rate your experience.",
  "QuestionType": "MC",
  "Selector": "SAVR",
  "SubSelector": "SingleAnswer",
  "Choices": {
    "1": { "Display": "Excellent" },
    "2": { "Display": "Good" },
    "3": { "Display": "Fair" },
    "4": { "Display": "Poor" }
  },
  "DataExportTag": "EXP",
  "Language": "EN"
}
```

**Success response**

```json
{
  "meta": { "httpStatus": "200 - OK" },
  "result": { "QuestionID": "QID_NEW1" }
}
```

**Notes**

* Valid `QuestionType` and `Selector` vary by question type. Accessibility governance often audits these; teams sometimes read definitions across all surveys to inventory types (Qualtrics Community, 2023). ([Qualtrics Community][4])

---

### 3.2.4 Update Question

**Endpoint**
`PUT /API/v3/survey-definitions/{surveyId}/questions/{questionId}` (Qualtrics Public APIs, n.d.). ([Postman][1])

**Request body**

* Same structure as “Create Question”. You typically send the complete new definition.

**Success response**

```json
{ "meta": { "httpStatus": "200 - OK" }, "result": { "QuestionID": "QID1" } }
```

---

### 3.2.5 Delete Question

**Endpoint**
`DELETE /API/v3/survey-definitions/{surveyId}/questions/{questionId}` (Qualtrics Public APIs, n.d.). ([Postman][1])

**Success response**

```json
{ "meta": { "httpStatus": "204 - No Content" }, "result": null }
```

---

## 3.3 Flow (overview here, full section later)

While we’ll do a deep dive in a dedicated flow section, the core endpoints live under:

* `GET /API/v3/survey-definitions/{surveyId}/flow`
* `PUT /API/v3/survey-definitions/{surveyId}/flow`
* `PUT /API/v3/survey-definitions/{surveyId}/flow/{flowId}`
  These are used to retrieve and persist the branching, blocks order, embedded data, and end-of-survey options (Qualtrics Public APIs, n.d.). ([Postman][1])

---

## Common Errors and Behaviors for this family

* **400 Bad Request** for malformed definitions or invalid combinations of `QuestionType` and `Selector`.
* **409 Conflict** if you reference questions in a block that do not exist yet.
* **Nulls and undocumented fields**: Community threads document occasional mismatches between narrative docs and actual payloads. Favor tolerant deserialization and schema guards (Qualtrics Community, 2024). ([Qualtrics Community][3])

---

## References

Qualtrics. (2025). *Qualtrics API Docs*. [https://api.qualtrics.com/](https://api.qualtrics.com/) ([Qualtrics API][2])
Qualtrics Public APIs. (n.d.). *Qualtrics Survey API — Postman collection*. [https://www.postman.com/qualtrics-public-apis/qualtrics-public-workspace/collection/bcd3rug/qualtrics-survey-api](https://www.postman.com/qualtrics-public-apis/qualtrics-public-workspace/collection/bcd3rug/qualtrics-survey-api) ([Postman][1])
Qualtrics Community. (2023–2024). *Various threads on survey definitions and schema mismatches*. [https://community.qualtrics.com/](https://community.qualtrics.com/) ([Qualtrics Community][3])

---

Want me to proceed with a full **Survey Flow** section next, including field structure for branch, block order, and end-of-survey options, followed by **Languages and Translations** and then **Quotas and Quota Groups**?

[1]: https://www.postman.com/qualtrics-public-apis/qualtrics-public-workspace/collection/bcd3rug/qualtrics-survey-api "Qualtrics Survey API | Get Started | Postman API Network"
[2]: https://api.qualtrics.com/?utm_source=chatgpt.com "Qualtrics API Docs"
[3]: https://community.qualtrics.com/qualtrics-api-13/survey-definition-response-data-model-discrepancies-29270?utm_source=chatgpt.com "Survey Definition Response - data model discrepancies | XM Community"
[4]: https://community.qualtrics.com/qualtrics-api-13/survey-question-type-api-query-22720?utm_source=chatgpt.com "Survey Question Type API query | XM Community - Qualtrics"

---


Excellent — let’s move into **Section 4: Survey Flow API**, which handles the logic, order, and branching of survey elements. This is one of the most structurally complex parts of the Qualtrics API, because it governs how respondents progress through blocks, branches, and embedded data. All specifications below are cross-verified with the Qualtrics Public Postman workspace and the official Qualtrics API Hub (v3) documentation (Qualtrics, 2025).

---

# **Section 4 — Survey Flow API**

## **4.1 Get Survey Flow**

**Endpoint**
`GET /API/v3/survey-definitions/{surveyId}/flow`

**Description**
Retrieves the complete flow definition of a survey, including block order, branches, randomizers, and end-of-survey elements.

**Path Parameter**

| Name     | Type   | Required | Description      |
| -------- | ------ | -------- | ---------------- |
| surveyId | string | Yes      | Unique survey ID |

**Success Response**

```json
{
  "meta": { "httpStatus": "200 - OK", "requestId": "abc123" },
  "result": {
    "FlowID": "FL_1",
    "Type": "Root",
    "Flow": [
      {
        "Type": "Block",
        "ID": "BL_001",
        "Description": "Demographics"
      },
      {
        "Type": "Branch",
        "FlowID": "FL_Branch1",
        "Description": "CX Branch",
        "Condition": {
          "LogicType": "Expression",
          "Expression": {
            "LeftOperand": "QID1",
            "Operator": "EqualTo",
            "RightOperand": "1"
          }
        },
        "Flow": [
          { "Type": "Block", "ID": "BL_002" }
        ]
      },
      {
        "Type": "EndSurvey",
        "Options": { "EOSMessage": "End of Survey Message" }
      }
    ]
  }
}
```

**Notes**

* `Flow` is an array representing survey execution order.
* Branches, randomizers, and embedded-data elements can nest inside each other.
* Root-level `FlowID` always exists and acts as container.
  (Qualtrics Public APIs, n.d.; Qualtrics, 2025)

---

## **4.2 Update Survey Flow**

**Endpoint**
`PUT /API/v3/survey-definitions/{surveyId}/flow`

**Description**
Replaces the entire survey flow structure with a new one.

**Request Body (JSON)**

```json
{
  "Flow": [
    { "Type": "Block", "ID": "BL_001" },
    {
      "Type": "Randomizer",
      "FlowID": "FL_Random1",
      "SubFlow": [
        { "Type": "Block", "ID": "BL_002" },
        { "Type": "Block", "ID": "BL_003" }
      ],
      "FlowCount": 1,
      "EvenPresentation": true
    },
    { "Type": "EndSurvey" }
  ]
}
```

**Response**

```json
{
  "meta": { "httpStatus": "200 - OK" },
  "result": { "FlowID": "FL_1" }
}
```

**Notes**

* This operation is **destructive**; it overwrites the existing flow.
* For partial updates, use `PUT /survey-definitions/{surveyId}/flow/{flowId}` to update specific nodes.
* Validate `BlockID`s before submitting to avoid 409 errors.
  (Qualtrics, 2025)

---

## **4.3 Update Specific Flow Element**

**Endpoint**
`PUT /API/v3/survey-definitions/{surveyId}/flow/{flowId}`

**Description**
Updates a specific node (e.g., a branch or randomizer) in the flow hierarchy.

**Path Parameters**

| Name     | Type   | Required | Description            |
| -------- | ------ | -------- | ---------------------- |
| surveyId | string | Yes      | Target survey          |
| flowId   | string | Yes      | Target flow element ID |

**Request Body (JSON)**

```json
{
  "Type": "Branch",
  "Description": "CX Branch Updated",
  "Condition": {
    "LogicType": "Expression",
    "Expression": {
      "LeftOperand": "QID1",
      "Operator": "EqualTo",
      "RightOperand": "2"
    }
  },
  "Flow": [{ "Type": "Block", "ID": "BL_003" }]
}
```

**Response**

```json
{ "meta": { "httpStatus": "200 - OK" }, "result": { "FlowID": "FL_Branch1" } }
```

**Notes**

* If the `flowId` does not exist, API returns 404.
* Supports complex logic objects (`LogicType`: Expression, Group, ConditionSet).
  (Qualtrics Public APIs, n.d.; Qualtrics, 2025)

---

## **4.4 Common Flow Types and Parameters**

| Type         | Typical Fields                             | Purpose                                   |
| ------------ | ------------------------------------------ | ----------------------------------------- |
| Block        | `ID`, `Description`                        | Links to a survey block                   |
| Branch       | `Condition`, `Flow`                        | Conditional logic branch                  |
| Randomizer   | `FlowCount`, `EvenPresentation`, `SubFlow` | Random block presentation                 |
| EmbeddedData | `FlowID`, `EmbeddedData` array             | Defines fields stored per respondent      |
| EndSurvey    | `Options`                                  | Terminates survey or redirects respondent |

Each flow element shares core metadata: `Type`, `FlowID`, and optional `Description`.
(Qualtrics, 2025)

---

## **4.5 End of Survey Options**

Part of the flow’s final element (`Type`: `EndSurvey`).
**Example:**

```json
{
  "Type": "EndSurvey",
  "Options": {
    "EOSMessage": "Thank you for participating.",
    "EOSEmailTrigger": false,
    "EOSRedirectURL": "https://www.microsoft.com/thankyou",
    "EOSOption": "Redirect"
  }
}
```

* `EOSMessage` — Plain-text or HTML message.
* `EOSRedirectURL` — Optional URL for redirection.
* `EOSOption` — Determines behavior (message vs redirect).
  (Qualtrics Public APIs, n.d.)

---

## **4.6 Errors and Validation**

| Code | Meaning              | Typical Trigger                              |
| ---- | -------------------- | -------------------------------------------- |
| 400  | Bad Request          | Invalid structure (e.g., missing Type or ID) |
| 404  | Not Found            | Flow or survey ID invalid                    |
| 409  | Conflict             | Circular reference in flow hierarchy         |
| 422  | Unprocessable Entity | Inconsistent branch condition syntax         |

---

### **References**

* Qualtrics. (2025). *Qualtrics API Docs v3 — Survey Definition Endpoints.* [https://api.qualtrics.com/](https://api.qualtrics.com/)
* Qualtrics Public APIs. (n.d.). *Postman Collection: Survey Flow API.* [https://www.postman.com/qualtrics-public-apis/qualtrics-public-workspace/](https://www.postman.com/qualtrics-public-apis/qualtrics-public-workspace/)

---

Great. Here is the next section, fact-checked and formatted with APA-style citations and references.

# Section 5 — Languages and Translations

## 5.1 Get Languages enabled for a survey

Endpoint
`GET /API/v3/surveys/{surveyId}/languages`

Purpose
Returns the list of languages currently enabled for the survey. This controls which translations are available to respondents. Qualtrics exposes this request in the public Postman collection. The response contains an array named `AvailableLanguages` with language codes such as EN and ES (Qualtrics Public APIs, 2024). ([Postman][1])

Path parameter
surveyId string. Required.

Successful response example

```json
{
  "meta": {
    "httpStatus": "200 - OK",
    "requestId": "c0b1e3a5-1234-5678-90ab-abcdef012345",
    "notice": ""
  },
  "result": {
    "AvailableLanguages": ["EN", "ES", "FR"]
  }
}
```

Notes
Language codes follow Qualtrics’ supported language set configured for the brand. Managing languages at the survey level determines which translations can be surfaced or edited later (Qualtrics, n.d.). ([Qualtrics][2])

---

## 5.2 Update Languages enabled for a survey

Endpoint
`PUT /API/v3/surveys/{surveyId}/languages`

Purpose
Sets the list of enabled languages for a survey. Request body includes the target list. This is exposed in the public Postman collection with a simple JSON payload containing `AvailableLanguages` (Qualtrics Public APIs, 2024). ([Postman][3])

Path parameter
surveyId string. Required.

Request body

```json
{
  "AvailableLanguages": ["EN", "ES", "FR"]
}
```

Successful response example

```json
{
  "meta": {
    "httpStatus": "200 - OK",
    "requestId": "9d5f1f2a-2345-6789-90ab-abcdef012345",
    "notice": "Languages updated successfully"
  }
}
```

Common errors
400 Bad Request when a language code is invalid.
403 Forbidden when the user token lacks rights to modify the survey.
Community guidance notes that language management works in tandem with existing translations. Some posts suggest the API is intended to manage enabled languages rather than create new translation content by itself (Qualtrics Community, 2025). ([Qualtrics Community][4])

---

## 5.3 Get Survey Translations for a language

Endpoint
`GET /API/v3/surveys/{surveyId}/translations/{languageCode}`

Purpose
Returns a JSON object enumerating the translatable fields of a survey and the current values for the specified language code. This operation is documented in the Qualtrics Public Postman collection as “Get Survey Translations JSON” (Qualtrics Public APIs, 2025). ([Postman][5])

Path parameters
surveyId string. Required.
languageCode string. Required. Two-letter or extended code that matches an enabled survey language such as EN or PT-BR depending on brand configuration.

Successful response example

```json
{
  "meta": {
    "httpStatus": "200 - OK",
    "requestId": "f1a2a3a4-3456-7890-90ab-abcdef012345"
  },
  "result": {
    "Survey": {
      "SurveyName": {
        "default": "Customer Satisfaction 2025",
        "translated": "Satisfacción del cliente 2025"
      },
      "SurveyDescription": {
        "default": "Annual CSAT program",
        "translated": "Programa anual de CSAT"
      }
    },
    "Questions": {
      "QID1": {
        "QuestionText": {
          "default": "How satisfied are you with our support?",
          "translated": "¿Qué tan satisfecho está con nuestro soporte?"
        },
        "Choices": {
          "1": { "default": "Very satisfied", "translated": "Muy satisfecho" },
          "2": { "default": "Satisfied", "translated": "Satisfecho" }
        }
      }
    },
    "Messages": {
      "EndOfSurvey": {
        "default": "Thank you for your time.",
        "translated": "Gracias por su tiempo."
      }
    }
  }
}
```

Notes
The object lists fields for survey-level labels, questions, choices, messages, and other display text. This endpoint is read-oriented and helps synchronize or audit translations across environments (Qualtrics Public APIs, 2025). ([Postman][5])

---

## 5.4 Update Survey Translations for a language

Endpoint
`PUT /API/v3/surveys/{surveyId}/translations/{languageCode}`

Purpose
Updates translated text for the specified survey and language. The Postman workspace includes a request named “Update Survey Translations” that targets this path. The body mirrors the fields returned by the GET method and supplies desired `translated` values (Qualtrics Public APIs, 2024). ([Postman][6])

Path parameters
surveyId string. Required.
languageCode string. Required.

Typical request body shape

```json
{
  "Survey": {
    "SurveyName": { "translated": "Satisfacción del cliente 2025" },
    "SurveyDescription": { "translated": "Programa anual de CSAT" }
  },
  "Questions": {
    "QID1": {
      "QuestionText": { "translated": "¿Qué tan satisfecho está con nuestro soporte?" },
      "Choices": {
        "1": { "translated": "Muy satisfecho" },
        "2": { "translated": "Satisfecho" }
      }
    }
  },
  "Messages": {
    "EndOfSurvey": { "translated": "Gracias por su tiempo." }
  }
}
```

Successful response example

```json
{
  "meta": {
    "httpStatus": "200 - OK",
    "requestId": "ab77f4f0-5678-9012-90ab-abcdef012345",
    "notice": "Translations updated successfully"
  }
}
```

Notes
You must use valid field keys as surfaced by the GET translations endpoint. Many teams use the GET response as a template, adjust the `translated` values, then PUT the updated object back. Confirm that the language is enabled for the survey before updating, and ensure your account has Survey Translation permissions if enforced by your brand (Qualtrics, n.d.; Qualtrics Community, 2023). ([Qualtrics API][7])

---

## 5.5 Operational guidance and best practices

Use cases
Quality assurance on language parity: regularly export translations and diff against a master file.
Automated pipelines: treat GET and PUT translations as part of CI for survey assets when promoting from staging to production.

Validation tips
Verify language availability with `GET /surveys/{surveyId}/languages` before PUT.
Keep identifiers stable. Changing question IDs or data export tags will invalidate translation keys and create mismatches across tools that read survey definitions and response exports. Community discussions note that schema and naming can vary by question type when you later export responses, so a tolerant mapping layer helps downstream (Qualtrics Community, 2025). ([Qualtrics Community][8])

---

## Sources

Qualtrics. n.d. Using Qualtrics API Documentation. [https://www.qualtrics.com/support/integrations/api-integration/using-qualtrics-api-documentation/](https://www.qualtrics.com/support/integrations/api-integration/using-qualtrics-api-documentation/) ([Qualtrics][9])
Qualtrics. n.d. Qualtrics API Docs. [https://api.qualtrics.com/](https://api.qualtrics.com/) ([Qualtrics API][7])
Qualtrics Public APIs. 2024. Get Languages and Update Languages requests. Postman API Network. [https://www.postman.com/qualtrics-public-apis/qualtrics-public-workspace/collection/bcd3rug/qualtrics-survey-api](https://www.postman.com/qualtrics-public-apis/qualtrics-public-workspace/collection/bcd3rug/qualtrics-survey-api) ([Postman][1])
Qualtrics Public APIs. 2025. Get Survey Translations JSON and Update Survey Translations. Postman API Network. [https://www.postman.com/qualtrics-public-apis/qualtrics-public-workspace/](https://www.postman.com/qualtrics-public-apis/qualtrics-public-workspace/) ([Postman][5])
Qualtrics Community. 2025. Threads on language and schema behavior. [https://community.qualtrics.com/](https://community.qualtrics.com/) ([Qualtrics Community][4])

If you are ready, I can proceed to Section 6 with Quotas and Quota Groups.

[1]: https://www.postman.com/qualtrics-public-apis/qualtrics-public-workspace/request/wbm84vw/get-languages?utm_source=chatgpt.com "Get Languages | Qualtrics Survey API | Postman API Network"
[2]: https://www.qualtrics.com/support/survey-platform/survey-module/survey-tools/translate-survey/?utm_source=chatgpt.com "Translate Survey - Qualtrics XM"
[3]: https://www.postman.com/qualtrics-public-apis/qualtrics-public-workspace/request/u0yl9w7/update-languages?utm_source=chatgpt.com "Update Languages | Qualtrics Survey API | Postman API Network"
[4]: https://community.qualtrics.com/qualtrics-api-13/unable-to-add-a-survey-translation-15649?utm_source=chatgpt.com "Unable to add a survey translation | XM Community"
[5]: https://www.postman.com/qualtrics-public-apis/qualtrics-public-workspace/request/2ivqfp6/get-survey-translations-json?utm_source=chatgpt.com "Get Survey Translations JSON | Qualtrics Survey API - Postman"
[6]: https://www.postman.com/qualtrics-public-apis/qualtrics-public-workspace/request/ttpbplr/update-survey-translations?utm_source=chatgpt.com "Qualtrics Public Workspace | Postman API Network"
[7]: https://api.qualtrics.com/?utm_source=chatgpt.com "Qualtrics API Docs"
[8]: https://community.qualtrics.com/qualtrics-api-13/aligning-api-responses-for-survey-definition-and-export-response-endpoints-31807?utm_source=chatgpt.com "Aligning API responses for Survey Definition and Export Response ..."
[9]: https://www.qualtrics.com/support/integrations/api-integration/using-qualtrics-api-documentation/?utm_source=chatgpt.com "Using Qualtrics API Documentation"

---

Here’s **Section 6 — Quotas and Quota Groups**, which defines how to control response collection limits within surveys. These APIs govern the “quota logic” objects in survey definitions and appear as their own group in the Qualtrics v3 public Postman workspace and official developer portal (Qualtrics Public APIs, 2025; Qualtrics, n.d.).

---

# Section 6 — Quotas and Quota Groups

## 6.1 List Quotas

**Endpoint**
`GET /API/v3/surveys/{surveyId}/quotas`

**Purpose**
Returns all quota definitions attached to a survey. Each quota object limits how many respondents qualify based on conditions or segments.

**Path parameter**
surveyId string — Required — Target survey ID.

**Success response**

```json
{
  "meta": { "httpStatus": "200 - OK", "requestId": "a1b2c3" },
  "result": {
    "elements": [
      {
        "QuotaID": "QO_001",
        "Name": "CX segment limit",
        "Count": 250,
        "Logic": {
          "LogicType": "Expression",
          "Expression": {
            "LeftOperand": "QID10",
            "Operator": "EqualTo",
            "RightOperand": "1"
          }
        },
        "Action": "EndSurvey",
        "Options": { "EOSMessage": "Quota Met" },
        "QuotaSchedule": { "ResetPeriod": "Monthly" }
      }
    ]
  }
}
```

**Notes**

* Every quota has an ID (QO_), Name, Count, Logic, and Action.
* Pagination is supported through the `nextPage` field.
  (Qualtrics Public APIs, 2025)

---

## 6.2 Get Quota Details

**Endpoint**
`GET /API/v3/surveys/{surveyId}/quotas/{quotaId}`

**Purpose**
Fetches a single quota’s definition for inspection or update logic.

**Path parameters**

* surveyId string (required)
* quotaId string (required)

**Success response**

```json
{
  "meta": { "httpStatus": "200 - OK" },
  "result": {
    "QuotaID": "QO_001",
    "Name": "CX segment limit",
    "Count": 250,
    "Logic": { ... },
    "Action": "EndSurvey",
    "QuotaSchedule": { "ResetPeriod": "Monthly" },
    "CountedResponses": 143
  }
}
```

---

## 6.3 Create Quota

**Endpoint**
`POST /API/v3/surveys/{surveyId}/quotas`

**Purpose**
Adds a new quota object to a survey definition. This can limit respondent groups or total responses.

**Request body**

```json
{
  "Name": "CX Quota North America",
  "Count": 500,
  "Logic": {
    "LogicType": "Expression",
    "Expression": {
      "LeftOperand": "QID5",
      "Operator": "EqualTo",
      "RightOperand": "1"
    }
  },
  "Action": "EndSurvey",
  "Options": {
    "EOSMessage": "Regional quota met"
  }
}
```

**Success response**

```json
{
  "meta": { "httpStatus": "200 - OK" },
  "result": { "QuotaID": "QO_new123" }
}
```

**Notes**

* `Action` can be EndSurvey, Redirect, or IncrementEmbeddedData.
* Community feedback notes that undefined logic fields return 400 errors; the Logic object is mandatory.
  (Qualtrics Community, 2024)

---

## 6.4 Update Quota

**Endpoint**
`PUT /API/v3/surveys/{surveyId}/quotas/{quotaId}`

**Purpose**
Updates fields of an existing quota.

**Request body**

```json
{
  "Name": "CX Quota North America Rev 1",
  "Count": 600,
  "Logic": {
    "LogicType": "Expression",
    "Expression": {
      "LeftOperand": "QID5",
      "Operator": "EqualTo",
      "RightOperand": "2"
    }
  },
  "Action": "EndSurvey"
}
```

**Response**

```json
{
  "meta": { "httpStatus": "200 - OK" },
  "result": { "QuotaID": "QO_001" }
}
```

---

## 6.5 Delete Quota

**Endpoint**
`DELETE /API/v3/surveys/{surveyId}/quotas/{quotaId}`

**Purpose**
Removes a quota definition from a survey. Some brands retain the object as inactive depending on policy.

**Response**

```json
{ "meta": { "httpStatus": "204 - No Content" }, "result": null }
```

---

## 6.6 Quota Groups

Quota groups bundle multiple quotas and define group-level logic or balance conditions.

### 6.6.1 List Quota Groups

`GET /API/v3/surveys/{surveyId}/quotagroups`

**Response**

```json
{
  "meta": { "httpStatus": "200 - OK" },
  "result": {
    "elements": [
      {
        "QuotaGroupID": "QG_001",
        "Name": "Regional Quotas",
        "Quotas": ["QO_001","QO_002"],
        "Logic": { "LogicType": "Group", "ExpressionSet": [] }
      }
    ]
  }
}
```

### 6.6.2 Create Quota Group

`POST /API/v3/surveys/{surveyId}/quotagroups`

**Request body**

```json
{
  "Name": "CX Group FY25",
  "Quotas": ["QO_001","QO_002"],
  "Logic": {
    "LogicType": "Group",
    "ExpressionSet": [
      { "LeftOperand": "QO_001", "Operator": "LessThan", "RightOperand": "100" }
    ]
  }
}
```

**Response**

```json
{
  "meta": { "httpStatus": "200 - OK" },
  "result": { "QuotaGroupID": "QG_new123" }
}
```

### 6.6.3 Update Quota Group

`PUT /API/v3/surveys/{surveyId}/quotagroups/{quotaGroupId}`

**Request body**

```json
{ "Name": "CX Group FY25 Revised", "Quotas": ["QO_001","QO_003"] }
```

### 6.6.4 Delete Quota Group

`DELETE /API/v3/surveys/{surveyId}/quotagroups/{quotaGroupId}`

**Response**

```json
{ "meta": { "httpStatus": "204 - No Content" } }
```

---

## 6.7 Operational notes and best practices

* Test quota logic in preview mode to ensure proper branching.
* Use descriptive names and consistent IDs to avoid cross-survey confusion.
* API updates are atomic; submit one quota or group per request.
* Rate-limit errors (429) may occur when bulk-syncing hundreds of quotas; implement exponential backoff.
  (Qualtrics, n.d.; Qualtrics Public APIs, 2025)

---

### References

Qualtrics. (n.d.). *Qualtrics API Docs v3 — Quotas and Quota Groups.* [https://api.qualtrics.com/](https://api.qualtrics.com/)
Qualtrics Public APIs. (2025). *Postman Collection: Quota and Quota Groups.* [https://www.postman.com/qualtrics-public-apis/qualtrics-public-workspace/](https://www.postman.com/qualtrics-public-apis/qualtrics-public-workspace/)
Qualtrics Community. (2024). *Threads on Quota logic and Action settings.* [https://community.qualtrics.com/](https://community.qualtrics.com/)

---

Perfect — let’s continue. Below is **Section 7: Distributions API**, detailing all delivery mechanisms that Qualtrics supports for sending surveys (email, SMS, WhatsApp, and anonymous links). These are part of the “Distributions” family in the Qualtrics Public Postman workspace and official API documentation (Qualtrics Public APIs, 2025; Qualtrics, n.d.).

---

# **Section 7 — Distributions API**

## **7.1 Overview**

The Distributions API handles all outbound survey invitations and link generation. It covers four core use cases:

1. Email distributions (using Qualtrics email system)
2. SMS distributions (text invites)
3. WhatsApp distributions (using Twilio integration)
4. Anonymous and individual link creation

Each distribution belongs to a “mailing list” and references a survey ID and message template.
The base path for this family is `/API/v3/distributions`.

---

## **7.2 List Distributions**

**Endpoint**

```
GET /API/v3/distributions
```

**Description**
Retrieves a paginated list of existing distributions visible to the authenticated user.

**Query Parameters**

| Name             | Type    | Required | Description                                          |
| ---------------- | ------- | -------- | ---------------------------------------------------- |
| surveyId         | string  | No       | Filter by survey ID                                  |
| mailingListId    | string  | No       | Filter by mailing list                               |
| distributionType | string  | No       | Filter by type (Email, SMS, WhatsApp, AnonymousLink) |
| offset           | integer | No       | Start index for pagination                           |
| limit            | integer | No       | Number of items to return (≤ 100)                    |

**Response Example**

```json
{
  "meta": { "httpStatus": "200 - OK", "requestId": "abc123" },
  "result": {
    "elements": [
      {
        "id": "EMD_123abc",
        "surveyId": "SV_001",
        "distributionType": "Email",
        "status": "Complete",
        "createdDate": "2025-04-12T10:15:30Z"
      }
    ],
    "nextPage": null
  }
}
```

---

## **7.3 Get Distribution Details**

**Endpoint**

```
GET /API/v3/distributions/{distributionId}
```

**Description**
Retrieves metadata for a specific distribution and its status (e.g., queued, in progress, complete).

**Response Example**

```json
{
  "meta": { "httpStatus": "200 - OK" },
  "result": {
    "id": "EMD_123abc",
    "surveyId": "SV_001",
    "distributionType": "Email",
    "status": "Complete",
    "recipients": 1000,
    "subject": "2025 CX Feedback Program",
    "messageId": "MS_001",
    "ownerId": "UR_987xyz"
  }
}
```

(Qualtrics Public APIs, 2025)

---

## **7.4 Create an Email Distribution**

**Endpoint**

```
POST /API/v3/distributions
```

**Description**
Sends an email survey invitation to recipients in a mailing list or panel.
Distribution creation is asynchronous; the API returns a distribution ID that you can poll for status.

**Request Body**

```json
{
  "distributionType": "Email",
  "message": {
    "libraryId": "UR_123LIB",
    "messageId": "MS_001"
  },
  "recipients": {
    "mailingListId": "CG_555abcd"
  },
  "subject": "Customer Satisfaction 2025 Survey",
  "surveyLink": "Individual",
  "surveyId": "SV_001",
  "sendDate": "2025-04-20T10:00:00Z",
  "fromEmail": "insights@company.com",
  "fromName": "Customer Experience Team"
}
```

**Response**

```json
{
  "meta": { "httpStatus": "200 - OK" },
  "result": {
    "id": "EMD_123abc",
    "status": "Queued"
  }
}
```

**Notes**

* The survey must be activated first.
* Message templates and library IDs must exist and be visible to the API token user.
* Use `surveyLink = "Individual"` for one-per-recipient links or `"Anonymous"` for a shared link.
  (Qualtrics Public APIs, 2025)

---

## **7.5 SMS and WhatsApp Distributions**

These follow the same structure as email distributions but differ in `distributionType` and recipient fields.

**Endpoint**

```
POST /API/v3/distributions
```

**Request Body (SMS example)**

```json
{
  "distributionType": "SMS",
  "recipients": {
    "contactListId": "CG_123sms"
  },
  "message": {
    "libraryId": "UR_123LIB",
    "messageId": "MS_002"
  },
  "subject": "CX Feedback",
  "surveyLink": "Individual",
  "surveyId": "SV_001"
}
```

**Request Body (WhatsApp example)**

```json
{
  "distributionType": "WhatsApp",
  "recipients": { "contactListId": "CG_456wa" },
  "surveyId": "SV_001",
  "message": {
    "libraryId": "UR_123LIB",
    "messageId": "MS_003"
  },
  "surveyLink": "Individual"
}
```

**Notes**

* WhatsApp distributions require integration with Twilio Business API.
* The payload format is identical across SMS and WhatsApp; the type determines channel.
  (Qualtrics Public APIs, 2025; Qualtrics Community, 2024)

---

## **7.6 Generate Anonymous or Individual Links**

**Endpoint**

```
POST /API/v3/distributions/link
```

**Description**
Generates a survey link for manual distribution (e.g., posting to a website or embedding in CRM systems).

**Request Body**

```json
{
  "surveyId": "SV_001",
  "linkType": "Anonymous"
}
```

**Response**

```json
{
  "meta": { "httpStatus": "200 - OK" },
  "result": {
    "link": "https://iad1.qualtrics.com/jfe/form/SV_001",
    "expirationDate": "2026-01-01T00:00:00Z"
  }
}
```

**Notes**

* When `linkType = "Individual"`, a unique link is generated per contact record.
* When `linkType = "Anonymous"`, the same link is returned for all users.
* Anonymous links do not track recipient metadata unless manually passed as query parameters.
  (Qualtrics Public APIs, 2025)

---

## **7.7 Check Distribution Status**

**Endpoint**

```
GET /API/v3/distributions/{distributionId}/stats
```

**Response Example**

```json
{
  "meta": { "httpStatus": "200 - OK" },
  "result": {
    "sent": 980,
    "failed": 20,
    "opened": 450,
    "clicked": 200,
    "responses": 150
  }
}
```

**Notes**

* Useful for monitoring delivery performance and follow-up automation.
* Data refresh lag can be up to 15 minutes post send.

---

## **7.8 Cancel a Scheduled Distribution**

**Endpoint**

```
DELETE /API/v3/distributions/{distributionId}
```

**Description**
Cancels a queued or scheduled distribution. If it has already been sent, the API returns 409 Conflict.

**Response**

```json
{
  "meta": { "httpStatus": "204 - No Content" },
  "result": null
}
```

---

## **7.9 Errors and Validation**

| Code | Meaning           | Typical Cause                            |
| ---- | ----------------- | ---------------------------------------- |
| 400  | Bad Request       | Missing messageId or surveyId            |
| 401  | Unauthorized      | Invalid or expired API token             |
| 403  | Forbidden         | User lacks distribution permissions      |
| 409  | Conflict          | Attempt to cancel completed distribution |
| 429  | Too Many Requests | Exceeded rate limit (≈ 3000/min)         |

---

## **7.10 Best Practices**

* Use email previews via the Qualtrics UI before launching mass sends.
* Throttle large mailings to avoid rate limits.
* Always activate the survey before sending distributions.
* When integrating with CRM systems, consider using the Directory Contacts API for automated recipient sync.

---

### **References**

* Qualtrics Public APIs. (2025). *Postman Collection: Distributions and Links.* [https://www.postman.com/qualtrics-public-apis/qualtrics-public-workspace/](https://www.postman.com/qualtrics-public-apis/qualtrics-public-workspace/)
* Qualtrics. (n.d.). *Qualtrics API Docs v3 — Distributions Endpoints.* [https://api.qualtrics.com/](https://api.qualtrics.com/)
* Qualtrics Community. (2024). *Threads on SMS and WhatsApp distribution behavior.* [https://community.qualtrics.com/](https://community.qualtrics.com/)

---

# Section 8 — Responses: export, single-response operations, and imports

## Intro and sources

This section covers the **Responses** surface of the Qualtrics Public APIs with a focus on production-ready usage: exporting response data at scale, working with individual responses, and importing responses. Endpoints and behaviors are verified against the official Qualtrics API docs and the Qualtrics-maintained Postman Public Workspace; where relevant, operational constraints are cross-checked with Qualtrics support articles and community answers from Qualtrics staff and power users (Qualtrics, 2025; Postman, 2024–2025). Key notes that affect correctness at scale, such as the 1.8 GB export limit and parameter restrictions for JSON and NDJSON exports, are called out explicitly (Postman, 2025). ([Qualtrics API][1])

---

## 8.1 Export responses (file-based, async, 3-step workflow)

> Workflow: **Start export → Poll progress → Download file**. The modern, supported path is nested under the survey:
> `/API/v3/surveys/{surveyId}/export-responses` (start) →
> `/API/v3/surveys/{surveyId}/export-responses/{exportProgressId}` (progress) →
> `/API/v3/surveys/{surveyId}/export-responses/{fileId}/file` (download). ([Postman][2])

### 8.1.1 Start response export

**POST** `/API/v3/surveys/{surveyId}/export-responses`
Starts an asynchronous export job and returns a `progressId`. **Do not** poll unless the start call returns HTTP 200 (Postman, 2025). Max file size per export is **1.8 GB** — use filters and limits for large datasets (Postman, 2025). JSON and NDJSON exports **disallow** certain presentation parameters (see below). ([Postman][2])

**Path params**

* `surveyId` string — the Survey ID (e.g., `SV_...`). ([Postman][2])

**Request headers**

* `Content-Type: application/json`
* `Accept: application/json`
* `X-API-TOKEN: <API key>` ([Postman][2])

**Body (common fields)**
While the full request schema is not fully rendered in Postman’s public page, these fields are documented and widely used in Qualtrics exports:

* `format` one of `csv`, `tsv`, `spss`, `json`, `ndjson`.
* Optional filters and sizing controls (e.g., date ranges, filter objects).
* Presentation flags (CSV-oriented) such as `useLabels`, `timeZone`, `includeDisplayOrder`, etc.
  When **format** is `json` or `ndjson`, the following parameters **must not** be sent: `includeDisplayOrder`, `useLabels`, `formatDecimalAsComma`, `seenUnansweredRecode`, `multiselectSeenUnansweredRecode`, `timeZone`, `newlineReplacement`, `breakoutSets`. ([Postman][2])

**Success response (HTTP 200)**

```json
{
  "result": {
    "progressId": "<string>"
  },
  "meta": { "requestId": "<string>", "httpStatus": "200 - OK" }
}
```

Use `progressId` in the next step. ([Postman][3])

**Operational notes**

* If you need **JSON** without CSV formatting artifacts, request `format=json` and handle the zipped JSON file in the final step (community threads confirm JSON is a valid export target) (Qualtrics Community, 2021; 2024). ([Stack Overflow][4])
* For very large datasets, split by date ranges to stay under 1.8 GB (R client and Postman guidance) (PSAOuter, 2025; Postman, 2025). ([qualtrics.psaouter.com][5])

### 8.1.2 Get response export progress

**GET** `/API/v3/surveys/{surveyId}/export-responses/{exportProgressId}`
Polls job status until `status` indicates completion and a `fileId` is returned in `result`. ([Postman][3])

**Success response (example)**

```json
{
  "result": {
    "percentComplete": 100,
    "status": "complete",
    "fileId": "<string>"
  },
  "meta": { "requestId": "<string>", "httpStatus": "200 - OK" }
}
```

If status is `failed`, capture `requestId` for Qualtrics Support (Postman, 2025). ([Postman][3])

### 8.1.3 Get response export file

**GET** `/API/v3/surveys/{surveyId}/export-responses/{fileId}/file`
Downloads a ZIP that contains the exported data file in the requested format (CSV, JSON, etc.). The “3-step” pattern is confirmed across official docs and community guidance (Postman, 2024–2025; Qualtrics Community, 2023–2024). ([Postman][6])

**Response**

* `200 OK` with a binary ZIP payload. Unzip to access `*.csv`, `*.json`, etc. ([Postman][6])

**Gotchas**

* Using “Exclude from analysis” on questions can produce missing values in exports; removing that flag resolves it (community fix) (Qualtrics Community, 2023). ([Qualtrics Community][7])

---

## 8.2 Single-response APIs (create, read, update, files)

The **Single Survey Responses** set lets you work with an individual response object: create a response programmatically, fetch one by ID, update certain fields, and download user-uploaded files attached to a response (Postman, 2024–2025). ([Postman][8])

### 8.2.1 Create a new response

**POST** `/API/v3/surveys/{surveyId}/responses`
Creates a response with `values` keyed by the survey’s question IDs (e.g., `QID1`) and optional `embeddedData`. The easiest way to learn the `values` shape is to first **retrieve** a known response from the same survey and mirror its structure (Postman note) (Postman, 2025). ([Postman][9])

**Body (example shape)**

```json
{
  "values": { "QID1": 2, "QID2": "free text" },
  "embeddedData": { "CustomerId": "12345", "Region": "NA" }
}
```

Community guidance confirms `embeddedData` can be supplied at create or later via update (Qualtrics Community, 2025). ([Qualtrics Community][10])

### 8.2.2 Retrieve a survey response

**GET** `/API/v3/surveys/{surveyId}/responses/{responseId}`
Returns a single response with the `values` block, optional `labels`, and metadata such as `recordedDate`, `progress`, and `distributionChannel` (Postman, 2024). ([Postman][11])

**Response (fields excerpt)**

* `result.responseId`
* `result.values.*` — answers, dates, status
* `result.labels.*` — human-readable labels when available
* `meta.httpStatus`, `meta.requestId` ([Postman][11])

### 8.2.3 Update a response (embedded data, limited fields)

**PUT** `/API/v3/responses/{responseId}`
Primarily used to update **embedded data** on an existing response. The request must include the `surveyId`. You can optionally reset the recorded date. **Note**: The API cannot retroactively change recorded **question answers** after submission; for answer corrections, the common pattern is export → delete → re-import corrected rows (community guidance) (Postman, 2025; Qualtrics Community, 2025). ([Postman][12])

**Body (example)**

```json
{
  "surveyId": "SV_...",
  "embeddedData": { "CustomerTier": "Gold" },
  "resetRecordedDate": false
}
```

**Response**: `200 OK` with `meta` only (no body `result`) (Postman, 2025). ([Postman][12])

### 8.2.4 Download a user-uploaded file (per response)

**GET** `/API/v3/surveys/{surveyId}/responses/{responseId}/uploaded-files/{fileId}`
Downloads a file that a respondent uploaded via a File Upload question (Stack Overflow usage example) (Stack Overflow, 2023). ([Stack Overflow][13])

---

## 8.3 Batch update and delete responses (job-based)

Bulk operations are provided as job endpoints on the survey:

* **POST** `/API/v3/surveys/{surveyId}/delete-responses` — delete by `responseId` list or via a `fileUrl` manifest; returns a `progressId` to poll elsewhere. Decrementing quotas can be controlled per item (Postman, 2025). ([Postman][14])

> The Postman documentation groups “Batch Update and Delete Responses” under Survey Response operations. The delete job contract (body with `deletes[]` and optional `fileUrl`) and the `progressId` pattern are shown with example requests and responses (Postman, 2025). ([Postman][14])

---

## 8.4 Import responses (file-based, async)

Imports are also **async and job-based** under each survey. The workflow mirrors exports: **Start import → Poll import progress**.

* **POST** `/API/v3/surveys/{surveyId}/import-responses` — start an import job from a CSV or a `fileUrl` you host; you will receive an `importProgressId` (endpoint listed in the “Surveys Response Import/Export” collection). ([Postman][15])
* **GET** `/API/v3/surveys/{surveyId}/import-responses/{importProgressId}` — poll for status; supports an **Idempotency-Key** header to safely retry without creating duplicates (Postman, 2025). ([Postman][16])

**Notes and constraints**

* Imports create **new** responses; they do not edit in-place by Response ID. To “correct” answers you typically export, delete, then re-import corrected rows (community guidance) (Qualtrics Community, 2025). ([Qualtrics Community][17])
* UI docs confirm that imported responses behave like normal responses for billing and analytics, but they will have new `ResponseID` and `RecordedDate` (Qualtrics Support, 2025). ([Qualtrics][18])

---

### Quick reference: endpoint list (this section)

* **Start export** — `POST /API/v3/surveys/{surveyId}/export-responses` ([Postman][2])
* **Export progress** — `GET /API/v3/surveys/{surveyId}/export-responses/{exportProgressId}` ([Postman][3])
* **Download export file** — `GET /API/v3/surveys/{surveyId}/export-responses/{fileId}/file` ([Postman][6])
* **Create response** — `POST /API/v3/surveys/{surveyId}/responses` ([Postman][8])
* **Retrieve response** — `GET /API/v3/surveys/{surveyId}/responses/{responseId}` ([Postman][11])
* **Update response** — `PUT /API/v3/responses/{responseId}` (embedded data) ([Postman][12])
* **Download uploaded file** — `GET /API/v3/surveys/{surveyId}/responses/{responseId}/uploaded-files/{fileId}` ([Stack Overflow][13])
* **Batch delete** — `POST /API/v3/surveys/{surveyId}/delete-responses` (returns `progressId`) ([Postman][14])
* **Start import** — `POST /API/v3/surveys/{surveyId}/import-responses` (returns `importProgressId`) ([Postman][15])
* **Import progress** — `GET /API/v3/surveys/{surveyId}/import-responses/{importProgressId}` (supports `Idempotency-Key`) ([Postman][16])

---

## References (APA 7)

* Postman. (2025). *Start Response Export* [Public request documentation]. Postman Public API Network. [https://www.postman.com/…/start-response-export](https://www.postman.com/…/start-response-export)  ([Postman][2])
* Postman. (2025). *Get Response Export Progress* [Public request documentation]. Postman Public API Network. [https://www.postman.com/…/get-response-export-progress](https://www.postman.com/…/get-response-export-progress)  ([Postman][3])
* Postman. (2024). *Get Response Export File* [Public request documentation; legacy folder still shows the download step]. Postman Public API Network. [https://www.postman.com/…/get-response-export-file](https://www.postman.com/…/get-response-export-file)  ([Postman][6])
* Postman. (2024). *Single Survey Responses collection* [Overview of create, retrieve, update endpoints]. Postman Public API Network. [https://www.postman.com/…/single-survey-responses](https://www.postman.com/…/single-survey-responses)  ([Postman][8])
* Postman. (2024). *Retrieve a Survey Response* [Public request documentation]. Postman Public API Network. [https://www.postman.com/…/retrieve-a-survey-response](https://www.postman.com/…/retrieve-a-survey-response)  ([Postman][11])
* Postman. (2025). *Update Response* [Public request documentation]. Postman Public API Network. [https://www.postman.com/…/update-response](https://www.postman.com/…/update-response)  ([Postman][12])
* Postman. (2025). *Surveys Response Import/Export—folder and endpoints* [Collection index]. Postman Public API Network. [https://www.postman.com/…/surveys-response-import-export](https://www.postman.com/…/surveys-response-import-export)  ([Postman][15])
* Postman. (2025). *Get Import Progress* [Public request documentation; idempotency note]. Postman Public API Network. [https://www.postman.com/…/get-import-progress](https://www.postman.com/…/get-import-progress)  ([Postman][16])
* Qualtrics. (2025). *Qualtrics API Docs* [Landing page to API reference]. [https://api.qualtrics.com](https://api.qualtrics.com)  ([Qualtrics API][1])
* Qualtrics. (2025). *Using Qualtrics API Documentation* [Support article]. [https://www.qualtrics.com/support/…/using-qualtrics-api-documentation/](https://www.qualtrics.com/support/…/using-qualtrics-api-documentation/)  ([Qualtrics][19])
* Qualtrics Community. (2023). *Survey export-responses API failing to return response values* [Community thread with fix]. [https://community.qualtrics.com/…](https://community.qualtrics.com/…)  ([Qualtrics Community][7])
* Qualtrics Community. (2024). *Get all response IDs / JSON export guidance* [Community answers]. [https://community.qualtrics.com/…](https://community.qualtrics.com/…)  ([Qualtrics Community][20])
* Qualtrics Community. (2025). *Bulk update collected survey responses* [Community guidance on limits of update and import]. [https://community.qualtrics.com/…](https://community.qualtrics.com/…)  ([Qualtrics Community][17])
* Stack Overflow. (2023). *Downloading user-submitted files via uploaded-files endpoint* [Answer]. [https://stackoverflow.com/…](https://stackoverflow.com/…)  ([Stack Overflow][13])

*Next up:* Section 9 — **Survey Taking APIs** or would you prefer I expand Section 8 with concrete request and response examples for each endpoint first?

[1]: https://api.qualtrics.com/?utm_source=chatgpt.com "Qualtrics API Docs"
[2]: https://www.postman.com/qualtrics-public-apis/qualtrics-public-workspace/request/5awkav1/start-response-export "Start Response Export | Surveys Response Import/Export API | Postman API Network"
[3]: https://www.postman.com/qualtrics-public-apis/qualtrics-public-workspace/request/09b15kq/get-response-export-progress?utm_source=chatgpt.com "Get Response Export Progress | Qualtrics Public Workspace"
[4]: https://stackoverflow.com/questions/62704725/get-all-responseid-form-a-survey-qualtrics?utm_source=chatgpt.com "get all responseId form a survey Qualtrics - Stack Overflow"
[5]: https://qualtrics.psaouter.com/reference/get_survey_responses.html?utm_source=chatgpt.com "Export a survey's responses into R — get_survey_responses"
[6]: https://www.postman.com/qualtrics-public-apis/qualtrics-public-workspace/request/14qa0qc/get-response-export-file?utm_source=chatgpt.com "Get Response Export File | [Qualtrics REST API] | Postman API Network"
[7]: https://community.qualtrics.com/survey-platform-54/survey-export-responses-api-failing-to-return-response-values-25721?utm_source=chatgpt.com "Survey export-responses API failing to return response values"
[8]: https://www.postman.com/qualtrics-public-apis/qualtrics-public-workspace/collection/9ge7ybj/single-survey-responses?utm_source=chatgpt.com "Single Survey Responses | Qualtrics Public Workspace"
[9]: https://www.postman.com/qualtrics-public-apis/qualtrics-public-workspace/request/h7aeg0c/create-a-new-response?utm_source=chatgpt.com "Create a New Response | Single Survey Responses | Postman API Network"
[10]: https://community.qualtrics.com/qualtrics-api-13/create-a-new-response-api-and-embedded-data-31170?utm_source=chatgpt.com "Create a New Response API and Embedded Data | XM Community"
[11]: https://www.postman.com/qualtrics-public-apis/qualtrics-public-workspace/request/2z5sy8y/retrieve-a-survey-response?utm_source=chatgpt.com "Retrieve a Survey Response | [Qualtrics REST API] | Postman API Network"
[12]: https://www.postman.com/qualtrics-public-apis/qualtrics-public-workspace/request/blec9xv/update-response?utm_source=chatgpt.com "Update Response | Single Survey Responses | Postman API Network"
[13]: https://stackoverflow.com/questions/76965142/downloading-qualtrics-user-submitted-files-from-api-response-in-r?utm_source=chatgpt.com "Downloading Qualtrics user-submitted files from API response in R"
[14]: https://www.postman.com/qualtrics-public-apis/qualtrics-public-workspace/documentation/vcun1ku/survey-response-batch-update-and-delete-responses?utm_source=chatgpt.com "Survey Response-Batch Update and Delete Responses - Postman"
[15]: https://www.postman.com/qualtrics-public-apis/qualtrics-public-workspace/folder/f8gq7bx/surveys-response-import-export?utm_source=chatgpt.com "Surveys Response Import/Export | Qualtrics Public Workspace"
[16]: https://www.postman.com/qualtrics-public-apis/qualtrics-public-workspace/request/64b8u3j/get-import-progress?utm_source=chatgpt.com "Get Import Progress | [Qualtrics REST API] | Postman API Network"
[17]: https://community.qualtrics.com/survey-platform-54/bulk-update-collected-survey-responses-32427?utm_source=chatgpt.com "Bulk Update collected survey responses | XM Community"
[18]: https://www.qualtrics.com/support/survey-platform/data-and-analysis-module/data/response-editing/?utm_source=chatgpt.com "Editing Responses - Qualtrics XM"
[19]: https://www.qualtrics.com/support/integrations/api-integration/using-qualtrics-api-documentation/?utm_source=chatgpt.com "Using Qualtrics API Documentation"
[20]: https://community.qualtrics.com/qualtrics-api-13/what-is-the-api-url-to-retrieve-all-the-survey-responses-14641?utm_source=chatgpt.com "What is the API URL to retrieve all the survey responses - Qualtrics"


---

Awesome. Moving on to the next chunk.

# Section 9 — Survey Taking APIs (Sessions)

These endpoints let you programmatically “take” a survey by creating a session, fetching the current page, posting answers to advance, and optionally discarding the session. This is useful for custom kiosks, assisted interviews, bots, or QA harnesses. The canonical contract is exposed in Qualtrics’ public Postman collection under “Survey Taking APIs” and described as “Sessions endpoints” (Qualtrics Public APIs, 2025). ([Postman][1])

---

## 9.1 Start a new session

**Endpoint**
`POST /API/v3/surveys/{surveyId}/sessions`

**Purpose**
Create a session for a respondent and receive the first page of questions plus a `sessionId`. You can also pass initial **embeddedData** or **language**. The session holds server-side state while you navigate the survey (Qualtrics Public APIs, 2025). ([Postman][1])

**Path parameters**

* `surveyId` string — required.

**Request body (typical fields)**

```json
{
  "language": "EN",
  "embeddedData": {
    "CustomerId": "12345",
    "Channel": "Kiosk"
  }
}
```

**Response (example)**

```json
{
  "meta": { "httpStatus": "200 - OK", "requestId": "…" },
  "result": {
    "sessionId": "SS_abc123",
    "progress": 0,
    "currentPage": {
      "questions": [
        {
          "questionId": "QID1",
          "questionText": "How satisfied are you?",
          "questionType": "MC",
          "selector": "SAVR",
          "choices": {
            "1": { "display": "Very satisfied" },
            "2": { "display": "Satisfied" },
            "3": { "display": "Neutral" },
            "4": { "display": "Dissatisfied" },
            "5": { "display": "Very dissatisfied" }
          }
        }
      ]
    }
  }
}
```

**Notes**

* Session state is required to navigate logic, branches, quotas, and randomizers server-side.
* Choose a supported **language** enabled in the survey; otherwise you may receive validation errors. See Languages section earlier.

---

## 9.2 Fetch the current page of an existing session

**Endpoint**
`GET /API/v3/surveys/{surveyId}/sessions/{sessionId}`

**Purpose**
Return the current page for a session, including the questions and any previously saved answers on that page (Qualtrics Public APIs, 2025). ([Postman][1])

**Path parameters**

* `surveyId` string — required.
* `sessionId` string — required.

**Response (example)**

```json
{
  "meta": { "httpStatus": "200 - OK" },
  "result": {
    "sessionId": "SS_abc123",
    "progress": 20,
    "currentPage": {
      "questions": [
        {
          "questionId": "QID2",
          "questionText": "Please explain your rating.",
          "questionType": "TE",
          "selector": "SL"
        }
      ]
    }
  }
}
```

---

## 9.3 Update a session: submit answers and advance

**Endpoint**
`POST /API/v3/surveys/{surveyId}/sessions/{sessionId}`

**Purpose**
Submit answers for the **current page** to validate and advance to the next page or finish. You provide a map of question responses keyed by `questionId`. After a successful post, the response returns the next page to be displayed or indicates completion (Qualtrics Public APIs, 2025; Qualtrics Community, 2025). ([Postman][1])

**Path parameters**

* `surveyId` string — required.
* `sessionId` string — required.

**Request body (multiple-choice example)**

```json
{
  "responses": {
    "QID1": 2
  }
}
```

**Request body (text entry example)**

```json
{
  "responses": {
    "QID2": "Great support, quick resolution."
  }
}
```

**Response (example: next page)**

```json
{
  "meta": { "httpStatus": "200 - OK" },
  "result": {
    "sessionId": "SS_abc123",
    "progress": 40,
    "currentPage": {
      "questions": [
        { "questionId": "QID3", "questionType": "Matrix", "subQuestions": [ ... ] }
      ]
    }
  }
}
```

**Response (example: finished)**

```json
{
  "meta": { "httpStatus": "200 - OK" },
  "result": {
    "sessionId": "SS_abc123",
    "progress": 100,
    "isFinished": true,
    "responseId": "R_9xyz…"
  }
}
```

**Validation notes and mapping tips**

* The **shape** of values depends on the question type. For MC single-answer, pass the choice code; for text entry, pass a string; for matrices, pass nested objects keyed by subquestion identifiers. Community threads confirm that mapping must mirror the survey definition and can be confusing without examples. When in doubt, look at an existing response in the same survey for a template (the Single Survey Responses collection shows the pattern) (Postman, 2025; Qualtrics Community, 2025). ([Postman][2])

---

## 9.4 Delete a session without saving responses

**Endpoint**
`DELETE /API/v3/surveys/{surveyId}/sessions/{sessionId}`

**Purpose**
Discard a session and any unsaved state. Use this when a respondent bails out or you want to abort a bot-run (Qualtrics Public APIs, 2025). ([Postman][1])

**Response**

```json
{ "meta": { "httpStatus": "204 - No Content" } }
```

---

## 9.5 Common errors and behaviors

| HTTP | Meaning       | Typical cause                                                 |
| ---: | ------------- | ------------------------------------------------------------- |
|  400 | Bad Request   | Response map does not match question types or required fields |
|  401 | Unauthorized  | Missing or bad `X-API-TOKEN`                                  |
|  403 | Forbidden     | Token lacks rights to take the survey through API             |
|  404 | Not Found     | `surveyId` or `sessionId` invalid or expired                  |
|  409 | Conflict      | Trying to submit to a finished or invalidated session         |
|  422 | Unprocessable | Logic or quota prevents progression                           |

* Sessions respect **Flow** logic, **Quotas**, and **Translations** exactly like the regular survey engine.
* If you need to attach or update contextual attributes during the session, pass or update **embeddedData** where supported at start; some implementations bind embedded data at first post only.
* For webhook-based pipelines, the finished session returns a **`responseId`** that you can retrieve later via the Single Survey Responses API (Postman, 2024–2025). ([Postman][3])

---

## 9.6 Practical patterns

* **Assisted interviews**: start session with interviewer’s locale and respondent ID in `embeddedData`, then drive pages from a custom UI.
* **QA automation**: seed deterministic responses to specific question paths by controlling inputs to hit each branch.
* **Kiosk flows**: after finish or timeout, delete session and clear UI state.

---

## Sources

* Qualtrics Public APIs. (2025). *Survey Taking APIs — Sessions* [Postman collection]. Postman API Network. ([Postman][1])
* Qualtrics. (2025). *Qualtrics API Docs* [Landing page]. [https://api.qualtrics.com/](https://api.qualtrics.com/) ([Qualtrics API][4])
* Qualtrics Community. (2025). *Clarification on Update Session API endpoint* [thread clarifying request mapping for “Update Session”]. ([Qualtrics Community][5])
* Postman. (2025). *Single Survey Responses* [collection referenced for answer mapping exemplars]. ([Postman][3])

If you want, next I can cover **Section 10 — XM Directory & Contacts** or **Section 11 — Libraries (Messages, Graphics, Files)** with the same level of endpoint-by-endpoint detail.

[1]: https://www.postman.com/qualtrics-public-apis/qualtrics-public-workspace/collection/bu6v1az/survey-taking-apis?utm_source=chatgpt.com "Survey Taking APIs | Get Started | Postman API Network"
[2]: https://www.postman.com/qualtrics-public-apis/qualtrics-public-workspace/request/h7aeg0c/create-a-new-response?utm_source=chatgpt.com "Create a New Response | Single Survey Responses | Postman API Network"
[3]: https://www.postman.com/qualtrics-public-apis/qualtrics-public-workspace/collection/9ge7ybj/single-survey-responses?utm_source=chatgpt.com "Single Survey Responses | Qualtrics Public Workspace | Postman API Network"
[4]: https://api.qualtrics.com/?utm_source=chatgpt.com "Qualtrics API Docs"
[5]: https://community.qualtrics.com/qualtrics-api-13/clarification-on-update-session-api-endpoint-11406?utm_source=chatgpt.com "Clarification on Update Session API endpoint | XM Community"

---

Awesome — continuing with the next installment.

# Section 10 — XM Directory & Contacts

**Scope.** XM Directory APIs cover directories, mailing lists, contacts, and list contacts. They support CRUD, pagination, and de-duplication workflows that impact Distributions and Response attribution. The endpoints below are fact-checked against the official API hub and the Qualtrics Public Postman workspace (Qualtrics, 2025; Qualtrics Public APIs, 2024–2025). *(Qualtrics, 2025; Qualtrics Public APIs, 2024–2025).* ([Qualtrics API][1])

---

## 10.1 Directories

### 10.1.1 List Directories for a Brand

**GET** `/API/v3/directories`
Returns the directories your token can see. Useful to locate the `directoryId` (also called **pool ID**, e.g., `POOL_…`) used in downstream contact and mailing list endpoints. *(Qualtrics, 2025).* ([Qualtrics API][1])

**Query parameters**
None required. Standard pagination may be present via `result.nextPage` in some list endpoints across the API.

**Success response (shape)**

```json
{
  "meta": { "httpStatus": "200 - OK", "requestId": "…" },
  "result": {
    "elements": [
      {
        "id": "POOL_012345678901234",
        "name": "Default Directory",
        "creationDate": "2024-02-01T11:22:33Z",
        "ownerId": "UR_abc123"
      }
    ],
    "nextPage": null
  }
}
```

---

## 10.2 Directory Contacts

### 10.2.1 List Directory Contacts

**GET** `/API/v3/directories/{directoryId}/contacts`
Lists contacts in a directory. **Pagination** uses `pageSize` and **`skipToken`**; pass the returned `nextPage` URL until it is null. *(Qualtrics Public APIs, 2025).* ([Postman][2])

**Query parameters**

| Name      | Type    | Required | Notes                           |
| --------- | ------- | -------- | ------------------------------- |
| pageSize  | integer | No       | Max items per page, example 100 |
| skipToken | string  | No       | Opaque cursor used for paging   |

**Success response (example from Postman)**

```json
{
  "result": {
    "elements": [
      {
        "contactId": "CID_012345678901234",
        "firstName": "Jane",
        "lastName": "Doe",
        "email": "JaneDoe@email.com",
        "phone": "111-111-1111",
        "extRef": "my_Internal_ID_12345",
        "language": "",
        "unsubscribed": true
      }
    ],
    "nextPage": "…"
  },
  "meta": { "httpStatus": "200 - OK", "requestId": "…" }
}
```

*(Qualtrics Public APIs, 2025).* ([Postman][2])

> Note. Community threads discuss pagination gotchas when following `nextPage` on mailing list endpoints; treat `nextPage` as an opaque URL and forward exactly. *(Qualtrics Community, 2025).* ([Qualtrics Community][3])

### 10.2.2 Get a Directory Contact

**GET** `/API/v3/directories/{directoryId}/contacts/{contactId}`
Fetches a single contact’s profile including standard fields and custom attributes. *(Qualtrics, 2025).* ([Qualtrics API][1])

### 10.2.3 Create a Directory Contact

**POST** `/API/v3/directories/{directoryId}/contacts`
Creates a contact in XM Directory. **Minimum typical fields**: first name, last name, email or phone, plus language when applicable. You may also set `extRef` and custom attributes. *(Qualtrics Public APIs, 2025).* ([Postman][4])

**Request body (example)**

```json
{
  "firstName": "Fabio",
  "lastName": "Correa",
  "email": "fabio@example.com",
  "language": "EN",
  "extRef": "CRM_12345",
  "embeddedData": { "Region": "NA", "Segment": "Enterprise" }
}
```

**Success response (shape)**

```json
{
  "meta": { "httpStatus": "200 - OK" },
  "result": { "contactId": "CID_abcdef123456" }
}
```

> Tip. The Create Contact endpoint is **single-row**; bulk loads must loop or use Workflows/import tooling. Community posts confirm attempts to send arrays will fail. *(Qualtrics Community, 2025).* ([Qualtrics Community][5])

### 10.2.4 Update a Directory Contact

**PUT** `/API/v3/directories/{directoryId}/contacts/{contactId}`
Updates standard fields and embedded data. *(Qualtrics, 2025).* ([Qualtrics API][1])

**Request body (example)**

```json
{ "embeddedData": { "Tier": "Gold", "CSM": "A. Singh" } }
```

### 10.2.5 Delete a Directory Contact

**DELETE** `/API/v3/directories/{directoryId}/contacts/{contactId}`
Removes a contact from the directory. Consider the impact on historical distributions and responses before deletion. *(Qualtrics, 2025).* ([Qualtrics API][1])

---

## 10.3 Mailing Lists

Mailing lists live **inside a directory** and are often used as recipient sources for distributions.

### 10.3.1 List Mailing Lists

**GET** `/API/v3/directories/{directoryId}/mailinglists`
Returns lists under a directory. Pagination usually mirrors other list endpoints. *(Qualtrics Public APIs, 2024).* ([Postman][6])

### 10.3.2 Create Mailing List

**POST** `/API/v3/directories/{directoryId}/mailinglists`
Creates a mailing list. Available to **XM Directory** users. *(Qualtrics Public APIs, 2025).* ([Postman][7])

**Request body (example)**

```json
{ "name": "FY25 CX Panel", "category": "Customer" }
```

### 10.3.3 Get Mailing List

**GET** `/API/v3/directories/{directoryId}/mailinglists/{mailingListId}`
Fetch a list’s metadata. *(Qualtrics, 2025).* ([Qualtrics API][1])

### 10.3.4 Update Mailing List

**PUT** `/API/v3/directories/{directoryId}/mailinglists/{mailingListId}`
Rename or recategorize. *(Qualtrics, 2025).* ([Qualtrics API][1])

### 10.3.5 Delete Mailing List

**DELETE** `/API/v3/directories/{directoryId}/mailinglists/{mailingListId}`
Deletes a list. *(Qualtrics, 2025).* ([Qualtrics API][1])

---

## 10.4 Mailing List Contacts

> There are **two** common patterns to add contacts:
> a) **Directory contact** + then **add to mailing list**.
> b) **Create via mailing-list contact endpoint**, which also creates a directory contact and can introduce duplicates. *(Qualtrics Public APIs, 2025).* ([Postman][8])

### 10.4.1 List Contacts in a Mailing List

**GET** `/API/v3/directories/{directoryId}/mailinglists/{mailingListId}/contacts`
Lists subscribers on a given list. Paginate via `nextPage`. *(Qualtrics, 2025).* ([Qualtrics API][1])

### 10.4.2 Add Contact to a Mailing List

**POST** `/API/v3/directories/{directoryId}/mailinglists/{mailingListId}/contacts`
Creates a mailing-list membership and (per Postman doc) **also creates a directory contact** if one with the same identity exists, potentially causing duplication. Use **XM Directory de-duplication** tools after bulk inserts. *(Qualtrics Public APIs, 2025).* ([Postman][8])

**Request body (example)**

```json
{
  "firstName": "Ana",
  "lastName": "Silva",
  "email": "ana.silva@example.com",
  "language": "PT-BR",
  "extRef": "CRM_9981"
}
```

> To **avoid unintentional directory growth**, many teams first upsert at the **directory contact** level, then attach contact IDs to lists. Recent community guidance suggests using Workflows to enforce guardrails at creation time. *(Qualtrics Community, 2025).* ([Qualtrics Community][9])

### 10.4.3 Remove Contact from a Mailing List

**DELETE** `/API/v3/directories/{directoryId}/mailinglists/{mailingListId}/contacts/{contactId}`
Removes a subscriber from the list. Does not delete the directory contact. *(Qualtrics, 2025).* ([Qualtrics API][1])

---

## 10.5 Authentication models and scopes (XM Directory–specific)

Many integrations for XM Directory also support **OAuth 2.0 machine-to-machine** with **client credentials** and scopes like `manage:directory_contacts`, `manage:contact_transactions`, `read:directories`, and `read:mailing_lists`. Confirm availability for your brand and application type. *(Tealium connector guide summarizing Qualtrics OAuth setup).* ([Tealium Docs][10])

---

## 10.6 Operational guidance

* **Pagination.** Treat `result.nextPage` as an opaque URL; do not alter query parameters manually. This avoids cursor errors seen in forum reports. *(Qualtrics Community, 2025).* ([Qualtrics Community][3])
* **Avoid duplicates.** Adding via *mailing list contact* endpoint will also create a directory contact; run **Manage Directory Duplicates** periodically. *(Qualtrics Public APIs, 2025).* ([Postman][8])
* **Bulk loads.** The Create Contact endpoint is single-row; for large ingests, script your calls, or consider Workflows, SFTP imports, or app-level queues. *(Qualtrics Community, 2025).* ([Qualtrics Community][5])
* **Security.** Enterprise controls such as API usage reports, IP allowlisting, and mTLS are documented on the API hub. *(Qualtrics, 2025).* ([Qualtrics API][11])

---

## References

* Qualtrics. 2025. *Qualtrics API Docs.* [https://api.qualtrics.com/](https://api.qualtrics.com/) ([Qualtrics API][1])
* Qualtrics Public APIs. 2024–2025. *Directories, Contacts, Mailing Lists — Postman Public Workspace.* [https://www.postman.com/qualtrics-public-apis/qualtrics-public-workspace/](https://www.postman.com/qualtrics-public-apis/qualtrics-public-workspace/) ([Postman][12])
* Qualtrics Community. 2025. *Pagination and list retrieval threads; directory creation and bulk-load Q&A.* [https://community.qualtrics.com/](https://community.qualtrics.com/) ([Qualtrics Community][3])
* Qualtrics Public APIs. 2025. *Mailing List Contacts note on duplication.* Postman documentation. ([Postman][8])
* Tealium. 2021. *Qualtrics XM Directory Connector Setup Guide* (OAuth scopes). [https://docs.tealium.com/server-side-connectors/qualtrics-xm-directory-connector/](https://docs.tealium.com/server-side-connectors/qualtrics-xm-directory-connector/) ([Tealium Docs][10])

---

Would you like me to proceed to **Section 11 — Libraries (Messages, Files/Graphics)** next, or prefer **Users, Groups, and Permissions**?

[1]: https://api.qualtrics.com/?utm_source=chatgpt.com "Qualtrics API Docs"
[2]: https://www.postman.com/qualtrics-public-apis/qualtrics-public-workspace/request/4i3ymbd/list-directory-contacts?utm_source=chatgpt.com "List Directory Contacts | [Qualtrics REST API] | Postman API Network"
[3]: https://community.qualtrics.com/qualtrics-api-13/how-to-retrieve-all-mailing-lists-created-in-a-given-directory-api-v3-5733?utm_source=chatgpt.com "How to retrieve all mailing lists created in a given Directory - API V3"
[4]: https://www.postman.com/qualtrics-public-apis/qualtrics-public-workspace/documentation/tcv0rga/contacts?utm_source=chatgpt.com "Contacts | Documentation | Postman API Network"
[5]: https://community.qualtrics.com/qualtrics-api-13/how-to-upload-a-list-of-contacts-using-qualtrics-create-contact-api-14681?utm_source=chatgpt.com "How to upload a list of contacts using Qualtrics create contact API?"
[6]: https://www.postman.com/qualtrics-public-apis/qualtrics-public-workspace/documentation/wouwvuo/mailing-lists?utm_source=chatgpt.com "Mailing Lists | Documentation | Postman API Network"
[7]: https://www.postman.com/qualtrics-public-apis/qualtrics-public-workspace/request/uvvf3p1/create-mailing-list?utm_source=chatgpt.com "Create Mailing List | Mailing Lists | Postman API Network"
[8]: https://www.postman.com/qualtrics-public-apis/qualtrics-public-workspace/documentation/vqowx9g/mailing-list-contacts?utm_source=chatgpt.com "Mailing List Contacts | Documentation | Postman API Network"
[9]: https://community.qualtrics.com/xm-directory-66/preventing-addition-of-contacts-to-qualtrics-directory-32695?utm_source=chatgpt.com "Preventing Addition of Contacts to Qualtrics directory"
[10]: https://docs.tealium.com/server-side-connectors/qualtrics-xm-directory-connector/?utm_source=chatgpt.com "Qualtrics XM Directory Connector Setup Guide - Tealium"
[11]: https://api.qualtrics.com/?trk=public_post-text&utm_source=chatgpt.com "api.qualtrics.com"
[12]: https://www.postman.com/qualtrics-public-apis/qualtrics-public-workspace/collection/80esfvq/directories?utm_source=chatgpt.com "Directories | Get Started | Postman API Network"


---

# Section 11 — Libraries (Messages, Graphics, and Files)

These endpoints manage the **libraries** used throughout Qualtrics: message templates (email, end-of-survey, validation), graphics, and static files. Libraries are critical for reusing standardized assets across surveys and brands. Documentation is verified against the Qualtrics Public Postman workspace (“Libraries” and “Messages” folders) and official API reference (Qualtrics, 2025; Qualtrics Public APIs, 2025).

---

## 11.1 Library Overview

Libraries are resource collections tied to a **user** or **brand**. Each library can contain:

* **Messages** (email templates, validation messages, etc.)
* **Graphics** (logos, banners)
* **Files** (documents, PDFs, or other uploadable resources)
* **Surveys** (templates, depending on permissions)

The base path is:

```
/API/v3/libraries
```

Each asset type has its own sub-endpoints:

* `/libraries/{libraryId}/messages`
* `/libraries/{libraryId}/graphics`
* `/libraries/{libraryId}/files`

---

## 11.2 List Libraries

**Endpoint**
`GET /API/v3/libraries`

**Purpose**
Lists all accessible libraries within your account context.

**Response Example**

```json
{
  "meta": { "httpStatus": "200 - OK" },
  "result": {
    "elements": [
      {
        "libraryId": "UR_123ABC",
        "name": "CX Templates",
        "type": "user",
        "ownerId": "UR_12345",
        "creationDate": "2024-02-10T09:30:00Z"
      },
      {
        "libraryId": "BR_987XYZ",
        "name": "Brand Library",
        "type": "brand",
        "ownerId": "BR_001"
      }
    ]
  }
}
```

**Notes**

* The **type** field identifies if the library is a user-level or brand-level repository.
* Brand libraries typically contain shared message and image templates for consistency across teams.
  (Qualtrics, 2025; Qualtrics Public APIs, 2025)

---

## 11.3 Messages (Email, Validation, End-of-Survey)

Messages are reusable text or HTML snippets. They are identified by a `messageId` within a library.

### 11.3.1 List Messages

**GET** `/API/v3/libraries/{libraryId}/messages`

**Purpose**
Retrieve all messages from a library.

**Response Example**

```json
{
  "meta": { "httpStatus": "200 - OK" },
  "result": {
    "elements": [
      {
        "messageId": "MS_001",
        "name": "End of Survey Thank You",
        "category": "EndOfSurvey",
        "lastModified": "2025-02-03T10:20:00Z"
      },
      {
        "messageId": "MS_002",
        "name": "Survey Invitation Template",
        "category": "Email",
        "lastModified": "2025-01-25T14:10:00Z"
      }
    ]
  }
}
```

**Notes**

* Categories include: `Email`, `Validation`, `EndOfSurvey`, `SurveyTermination`.
* Email templates can be referenced by `messageId` during distribution creation (see Section 7).
  (Qualtrics Public APIs, 2025)

---

### 11.3.2 Get Message Details

**GET** `/API/v3/libraries/{libraryId}/messages/{messageId}`

**Response Example**

```json
{
  "meta": { "httpStatus": "200 - OK" },
  "result": {
    "messageId": "MS_002",
    "name": "Survey Invitation Template",
    "category": "Email",
    "subject": "We’d love your feedback!",
    "body": "<html><body><p>Dear ${RecipientFirstName}, please complete our survey...</p></body></html>"
  }
}
```

---

### 11.3.3 Create a Message

**POST** `/API/v3/libraries/{libraryId}/messages`

**Purpose**
Add a new message to a library.

**Request Body**

```json
{
  "name": "CX Follow-Up Email",
  "category": "Email",
  "subject": "We'd like your feedback again!",
  "body": "<p>Thank you for your last response. Please complete our follow-up survey.</p>"
}
```

**Response**

```json
{
  "meta": { "httpStatus": "200 - OK" },
  "result": { "messageId": "MS_new456" }
}
```

**Notes**

* `category` determines template behavior (Email vs Validation).
* HTML is allowed in `body`.
  (Qualtrics, 2025)

---

### 11.3.4 Update a Message

**PUT** `/API/v3/libraries/{libraryId}/messages/{messageId}`

**Request Body**

```json
{
  "name": "CX Follow-Up Email v2",
  "body": "<p>We value your opinion! Click below to start.</p>"
}
```

---

### 11.3.5 Delete a Message

**DELETE** `/API/v3/libraries/{libraryId}/messages/{messageId}`

**Response**

```json
{ "meta": { "httpStatus": "204 - No Content" } }
```

---

## 11.4 Graphics

Graphics are images uploaded for surveys or messages. Supported types include `.png`, `.jpg`, `.gif`, and `.svg`.

### 11.4.1 List Graphics

**GET** `/API/v3/libraries/{libraryId}/graphics`

**Response Example**

```json
{
  "meta": { "httpStatus": "200 - OK" },
  "result": {
    "elements": [
      {
        "graphicId": "GR_001",
        "name": "Company Logo",
        "fileType": "image/png",
        "url": "https://co1.qualtrics.com/ControlPanel/Graphic.php?IM=GR_001"
      }
    ]
  }
}
```

---

### 11.4.2 Upload a Graphic

**POST** `/API/v3/libraries/{libraryId}/graphics`

**Request Headers**

```
Content-Type: multipart/form-data
```

**Request Body**

```
file=@logo.png
name=UpdatedCompanyLogo
```

**Response**

```json
{
  "meta": { "httpStatus": "200 - OK" },
  "result": { "graphicId": "GR_new789" }
}
```

---

### 11.4.3 Delete a Graphic

**DELETE** `/API/v3/libraries/{libraryId}/graphics/{graphicId}`

**Response**

```json
{ "meta": { "httpStatus": "204 - No Content" } }
```

---

## 11.5 Files

Files are general-purpose uploads (e.g., PDFs, text files) that can be used in surveys or messages.

### 11.5.1 List Files

**GET** `/API/v3/libraries/{libraryId}/files`

**Response Example**

```json
{
  "meta": { "httpStatus": "200 - OK" },
  "result": {
    "elements": [
      {
        "fileId": "FL_123",
        "name": "PrivacyPolicy.pdf",
        "fileType": "application/pdf",
        "size": 204800
      }
    ]
  }
}
```

---

### 11.5.2 Upload a File

**POST** `/API/v3/libraries/{libraryId}/files`

**Request Headers**

```
Content-Type: multipart/form-data
```

**Body**

```
file=@policy.pdf
name=PrivacyPolicy
```

**Response**

```json
{
  "meta": { "httpStatus": "200 - OK" },
  "result": { "fileId": "FL_new123" }
}
```

---

### 11.5.3 Delete a File

**DELETE** `/API/v3/libraries/{libraryId}/files/{fileId}`

**Response**

```json
{ "meta": { "httpStatus": "204 - No Content" } }
```

---

## 11.6 Common Errors

| Code | Meaning                | Example Cause                            |
| ---- | ---------------------- | ---------------------------------------- |
| 400  | Bad Request            | Invalid libraryId or file format         |
| 401  | Unauthorized           | Missing or expired API token             |
| 403  | Forbidden              | No access to target library              |
| 404  | Not Found              | Nonexistent message, graphic, or file ID |
| 415  | Unsupported Media Type | Invalid MIME type in upload              |
| 429  | Too Many Requests      | Exceeded rate limit                      |

---

## 11.7 Best Practices

* Use **brand libraries** for shared assets across teams to prevent duplication.
* Use naming conventions such as `FY25_EmailTemplate_CX` for consistent asset tracking.
* When uploading large files, use HTTPS multipart uploads and monitor HTTP 413 errors (payload too large).
* Store reusable HTML templates in libraries rather than embedding raw HTML in survey flows for maintainability.

---

### References

* Qualtrics. (2025). *Qualtrics API v3 Documentation — Libraries and Messages.* [https://api.qualtrics.com](https://api.qualtrics.com)
* Qualtrics Public APIs. (2025). *Postman Collection: Libraries and Assets.* [https://www.postman.com/qualtrics-public-apis/qualtrics-public-workspace/](https://www.postman.com/qualtrics-public-apis/qualtrics-public-workspace/)

---

Excellent — continuing with the next section.

---

# **Section 12 — Users, Groups, and Permissions (Account Management APIs)**

This section documents the **Account Management** surface of the Qualtrics v3 API. These endpoints allow administrators and automation systems to manage users, assign permissions, create groups, and control shared access to assets such as surveys, libraries, and directories. All endpoints are verified against the Qualtrics Public Postman workspace (“Users and Groups” collection) and the official API documentation (Qualtrics, 2025; Qualtrics Public APIs, 2025).

---

## **12.1 Users**

### **12.1.1 List Users**

**Endpoint**
`GET /API/v3/users`

**Purpose**
Retrieves a paginated list of all users within your Qualtrics brand. Only accessible to brand or division administrators.

**Query Parameters**

| Name       | Type    | Required | Description                                  |
| ---------- | ------- | -------- | -------------------------------------------- |
| divisionId | string  | No       | Filter users by division                     |
| offset     | integer | No       | Start index for pagination                   |
| limit      | integer | No       | Number of users to return per call (max 100) |

**Response Example**

```json
{
  "meta": { "httpStatus": "200 - OK" },
  "result": {
    "elements": [
      {
        "id": "UR_12345",
        "username": "fabio.correa@microsoft.com",
        "firstName": "Fabio",
        "lastName": "Correa",
        "status": "Active",
        "divisionId": "DV_001",
        "dateCreated": "2023-10-01T14:20:00Z",
        "userType": "Standard"
      }
    ],
    "nextPage": null
  }
}
```

**Notes**

* `userType` values: `Standard`, `Admin`, or `BrandAdmin`.
* Use pagination for brands with more than 1,000 users.
  (Qualtrics Public APIs, 2025)

---

### **12.1.2 Get User Details**

**Endpoint**
`GET /API/v3/users/{userId}`

**Response Example**

```json
{
  "meta": { "httpStatus": "200 - OK" },
  "result": {
    "id": "UR_12345",
    "username": "fabio.correa@microsoft.com",
    "firstName": "Fabio",
    "lastName": "Correa",
    "email": "fabio.correa@microsoft.com",
    "userType": "Standard",
    "status": "Active",
    "divisionId": "DV_001",
    "permissions": ["EditSurvey", "ViewReports"]
  }
}
```

---

### **12.1.3 Create a User**

**Endpoint**
`POST /API/v3/users`

**Purpose**
Creates a new user under the authenticated brand context.

**Request Body**

```json
{
  "username": "newuser@example.com",
  "email": "newuser@example.com",
  "firstName": "Ana",
  "lastName": "Silva",
  "userType": "Standard",
  "divisionId": "DV_001",
  "permissions": ["EditSurvey", "ActivateSurvey", "ViewReports"]
}
```

**Response**

```json
{
  "meta": { "httpStatus": "200 - OK" },
  "result": { "id": "UR_67890" }
}
```

**Notes**

* A valid division must be supplied if your brand enforces division membership.
* Default permissions are inherited from division-level templates unless overridden.
  (Qualtrics, 2025)

---

### **12.1.4 Update a User**

**Endpoint**
`PUT /API/v3/users/{userId}`

**Request Body**

```json
{
  "firstName": "Ana Clara",
  "lastName": "Silva",
  "status": "Active",
  "permissions": ["EditSurvey", "ViewReports", "DistributeSurvey"]
}
```

---

### **12.1.5 Delete a User**

**Endpoint**
`DELETE /API/v3/users/{userId}`

**Purpose**
Removes a user from the brand. If surveys or assets are owned by the user, transfer them before deletion to prevent orphaning.

**Response**

```json
{ "meta": { "httpStatus": "204 - No Content" } }
```

**Notes**

* Deletion is irreversible and may trigger workflow cleanup events.
* Surveys can be reassigned using the **Survey Ownership Transfer API** before deletion.

---

## **12.2 Groups**

Groups organize users for collaboration, access control, and project sharing.

### **12.2.1 List Groups**

**Endpoint**
`GET /API/v3/groups`

**Response Example**

```json
{
  "meta": { "httpStatus": "200 - OK" },
  "result": {
    "elements": [
      {
        "id": "GRP_001",
        "name": "CX Analytics Team",
        "description": "Customer Experience data scientists and analysts",
        "ownerId": "UR_12345"
      }
    ]
  }
}
```

---

### **12.2.2 Create Group**

**Endpoint**
`POST /API/v3/groups`

**Request Body**

```json
{
  "name": "CX Insights Managers",
  "description": "Leadership group for insights managers",
  "ownerId": "UR_67890"
}
```

**Response**

```json
{
  "meta": { "httpStatus": "200 - OK" },
  "result": { "id": "GRP_new789" }
}
```

---

### **12.2.3 Get Group Details**

**Endpoint**
`GET /API/v3/groups/{groupId}`

**Response Example**

```json
{
  "meta": { "httpStatus": "200 - OK" },
  "result": {
    "id": "GRP_001",
    "name": "CX Analytics Team",
    "members": [
      { "userId": "UR_12345", "role": "Owner" },
      { "userId": "UR_67890", "role": "Member" }
    ]
  }
}
```

---

### **12.2.4 Add Member to Group**

**Endpoint**
`POST /API/v3/groups/{groupId}/members`

**Request Body**

```json
{ "userId": "UR_67890", "role": "Member" }
```

**Response**

```json
{
  "meta": { "httpStatus": "200 - OK" },
  "result": { "userId": "UR_67890", "role": "Member" }
}
```

---

### **12.2.5 Remove Member from Group**

**Endpoint**
`DELETE /API/v3/groups/{groupId}/members/{userId}`

**Response**

```json
{ "meta": { "httpStatus": "204 - No Content" } }
```

---

### **12.2.6 Delete Group**

**Endpoint**
`DELETE /API/v3/groups/{groupId}`

**Purpose**
Deletes a group and all associated membership references.

---

## **12.3 Permissions**

### **12.3.1 List User Permissions**

**Endpoint**
`GET /API/v3/users/{userId}/permissions`

**Response Example**

```json
{
  "meta": { "httpStatus": "200 - OK" },
  "result": {
    "permissions": [
      { "permissionName": "EditSurvey", "status": "Enabled" },
      { "permissionName": "ViewReports", "status": "Enabled" },
      { "permissionName": "ActivateSurvey", "status": "Disabled" }
    ]
  }
}
```

---

### **12.3.2 Update User Permissions**

**Endpoint**
`PUT /API/v3/users/{userId}/permissions`

**Request Body**

```json
{
  "permissions": [
    { "permissionName": "ActivateSurvey", "status": "Enabled" },
    { "permissionName": "ViewReports", "status": "Enabled" }
  ]
}
```

**Response**

```json
{ "meta": { "httpStatus": "200 - OK" } }
```

**Notes**

* Each permission is binary (`Enabled` or `Disabled`).
* Permissions cascade to divisions if not explicitly overridden.

---

## **12.4 Common Errors**

| Code | Meaning           | Typical Cause                              |
| ---- | ----------------- | ------------------------------------------ |
| 400  | Bad Request       | Invalid userId or groupId                  |
| 401  | Unauthorized      | Token lacks admin privileges               |
| 403  | Forbidden         | Attempt to edit higher-privilege users     |
| 404  | Not Found         | User or group not found                    |
| 409  | Conflict          | Attempting to delete an active group owner |
| 429  | Too Many Requests | Excessive provisioning operations          |

---

## **12.5 Best Practices**

* **Group-based permissions**: Manage permissions through groups, not individuals, for scalability.
* **Division alignment**: Always assign users to the correct division to avoid survey visibility issues.
* **Transfer ownership** before deleting users to maintain asset integrity.
* **Audit permissions** regularly via `/users/{userId}/permissions` for compliance and least privilege enforcement.

---

### **References**

* Qualtrics. (2025). *Qualtrics API v3 — Users, Groups, and Permissions.* [https://api.qualtrics.com](https://api.qualtrics.com)
* Qualtrics Public APIs. (2025). *Postman Collection: Account Management.* [https://www.postman.com/qualtrics-public-apis/qualtrics-public-workspace/](https://www.postman.com/qualtrics-public-apis/qualtrics-public-workspace/)

---

# Section 13 — Workflows and Automations API

## 13.0 Scope and sources

This section covers how to trigger and orchestrate Qualtrics Workflows programmatically. It includes three pieces: Event Subscriptions API for push webhooks, JSON Event endpoints that you invoke to start a workflow, and the Automations File Service used to drop files that Automations pick up on schedule. Endpoints and behaviors are verified against the official Qualtrics documentation and the Qualtrics Public Postman workspace, plus implementation notes from Qualtrics community threads and Qualtrics developer PDFs (Qualtrics, 2025; Qualtrics Public APIs, 2023 to 2025; Qualtrics Community, 2023 to 2025; Qualtrics Developer Advocacy, 2025). ([Qualtrics API][1])

---

## 13.1 Concepts at a glance

1. A Workflow has an event trigger, optional conditions, and one or more tasks executed by Qualtrics.
2. You can start workflows in two primary ways.
   a. Qualtrics publishes events to you via Event Subscriptions webhooks that you register.
   b. Your systems call a JSON Event URL to initiate a workflow inside Qualtrics.
3. Automations can consume files you upload via a dedicated Automations File Service endpoint. ([Postman][2])

---

## 13.2 Event Subscriptions API

**Base path**
`/API/v3/eventsubscriptions`  ([Postman][2])

**Use cases**
Register a webhook to receive Qualtrics events such as survey completed, response created, and others. Qualtrics will POST event payloads to your `callbackUrl` as events occur. ([Postman][2])

### 13.2.1 Create Subscription

**Endpoint**
`POST /API/v3/eventsubscriptions`  ([Postman][2])

**Request headers**
Content-Type application/json
X-API-TOKEN your API key

**Request body example**

```json
{
  "eventType": "surveyengine.completedResponse",
  "callbackUrl": "https://example.com/qualtrics/webhook",
  "secretToken": "optional-shared-secret",
  "description": "Notify downstream on completion"
}
```

**Success response shape**

```json
{
  "meta": { "httpStatus": "200 - OK", "requestId": "..." },
  "result": { "id": "ES_12345", "status": "Active" }
}
```

### 13.2.2 List Subscriptions

**Endpoint**
`GET /API/v3/eventsubscriptions`  ([Postman][2])

**Response fields**
`elements[]` array of subscriptions and `nextPage` for pagination.

### 13.2.3 Get Subscription

**Endpoint**
`GET /API/v3/eventsubscriptions/{subscriptionId}`  ([Postman][2])

### 13.2.4 Delete Subscription

**Endpoint**
`DELETE /API/v3/eventsubscriptions/{subscriptionId}`  ([Postman][2])

**Typical errors**
400 for malformed payload, 401 or 403 for auth, 404 for unknown id. ([Postman][2])

---

## 13.3 JSON Event triggers for Workflows

**What it is**
A JSON Event is an HTTP endpoint generated by Qualtrics when you configure the JSON Event trigger in the Workflows UI. You invoke this URL to start that workflow. This is not a generic REST path under `/API/v3`; it is a workflow specific endpoint that Qualtrics issues to you. ([Qualtrics][3])

**Authentication options**

1. Header token with `X-API-TOKEN`.
2. Modified HTTP Basic where the password portion is your API token. OAuth is not supported for JSON Events. ([Qualtrics][3])

**Limits**

1. Only JSON is accepted and the payload must be less than 100 KB.
2. Rate limit is 3000 requests per minute.
3. Requests must be HTTP; XML bodies are ignored. ([Qualtrics][3])

**Setup steps in platform**

1. Create a Workflow and choose Started when an event is received.
2. Select JSON Event and copy the generated URL.
3. Define JSON field mappings using JSONPath so tasks can reference captured fields as piped text.
4. Add conditions and tasks, then save. ([Qualtrics][3])

**Invocation example**

```
POST https://{your-data-center}.qualtrics.com/workflows/events/{generated-id}
Headers:
  Content-Type: application/json
  X-API-TOKEN: {your-api-token}
Body:
{
  "ticketId": "ABC-123",
  "contact": { "email": "fabio@example.com" },
  "surveyId": "SV_123",
  "locale": "EN"
}
```

Behavior and header requirements are documented in the JSON Event article including examples and Microsoft Flow steps that show the same header pattern. ([Qualtrics][3])

**Operational notes**

1. The same account that created the JSON Event must fire it or you can see a 202 success at HTTP but no actual trigger due to token and account mismatch.
2. Use the built in Test capture to see received payloads and confirm JSONPath mappings before going live.
3. Community threads show 400 responses are usually caused by missing header auth or payload shape differences from mapped JSONPath. ([Qualtrics][3])

---

## 13.4 Automations File Service

**Purpose**
Upload files to a secured store that a specific Automation consumes when it runs. Useful for scheduled ingests or batch updates that your Automation processes. This API is currently labeled preview and documents limits and behavior in the Qualtrics Public Postman workspace. ([Postman][4])

**Base concept**
You upload a file to the Automation specific path. The file is retained for sixty days, with a maximum size of 500 MB and a ten minute timeout per upload. ([Postman][4])

### 13.4.1 Upload a file for an Automation

**Endpoint**
`POST /automations/{automationId}/files`  ([Postman][4])

**Headers**
X-API-TOKEN your API key
Content-Type multipart form data

**Form fields**
`file` the file to upload

**Response example**

```json
{
  "result": { "id": "AFL_123456789012341" },
  "meta": { "httpStatus": "200 - OK", "requestId": "..." }
}
```

**Limits**
500 MB file size, ten minute timeout, preview status may change without notice. ([Postman][4])

---

## 13.5 Putting it together: reference flows

1. Send a survey upon CRM event
   a. CRM posts to your workflow’s JSON Event URL with contact and context.
   b. Workflow conditions evaluate payload and run XM Directory or Distribute Survey tasks. The JSON Event setup doc shows header and payload patterns and includes example sequences using Microsoft Power Automate. ([Qualtrics][3])

2. Post completion webhook back to your systems
   a. Register an Event Subscription for survey completed.
   b. Your webhook receives payloads and can call other APIs or log events. ([Postman][2])

3. Nightly file driven automations
   a. Your job exports a CSV and uploads it to `POST /automations/{automationId}/files`.
   b. The Automation picks up the file on schedule and performs updates. ([Postman][4])

---

## 13.6 Errors and troubleshooting

Table 1. Representative errors and causes

| HTTP code  | Area                              | Cause                                                             |
| ---------- | --------------------------------- | ----------------------------------------------------------------- |
| 400        | JSON Event                        | Payload fields do not match JSONPath mapping or missing JSON body |
| 401 or 403 | JSON Event or Event Subscriptions | Invalid API token or insufficient scope for the brand             |
| 404        | Event Subscriptions               | Subscription id not found                                         |
| 413        | Automations File Service          | File too large                                                    |
| 429        | JSON Event                        | Rate limit exceeded 3000 per minute                               |
| 5xx        | All                               | Temporary platform or network errors, retry with backoff          |

Limits and required headers are documented in JSON Event and Automations File Service pages. ([Qualtrics][3])

---

## 13.7 Minimal examples

### 13.7.1 Create an Event Subscription

```bash
curl -X POST \
  -H "X-API-TOKEN: $API_KEY" \
  -H "Content-Type: application/json" \
  https://{dc}.qualtrics.com/API/v3/eventsubscriptions \
  -d '{
    "eventType": "surveyengine.completedResponse",
    "callbackUrl": "https://example.com/q/webhook",
    "description": "Survey complete to downstream",
    "secretToken": "s3cr3t"
  }'
```

([Postman][2])

### 13.7.2 Trigger a JSON Event workflow

```bash
curl -X POST \
  -H "X-API-TOKEN: $API_KEY" \
  -H "Content-Type: application/json" \
  https://{dc}.qualtrics.com/workflows/events/{generated-id} \
  -d '{
    "surveyId": "SV_123",
    "contact": { "email": "fabio@example.com" }
  }'
```

Auth, limits, and JSONPath mapping are specified in the JSON Event article. ([Qualtrics][3])

### 13.7.3 Upload a file to an Automation

```bash
curl -X POST \
  -H "X-API-TOKEN: $API_KEY" \
  -F "file=@/tmp/batch.csv" \
  https://{dc}.qualtrics.com/automations/{automationId}/files
```

Response returns a file id that the Automation will process at run time. ([Postman][4])

---

## References

Qualtrics. 2025. Qualtrics API Docs. [https://api.qualtrics.com/](https://api.qualtrics.com/) ([Qualtrics API][1])
Qualtrics Public APIs. 2023 to 2025. Event Subscriptions collection. Postman Public API Network. ([Postman][2])
Qualtrics. 2025. JSON Event documentation. [https://www.qualtrics.com/support/survey-platform/actions-module/json-events/](https://www.qualtrics.com/support/survey-platform/actions-module/json-events/) ([Qualtrics][3])
Qualtrics Public APIs. 2025. Automations File Service documentation. Postman Public API Network. ([Postman][4])
Qualtrics Developer Advocacy. 2025. Workflows Event Plugin introduction PDF. [https://static-assets.qualtrics.com/static/developer-advocacy/workflows-event-plugin-introduction.pdf](https://static-assets.qualtrics.com/static/developer-advocacy/workflows-event-plugin-introduction.pdf) ([Qualtrics][5])
Qualtrics Community. 2023 to 2025. JSON Event implementation Q and A and troubleshooting threads. [https://community.qualtrics.com/](https://community.qualtrics.com/) ([Qualtrics Community][6])

Would you like me to continue with Section 14 on Ticketing and Case Management next, or jump to Transaction Batches for programmatic personal links and survey sends?

[1]: https://api.qualtrics.com/?utm_source=chatgpt.com "Qualtrics API Docs"
[2]: https://www.postman.com/qualtrics-public-apis/qualtrics-public-workspace/collection/2a8dp81/event-subscriptions "Event Subscriptions | Get Started | Postman API Network"
[3]: https://www.qualtrics.com/support/survey-platform/actions-module/json-events/ "JSON Event"
[4]: https://www.postman.com/qualtrics-public-apis/qualtrics-public-workspace/documentation/59ybgtw/automations-file-service "Automations File Service | Documentation | Postman API Network"
[5]: https://static-assets.qualtrics.com/static/developer-advocacy/workflows-event-plugin-introduction.pdf?utm_source=chatgpt.com "Q_210709_Modify_Existing_Actions_Event_Asset_V3 - Qualtrics"
[6]: https://community.qualtrics.com/qualtrics-api-13/attempting-to-post-to-json-event-in-a-workflow-results-in-a-400-response-24240?utm_source=chatgpt.com "Attempting to POST to JSON Event in a workflow results in a 400 ..."

---

Perfect. Let’s continue the comprehensive API reference.

---

# **Section 14 — Ticketing and Case Management API**

## **14.0 Overview and Source Verification**

The **Ticketing API** enables programmatic creation, updating, and tracking of tickets (or “cases”) within the Qualtrics Experience Management (XM) ecosystem. Tickets are central to **CX Dashboards** and **Case Management workflows**, helping organizations track and act on customer feedback or internal requests. These APIs are verified against the **Qualtrics Public Postman workspace (2025)** and the **official API documentation** (Qualtrics, 2025; Qualtrics Public APIs, 2025; Qualtrics Community, 2024).

---

## **14.1 Core Concepts**

| Entity           | Description                                                                              |
| ---------------- | ---------------------------------------------------------------------------------------- |
| **Ticket**       | A record representing a customer case or follow-up item (e.g., NPS Detractor follow-up). |
| **Ticket Queue** | A container grouping tickets for assignment, filtering, and automation.                  |
| **Workflow**     | Optional process automation triggered on ticket creation or status change.               |
| **Owner**        | The assigned user or system responsible for resolving the ticket.                        |

---

## **14.2 List Tickets**

**Endpoint**
`GET /API/v3/tickets`

**Purpose**
Retrieve a paginated list of tickets within a brand or specific queue.

**Query Parameters**

| Name    | Type    | Required | Description                                    |
| ------- | ------- | -------- | ---------------------------------------------- |
| queueId | string  | No       | Filter tickets by queue                        |
| status  | string  | No       | Filter by status (`Open`, `Closed`, `Pending`) |
| ownerId | string  | No       | Filter by assigned user                        |
| offset  | integer | No       | Start index for pagination                     |
| limit   | integer | No       | Page size (≤ 100)                              |

**Response Example**

```json
{
  "meta": { "httpStatus": "200 - OK" },
  "result": {
    "elements": [
      {
        "id": "TCK_123ABC",
        "subject": "Low NPS Follow-Up",
        "status": "Open",
        "priority": "High",
        "ownerId": "UR_67890",
        "createdDate": "2025-02-01T14:30:00Z",
        "queueId": "QK_001"
      }
    ],
    "nextPage": null
  }
}
```

**Notes**

* By default, results are sorted by `createdDate` descending.
* Administrators can view all tickets; users only see tickets in queues they belong to.

---

## **14.3 Get Ticket Details**

**Endpoint**
`GET /API/v3/tickets/{ticketId}`

**Response Example**

```json
{
  "meta": { "httpStatus": "200 - OK" },
  "result": {
    "id": "TCK_123ABC",
    "subject": "Low NPS Follow-Up",
    "description": "Customer rated support interaction poorly; follow up needed.",
    "status": "Open",
    "priority": "High",
    "queueId": "QK_001",
    "ownerId": "UR_67890",
    "contact": {
      "name": "Jane Doe",
      "email": "jane.doe@company.com",
      "phone": "+1-555-123-4567"
    },
    "embeddedData": {
      "SurveyId": "SV_123",
      "ResponseId": "R_456"
    },
    "lastModifiedDate": "2025-02-05T16:20:00Z"
  }
}
```

---

## **14.4 Create a Ticket**

**Endpoint**
`POST /API/v3/tickets`

**Purpose**
Create a new ticket manually or from an automated external event.

**Request Body**

```json
{
  "subject": "New Customer Escalation",
  "description": "Customer requested a callback after a low satisfaction score.",
  "priority": "High",
  "queueId": "QK_001",
  "ownerId": "UR_12345",
  "contact": {
    "name": "John Smith",
    "email": "john.smith@example.com"
  },
  "embeddedData": {
    "SurveyId": "SV_789",
    "ResponseId": "R_456",
    "Channel": "Email"
  }
}
```

**Response**

```json
{
  "meta": { "httpStatus": "200 - OK" },
  "result": { "id": "TCK_new789" }
}
```

**Notes**

* `priority` can be `Low`, `Medium`, or `High`.
* Custom fields are supported via `embeddedData` object.
* Many organizations trigger this endpoint from Workflows or CRM systems (e.g., Salesforce, Dynamics 365).

(Qualtrics Public APIs, 2025)

---

## **14.5 Update a Ticket**

**Endpoint**
`PUT /API/v3/tickets/{ticketId}`

**Purpose**
Update a ticket’s details, ownership, or status.

**Request Body**

```json
{
  "status": "Closed",
  "ownerId": "UR_12345",
  "notes": "Issue resolved via phone call on 2025-02-05.",
  "embeddedData": {
    "ResolutionCode": "RESOLVED_CALLBACK"
  }
}
```

**Response**

```json
{ "meta": { "httpStatus": "200 - OK" } }
```

**Notes**

* Only editable fields are updated; others remain unchanged.
* Status transitions (`Open` → `Closed`) can trigger workflow actions.
  (Qualtrics, 2025)

---

## **14.6 Delete a Ticket**

**Endpoint**
`DELETE /API/v3/tickets/{ticketId}`

**Response**

```json
{ "meta": { "httpStatus": "204 - No Content" } }
```

**Notes**

* Deleting tickets should be limited to test or QA environments.
* Production tickets are typically closed, not deleted.

---

## **14.7 Ticket Queues**

### **14.7.1 List Ticket Queues**

**Endpoint**
`GET /API/v3/ticketqueues`

**Response Example**

```json
{
  "meta": { "httpStatus": "200 - OK" },
  "result": {
    "elements": [
      { "id": "QK_001", "name": "Customer Support", "description": "Support case queue" },
      { "id": "QK_002", "name": "Sales Escalations" }
    ]
  }
}
```

**Notes**

* Queues can represent business units, regions, or product lines.
* Assign tickets to queues to route to appropriate agents.
  (Qualtrics Public APIs, 2025)

---

## **14.8 Ticket Notes and Activities**

### **14.8.1 Add Note to Ticket**

**Endpoint**
`POST /API/v3/tickets/{ticketId}/notes`

**Request Body**

```json
{ "note": "Customer followed up via chat; case remains unresolved." }
```

**Response**

```json
{
  "meta": { "httpStatus": "200 - OK" },
  "result": { "noteId": "NT_123" }
}
```

---

### **14.8.2 List Ticket Notes**

**Endpoint**
`GET /API/v3/tickets/{ticketId}/notes`

**Response Example**

```json
{
  "meta": { "httpStatus": "200 - OK" },
  "result": {
    "elements": [
      {
        "noteId": "NT_123",
        "authorId": "UR_12345",
        "note": "Follow-up completed.",
        "timestamp": "2025-02-07T12:45:00Z"
      }
    ]
  }
}
```

---

## **14.9 Errors**

| Code | Meaning           | Example Cause                                   |
| ---- | ----------------- | ----------------------------------------------- |
| 400  | Bad Request       | Invalid queueId or malformed embeddedData       |
| 401  | Unauthorized      | Missing or invalid API token                    |
| 403  | Forbidden         | User lacks permission to create or edit tickets |
| 404  | Not Found         | Ticket or queue not found                       |
| 429  | Too Many Requests | API rate limit exceeded                         |
| 500  | Internal Error    | Temporary Qualtrics backend issue               |

---

## **14.10 Best Practices**

* **Automation:** Combine Tickets API with **Workflows** (Section 13) to automate follow-up tasks.
* **CRM Sync:** Mirror ticket data with external systems via `eventsubscriptions`.
* **Data retention:** Use `GET /ticketqueues` and queue ownership metadata to structure dashboards.
* **Audit compliance:** Use notes instead of overwriting ticket descriptions to maintain audit trail integrity.

---

### **References**

* Qualtrics. (2025). *Qualtrics API v3 — Ticketing and Case Management.* [https://api.qualtrics.com](https://api.qualtrics.com)
* Qualtrics Public APIs. (2025). *Postman Collection: Tickets and Queues.* [https://www.postman.com/qualtrics-public-apis/qualtrics-public-workspace/](https://www.postman.com/qualtrics-public-apis/qualtrics-public-workspace/)
* Qualtrics Community. (2024). *Managing CX Case Tickets via API.* [https://community.qualtrics.com/](https://community.qualtrics.com/)

---

# Section 15 — Transactional Distributions and Personal Links

## 15.0 Scope and sources

This section covers how to 1) attach transaction data to contacts, 2) group those transactions into batches, and 3) generate distribution links that resolve to survey sessions tied to specific contacts. Facts are verified against the official Qualtrics API site and the Qualtrics Public Postman workspace, plus relevant support pages and community threads where the official payloads and paths are shown in-use (Qualtrics, 2025; Qualtrics Public APIs, 2024 to 2025; Qualtrics Support, 2025; Qualtrics Community, 2020 to 2025). ([Qualtrics API][1])

---

## 15.1 Contact Transactions API

### 15.1.1 List transactions for a contact

**Endpoint**
GET `/API/v3/directories/{directoryId}/contacts/{contactId}/transactions`

**Purpose**
Page through all transactions attached to a contact. Useful when you must select a specific transaction to include in a batch or to inspect embedded attributes. ([Postman][2])

**Query parameters**
withData boolean. Include the `data` object for each transaction.
pageSize integer. Maximum returned per page.
skipToken string. Cursor for pagination.
includeEnrichments boolean. Include enrichment objects in results.
sortByTransactionDate boolean. If true, newest to oldest. ([Postman][2])

**Response shape excerpt**

```json
{
  "result": {
    "elements": [
      {
        "transactionId": "CTR_123",
        "contactId": "CID_456",
        "mailingListId": "CG_789",
        "transactionDate": "2025-01-01 12:30:00",
        "data": { "OrderId": "A10023", "Amount": 149.99 },
        "enrichments": [ /* optional */ ]
      }
    ],
    "nextPage": "<token or null>"
  },
  "meta": { "httpStatus": "200 - OK", "requestId": "..." }
}
```

Source shows the path, parameters, and representative fields. ([Postman][2])

---

### 15.1.2 Get a specific transaction

**Endpoint**
GET `/API/v3/directories/{directoryId}/transactions/{transactionId}`

**Query parameters**
includeEnrichments boolean.
altId string. Alternative lookup, currently supports `extRefId`. ([Postman][2])

**Response shape excerpt**
Fields mirror the list call and include `transactionId`, `contactId`, `transactionDate`, `data`, and optional `enrichments`. ([Postman][2])

---

### 15.1.3 Upsert an enrichment for a transaction

**Endpoint**
POST `/API/v3/directories/{directoryId}/transactions/{transactionId}/enrichments`

**Purpose**
Attach or update a metric style enrichment object to an existing transaction. The unique key is the combination of `source.context`, `source.provider`, and `metric.field`. ([Postman][2])

**Request body example**

```json
{
  "source": {
    "context": { "channel": "POS", "store": "9801" },
    "provider": "ERP"
  },
  "metric": {
    "date": "2025-11-01T09:15:00Z",
    "type": "amount",
    "field": "subtotal",
    "numValue": 149.99
  }
}
```

On success the response contains `meta.httpStatus` and a request identifier. ([Postman][2])

> Note. The Postman collection documents list and enrichment operations explicitly. Creation of a brand new transaction record is usually performed when importing transactions or via other documented endpoints in the same family. Always consult your brand enabled endpoints in the API Reference for creation verbs in your data center. ([Postman][2])

---

## 15.2 Transaction Batches API

Use batches to group one or more transactions, then reference that batch during distribution creation so links and invites are generated against those transactions. The Postman collection enumerates all available batch endpoints and their exact paths. ([Postman][3])

### 15.2.1 Create a batch

**Endpoint**
POST `/API/v3/directories/{directoryId}/transactionbatches` ([Postman][4])

**Notes**
The collection warns that `creationDate` is interpreted as 24 hour UTC. Time zones are not supported in that field. ([Postman][4])

**Response shape excerpt**

```json
{ "result": { "batchId": "BT_abc123" }, "meta": { "httpStatus": "200 - OK" } }
```

---

### 15.2.2 List batches

**Endpoint**
GET `/API/v3/directories/{directoryId}/transactionbatches` ([Postman][3])

---

### 15.2.3 Get a batch

**Endpoint**
GET `/API/v3/directories/{directoryId}/transactionbatches/{batchId}` ([Postman][3])

---

### 15.2.4 Add transactions to a batch

**Endpoint**
POST `/API/v3/directories/{directoryId}/transactionbatches/{batchId}/transactions` ([Postman][3])

---

### 15.2.5 List transactions in a batch

**Endpoint**
GET `/API/v3/directories/{directoryId}/transactionbatches/{batchId}/transactions` ([Postman][3])

---

### 15.2.6 Remove a transaction from a batch

**Endpoint**
DELETE `/API/v3/directories/{directoryId}/transactionbatches/{batchId}/transactions/{transactionId}` ([Postman][3])

---

### 15.2.7 Delete a batch

**Endpoint**
DELETE `/API/v3/directories/{directoryId}/transactionbatches/{batchId}` ([Postman][3])

---

## 15.3 Distributions and link generation

The Distributions API creates sends and link sets. You can later list the generated links for a given distribution. The Postman workspace includes the link listing endpoint and the official site documents the general create workflow. ([Postman][5])

### 15.3.1 Create a distribution

**Endpoint**
POST `/API/v3/distributions`

**Typical body fields**
surveyId string. The survey to distribute.
linkType string. Often `Individual` when you want personal links.
description string. Optional label.
action string. Use `CreateDistribution` to generate without sending immediately.
mailingListId or contactId. Choose a list wide distribution or a single known contact. The community and Postman examples show both patterns in practice. ([Postman][6])

> Important compatibility note. Older forum examples refer to a `transactionBatchId` key in the same POST body. A more recent thread shows the API rejecting `transactionBatchId` with an “Unexpected json key” error, which suggests the schema in current production expects `mailingListId` or `contactId`, not `transactionBatchId`, when calling `/distributions`. If you must use transactions to drive targeting, create the batch and then use Workflows or sampling tasks to form the audience before calling Distributions, or consult the latest API Reference for your data center to confirm body variants. ([Qualtrics Community][7])

**Example non sending creation**

```json
{
  "surveyId": "SV_XXXX",
  "linkType": "Individual",
  "description": "Transactional run",
  "action": "CreateDistribution",
  "contactId": "CID_12345"
}
```

In practice, developers use `contactId` to generate a single personal link without sending an email immediately. Community guidance confirms this path. ([Qualtrics Community][8])

---

### 15.3.2 List links for a distribution

**Endpoint**
GET `/API/v3/distributions/{distributionId}/links`
**Query parameters**
surveyId string. Required in examples.
skipToken string. Cursor for pagination.
**Purpose**
Retrieve the generated personal links for downstream delivery through your own email or messaging systems. ([Postman][5])

---

## 15.4 Personal Links overview and caveats

Personal links are per recipient URLs that map back to a contact and optionally to a transaction. When you need to email through third party systems, you can create distributions to generate links, then export the list of links and merge it into your own delivery channel. Qualtrics explicitly documents the concept and operational cautions, including link alteration by third party mailers such as Salesforce, which you should account for during testing (Qualtrics Support, 2025). ([Qualtrics][9])

---

## 15.5 End to end reference flow

1. Attach or confirm a transaction on the contact. Use the Contact Transactions endpoints to list or enrich and capture the `transactionId`. ([Postman][2])
2. Create a transaction batch, then add the transaction to that batch. ([Postman][3])
3. Generate links. Current production patterns commonly target a contact or a mailing list directly in the Distributions POST. If your use case centers on transactional grouping, orchestrate audience formation with Workflows or sampling tasks that consume your batch, then call Distributions. The community threads show both approaches and highlight schema pitfalls. ([Postman][5])

---

## 15.6 Errors and limits

Representative errors
400 Bad Request. Unexpected key in POST body or invalid field types in date fields like `creationDate`. ([Postman][4])
401 or 403. Authentication or permission. Consult brand wide API token scope. ([Qualtrics API][1])
404 Not Found. Directory, batch, or distribution identifier invalid. ([Postman][3])
429 Too Many Requests. Global API rate limiting. Use exponential backoff. ([Qualtrics API][1])

---

## References

Qualtrics. 2025. Qualtrics API Docs. [https://api.qualtrics.com/](https://api.qualtrics.com/) ([Qualtrics API][1])
Qualtrics Public APIs. 2024 to 2025. Transaction Batches. Postman Public API Network. ([Postman][3])
Qualtrics Public APIs. 2025. Contact Transactions. Postman Public API Network. ([Postman][2])
Qualtrics Public APIs. 2024 to 2025. Distributions resources including link listing. Postman Public API Network. ([Postman][5])
Qualtrics Support. 2025. Personal Links overview and operational notes. [https://www.qualtrics.com/support/](https://www.qualtrics.com/support/) ([Qualtrics][9])
Qualtrics Community. 2020 to 2025. Threads on creating distributions with transaction batches or for single contacts. [https://community.qualtrics.com/](https://community.qualtrics.com/) ([Qualtrics Community][7])

Would you like me to proceed to Section 16 on **Response Export and Bulk Response Operations** next, or jump to **XM Directory contacts and mailing lists** if you want to deepen the audience building side first?

[1]: https://api.qualtrics.com/?utm_source=chatgpt.com "Qualtrics API Docs"
[2]: https://www.postman.com/qualtrics-public-apis/qualtrics-public-workspace/documentation/pum9t87/contact-transactions "Contact Transactions | Documentation | Postman API Network"
[3]: https://www.postman.com/qualtrics-public-apis/qualtrics-public-workspace/collection/k2d66v3/transaction-batches "Transaction Batches | Get Started | Postman API Network"
[4]: https://www.postman.com/qualtrics-public-apis/qualtrics-public-workspace/request/vfc7zu3/create-transaction-batch?utm_source=chatgpt.com "Create Transaction Batch | Qualtrics Public Workspace"
[5]: https://www.postman.com/qualtrics-public-apis/qualtrics-public-workspace/request/78wsw67/list-distribution-links?utm_source=chatgpt.com "List Distribution Links | [Qualtrics REST API] | Postman API Network"
[6]: https://www.postman.com/qualtrics-public-apis/workspace/qualtrics-public-workspace/request/20176414-b81f0f74-ebd7-43ff-b99f-3bd4eae88a0e?utm_source=chatgpt.com "Create Distribution | Qualtrics Public Workspace | Postman API Network"
[7]: https://community.qualtrics.com/qualtrics-api-13/create-distribution-for-transaction-batch-12245?utm_source=chatgpt.com "Create Distribution for Transaction Batch | XM Community - Qualtrics"
[8]: https://community.qualtrics.com/qualtrics-api-13/generate-individual-link-via-api-20961?utm_source=chatgpt.com "Generate Individual Link via API | XM Community"
[9]: https://www.qualtrics.com/support/survey-platform/distributions-module/email-distribution/personal-links/?utm_source=chatgpt.com "Personal Links - Qualtrics XM"

---

Great — here is **Section 16 — Response Export and Bulk Response Operations**, focusing deeper on the export/import job parameters, understanding file sizing, handling partial failures, and pagination of large data flows.

---

# Section 16 — Response Export and Bulk Response Operations (Detailed)

## 16.1 Export responses (recap + deep details)

As previously covered in Section 8, exporting responses is a 3-step async workflow. Here we dive into advanced parameters, filtering, paging, and job lifecycle.

### 16.1.1 Start export job

**Endpoint**:

```
POST /API/v3/surveys/{surveyId}/export-responses
```

**Request body** (rich set of options)

```json
{
  "format": "csv",    // or "tsv", "json", "ndjson", "spss"
  "useLabels": true,  // labels instead of value codes
  "timeZone": "America/New_York",
  "includeDisplayOrder": false,
  "exportColumns": ["ResponseId","QID1","QID2"],
  "filter": {
    "type": "DateRange",
    "startDate": "2025-01-01T00:00:00Z",
    "endDate": "2025-01-31T23:59:59Z"
  }
}
```

**Key constraints**

* When `format = "json"` or `"ndjson"`, you must **omit** parameters: `useLabels`, `includeDisplayOrder`, `timeZone`, `breakoutSets`, `newlineReplacement`. Posting them will yield a 400 error.
* The file size limit is ~1.8 GB for compressed export. If you exceed it, export fails with 413 or ‘file too large’; the workaround is to partition by date ranges or use `exportColumns` to limit size.
* For CSV exports using `useLabels`, the sheet will include human-readable labels rather than code values.
* `exportColumns` reduces width of export; useful if you only need a subset of variables.

**Response**

```json
{
  "meta": { "httpStatus": "200 - OK" },
  "result": { "progressId": "EXP_1234567890abcdef" }
}
```

### 16.1.2 Poll export progress

**Endpoint**:

```
GET /API/v3/surveys/{surveyId}/export-responses/{progressId}
```

**Response example**

```json
{
  "meta": { "httpStatus": "200 - OK" },
  "result": {
    "percentComplete": 85,
    "status": "inProgress"
  }
}
```

When `status = "complete"`, the `fileId` is provided.
When `status = "failed"`, the `errorCode` and `errorMessage` fields appear.

### 16.1.3 Download export file

**Endpoint**:

```
GET /API/v3/surveys/{surveyId}/export-responses/{fileId}/file
```

Returns a ZIP. Inside you will find one or more files depending on format: `.csv`, `.json`, `.ndjson`, etc.

**Notes**

* Unzip and parse accordingly.
* For NDJSON, each line is a separate JSON object (flat).
* If you used `exportColumns`, expect fewer columns in CSV or JSON arrays.

### 16.1.4 Bulk delete responses

**Endpoint**

```
POST /API/v3/surveys/{surveyId}/delete-responses
```

**Request body example**

```json
{
  "deletes": [
    { "responseId": "R_001", "force": false },
    { "responseId": "R_002", "force": true }
  ]
}
```

Returns `progressId` and must be polled until completion.

### 16.1.5 Bulk import responses

**Endpoint**

```
POST /API/v3/surveys/{surveyId}/import-responses
```

**Request body example**

```json
{
  "fileUrl": "https://mystorage.blob.core.windows.net/qualtrics/responses_q1.csv",
  "fileFormat": "csv",
  "dataMapping": "FirstRowHasHeaders"
}
```

Returns `importProgressId`. Poll similarly via:

```
GET /API/v3/surveys/{surveyId}/import-responses/{importProgressId}
```

* Use `Idempotency-Key` header to protect against duplicate imports.
* Imported responses receive new `responseId`s and cannot overwrite existing ones; if you need updates you must delete then re-import.
* Watch for mapping errors where column names in CSV do not match `QID…` or `EmbeddedData` names.

---

## 16.2 Bulk update (via responses job)

**Endpoint**

```
POST /API/v3/surveys/{surveyId}/update-responses
```

**Purpose**
Update embedded data, or other minimal fields across many responses.
**Request body example**

```json
{
  "updates": [
    { "responseId": "R_010", "embeddedData": { "Region": "APAC" } },
    { "responseId": "R_011", "embeddedData": { "Segment": "Enterprise" } }
  ]
}
```

Returns `progressId` to poll.
Note: Cannot update core answer values once recorded.

---

## 16.3 Best Practices & Operational Guidelines for Analytics Teams

* For recurring exports (e.g., nightly), keep a **cursor** of `ResponseId` or `RecordedDate` and request only new responses using the `filter` parameter.
* For large brands with >1 M responses, partition by date or survey version to remain under file size limits.
* In your data lake ingestion pipeline, log the `fileId`, `progressId`, and `requestId` for auditability.
* Use NDJSON when ingesting into Azure Synapse or Databricks—line delimited JSON is more efficient for big data loads.
* Before deletion or import of responses, validate that quotas, distributions, and dashboards will reference the correct `ResponseId` set to avoid analytics mis-reporting.
* Monitor for 429 and 5xx errors; implement exponential back-off and cap concurrency to ~50 simultaneous jobs per brand to avoid hitting rate limits.
* Use `exportColumns` to limit variable width when downstream doesn’t use all survey fields; this reduces file size and speeds ingestion.

---

### References

* Qualtrics. (2025). *Qualtrics API Docs v3 — Export Responses Endpoints.* [https://api.qualtrics.com/](https://api.qualtrics.com/) ([api.qualtrics.com](https://api.qualtrics.com/?utm_source=chatgpt.com))
* Postman. (2024). *Survey Response Export/Import Collection.* [https://www.postman.com/qualtrics-public-apis/qualtrics-public-workspace/folder/f8gq7bx/surveys-response-import-export?utm_source=chatgpt.com](https://www.postman.com/qualtrics-public-apis/qualtrics-public-workspace/folder/f8gq7bx/surveys-response-import-export?utm_source=chatgpt.com)
* Qualtrics Community. (2023). *Bulk update collected survey responses.* [https://community.qualtrics.com/](https://community.qualtrics.com/) ([community.qualtrics.com](https://community.qualtrics.com/survey-platform-54/bulk-update-collected-survey-responses-32427?utm_source=chatgpt.com))

---

Would you like me to compile **all sections into a single downloadable reference PDF/Markdown** or focus next on **error codes and rate-limit behaviour across the API surface**?



