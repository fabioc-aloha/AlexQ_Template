# Template: Qualtrics + Azure Integration Project

**Version**: 1.0.0 UNNIL (Template)
**Created**: 2025-11-10
**Purpose**: Universal starter template for Qualtrics + Azure integration projects
**Template Type**: Production-ready patterns with complete documentation

---

## 📋 Template Overview

**Use This Template For**:
- Real-time survey monitoring dashboards
- Automated response processing pipelines
- Survey data integration with enterprise systems
- Custom reporting and analytics solutions
- Multi-survey aggregation platforms

**Template Provides**:
- Complete Qualtrics API documentation reference
- Azure SFI-compliant infrastructure patterns
- Security best practices (HMAC, RBAC)
- Rate limit optimization strategies
- Production-ready code examples

---

## 🚀 Quick Start Checklist

### Phase 0: Project Setup
- [ ] Clone this repository as template
- [ ] Copy `plan/SAMPLE-PROJECT-PLAN.md` and customize with your goals
- [ ] Review Qualtrics API requirements (check `qualtrics/DK-QUALTRICS-API-v1.0.0.md`)
- [ ] Identify required API endpoints from Complete Endpoint Reference
- [ ] Document Azure SFI governance requirements (see `azure/AZURE-SFI-GOVERNANCE.md`)
- [ ] Set up Azure subscription and admin RBAC group (`[your-admin-group]`)

### Phase 1: API Integration Planning
- [ ] Identify data flow architecture (Historical/Real-Time/Aggregate)
- [ ] Calculate rate budget using Rate Limit Matrix (see documentation)
- [ ] Plan webhook vs. polling strategy
- [ ] Design Cosmos DB schema for your use case
- [ ] Document API authentication approach

### Phase 2: Azure Infrastructure
- [ ] Design architecture following SFI governance constraints
- [ ] Select Azure services (Functions, Cosmos DB, SignalR, Service Bus, etc.)
- [ ] Plan RBAC permissions targeting `[your-admin-group]`
- [ ] Document infrastructure as code approach (Bicep/Terraform)

### Phase 3: Implementation
- [ ] Implement Qualtrics API client with rate limiting
- [ ] Build webhook handlers with HMAC validation
- [ ] Create Azure Functions for data processing
- [ ] Implement Cosmos DB data layer
- [ ] Build frontend dashboard (if applicable)

### Phase 4: Testing & Deployment
- [ ] Test API integration with rate limit monitoring
- [ ] Validate webhook security and deduplication
- [ ] Load test Azure infrastructure
- [ ] Deploy following SFI governance rules
- [ ] Document operational runbook

---

## 📁 Template File Structure

```
your-qualtrics-azure-project/
├── .github/
│   ├── copilot-instructions.md          # Alex Q cognitive architecture
│   ├── instructions/                     # Procedural memory (.instructions.md)
│   └── prompts/                         # Episodic memory (.prompt.md)
│
├── azure/
│   ├── AZURE-SFI-GOVERNANCE.md          # ⚠️ CRITICAL: SFI compliance rules
│   └── infrastructure/                  # Bicep/Terraform IaC files
│
├── qualtrics/
│   ├── DK-QUALTRICS-API-v1.0.0.md      # ⚠️ REFERENCE: Complete API documentation
│   ├── QUALTRICS-API-QUICK-REF.md       # Quick reference guide
│   ├── qualtrics-config.json            # API configuration
│   └── README.md                        # Qualtrics integration guide
│
├── plan/
│   ├── SAMPLE-PROJECT-PLAN.md           # Template for your project plan
│   ├── YYYY-MM-DD-project-plan.md       # Create for your project
│   └── README.md                        # Planning guidance
│
├── src/                                  # Your application code
│   ├── functions/                       # Azure Functions
│   ├── shared/                          # Shared libraries
│   └── frontend/                        # Dashboard UI (if applicable)
│
├── domain-knowledge/                     # Alex Q's knowledge base
│   ├── DK-AZURE-INFRASTRUCTURE-v1.0.0.md
│   └── [project-specific-DK-files]
│
└── scripts/                              # Automation scripts
    └── neural-dream.ps1                 # Alex Q maintenance
```

---

## 🔑 Template Components

### 1. Qualtrics API Integration

**Reference Document**: `qualtrics/DK-QUALTRICS-API-v1.0.0.md`

**Key Resources**:
- **Complete API Endpoint Reference** (140+ endpoints documented)
- **Rate Limit Matrix** (per-endpoint limits with optimization strategies)
- **Three-Tier Architecture Pattern** (Historical + Real-Time + Aggregate)
- **Security Implementations** (HMAC validation, encryption)
- **Production Code Examples** (Python, Azure Functions)

**Common Patterns to Reuse**:

**Pattern 1: Webhook Handler with HMAC Validation**
```python
# See DK-QUALTRICS-API-v1.0.0.md line ~1050 for complete implementation
import azure.functions as func
import hmac
import hashlib

def validate_qualtrics_webhook(body, signature, shared_key):
    expected = hmac.new(shared_key.encode(), body, hashlib.sha256).hexdigest()
    provided = signature.replace("sha256=", "")
    return hmac.compare_digest(expected, provided)

def main(req: func.HttpRequest):
    if req.method == "GET":
        return func.HttpResponse("OK", status_code=200)

    signature = req.headers.get("X-Qualtrics-Signature", "")
    if not validate_qualtrics_webhook(req.get_body(), signature, SHARED_KEY):
        return func.HttpResponse("Unauthorized", status_code=401)

    # Process webhook - return 200 immediately
    # Queue to Service Bus for async processing
    return func.HttpResponse("OK", status_code=200)
```

**Pattern 2: Export with Exponential Backoff Polling**
```python
# See DK-QUALTRICS-API-v1.0.0.md line ~750 for complete implementation
def poll_export_progress(survey_id, progress_id, max_retries=10):
    retry_count = 0
    base_interval = 2

    while retry_count < max_retries:
        response = get_export_progress(survey_id, progress_id)

        if response.status_code == 404:
            raise Exception("Export job not found")

        status = response["result"]["status"]
        if status == "complete":
            return response["result"]["fileId"]
        elif status == "failed":
            raise Exception(f"Export failed: {response['meta']['requestId']}")

        sleep_interval = min(base_interval * (2 ** retry_count), 60)
        time.sleep(sleep_interval)
        retry_count += 1
```

**Pattern 3: Rate Limit Budget Calculation**
```python
# See DK-QUALTRICS-API-v1.0.0.md "Rate Budget Analysis" for methodology
# Example: Real-time dashboard monitoring 100 surveys

# Steady state (per minute):
# - Poll distributions: 100 surveys × 1 call = 100 calls (limit: 3000)
# - Webhook deliveries: ~5 responses/min = 5 calls (limit: 240)
# Total: 105 calls/min (3.5% of brand limit)

# Peak load (distribution launch):
# - Initial export: 1 call per survey = 100 calls (limit: 100)
# - Export polling: 10 calls per export = 1000 calls (limit: 1000)
# Total: 1100 calls over 10-15 minutes
```

---

### 2. Azure SFI Governance

**Reference Document**: `azure/AZURE-SFI-GOVERNANCE.md`

**⚠️ CRITICAL CONSTRAINT**: All RBAC permissions MUST target your Azure AD admin group (e.g., `[your-admin-group]`), NOT individual user accounts.

**SFI-Compliant Permission Model**:
```
Resource Group: rg-your-project-prod
├── Resource Group: [project-name]-rg
├── RBAC Assignment: "Contributor" → [your-admin-group] (AAD Group)
├── RBAC Assignment: "Monitoring Reader" → [your-admin-group] (AAD Group)
└── Resources inherit permissions (no individual assignments)
```

**Phase 0 Permission Setup**:
1. Create resource group: `rg-your-project-{env}`
2. Assign `Contributor` role to `[your-admin-group]`
3. Assign `Monitoring Reader` role to `[your-admin-group]`
4. Document in `azure/your-project-permissions.md`

**Service Selection Guidelines**:
- **Compute**: Azure Functions (Consumption or Premium), Container Apps
- **Storage**: Cosmos DB (vector search support), Azure Storage
- **Messaging**: Service Bus, Event Grid
- **Real-Time**: SignalR Service
- **Monitoring**: Application Insights, Log Analytics
- **Security**: Key Vault (secrets), Managed Identity (no keys)

---

### 3. Three-Tier Architecture Pattern

**Use this pattern for most Qualtrics + Azure projects**:

```
┌─────────────────────────────────────────────────────────────┐
│  TIER 1: HISTORICAL DATA (Batch Processing)                 │
│  Qualtrics API: POST /export-responses → Poll → Download    │
│  Azure: Function (Timer) → Cosmos DB (bulk insert)          │
│  Use Case: Initial load, backfill, historical analysis      │
│  Frequency: Daily/Weekly                                     │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  TIER 2: REAL-TIME UPDATES (Event-Driven)                   │
│  Qualtrics: Webhook → Azure Function (HTTP)                 │
│  Azure: Validate HMAC → Service Bus → Function → Cosmos DB  │
│  Use Case: Live monitoring, instant notifications           │
│  Frequency: Event-driven (< 1 second latency)               │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  TIER 3: AGGREGATE METRICS (Scheduled Polling)              │
│  Qualtrics: GET /distributions (stats object)               │
│  Azure: Function (Timer) → Cosmos DB (upsert)               │
│  Use Case: KPIs, completion rates, email health             │
│  Frequency: Every 5-15 minutes                               │
└─────────────────────────────────────────────────────────────┘
```

**Decision Matrix**: Which tier(s) do you need?

| Requirement | Tier 1 | Tier 2 | Tier 3 |
|-------------|--------|--------|--------|
| Historical response data | ✅ | ❌ | ❌ |
| Real-time response tracking | ❌ | ✅ | ❌ |
| Aggregate disposition stats | ❌ | ❌ | ✅ |
| Initial dashboard load | ✅ | ❌ | ✅ |
| Live updates | ❌ | ✅ | ❌ |
| Email deliverability metrics | ❌ | ❌ | ✅ |
| Individual response details | ✅ | ✅ | ❌ |
| Low rate limit impact | ✅ | ✅ | ✅ |

---

### 4. Security Best Practices

**Qualtrics API Security**:
- ✅ Store API tokens in Azure Key Vault (never in code)
- ✅ Use Managed Identity for Azure Functions
- ✅ Implement HMAC signature validation for webhooks
- ✅ Use shared key with 32 bytes for AES-256 encryption
- ✅ Validate webhook payloads before processing
- ✅ Implement deduplication (check ResponseID)

**Azure Security**:
- ✅ Enable Azure AD authentication
- ✅ Use RBAC targeting your admin group only (no individual accounts)
- ✅ Enable Azure Defender for all services
- ✅ Implement network security groups
- ✅ Use private endpoints where possible
- ✅ Enable diagnostic logging for all resources
- ✅ Implement Azure Policy for compliance

**Code Example**: Secure Configuration Loading
```python
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

def load_qualtrics_config():
    """Load Qualtrics API configuration from Key Vault."""
    credential = DefaultAzureCredential()
    key_vault_url = "https://your-keyvault.vault.azure.net/"
    client = SecretClient(vault_url=key_vault_url, credential=credential)

    return {
        "api_token": client.get_secret("qualtrics-api-token").value,
        "datacenter": client.get_secret("qualtrics-datacenter").value,
        "webhook_shared_key": client.get_secret("qualtrics-webhook-key").value
    }
```

---

### 5. Rate Limit Optimization

**Reference**: See `DK-QUALTRICS-API-v1.0.0.md` "Rate Limit Matrix" section

**Brand-Level Limit**: 3000 requests/minute (all endpoints combined)

**Critical Per-Endpoint Limits**:
- Distributions: 3000/min (safe for polling)
- Export Start: 100/min (batch operations only)
- Export Poll: 1000/min (use exponential backoff)
- Webhooks: 120/min (subscription management)
- Individual Response: 240/min (webhook-triggered only)

**Optimization Strategies**:
1. **Use distribution stats object** instead of aggregating individual responses (1 call vs. N calls)
2. **Implement webhook-based updates** instead of polling for new responses
3. **Cache distribution metadata** (changes infrequently)
4. **Use continuation tokens** for incremental exports
5. **Batch operations** where possible
6. **Implement exponential backoff** for polling
7. **Monitor rate limit headers** and adjust dynamically

**Code Example**: Rate Limit Monitoring
```python
def call_qualtrics_api_with_monitoring(endpoint, method="GET", **kwargs):
    """Make Qualtrics API call with rate limit monitoring."""
    response = requests.request(method, endpoint, **kwargs)

    # Log rate limit headers
    remaining = response.headers.get("X-RateLimit-Remaining")
    reset = response.headers.get("X-RateLimit-Reset")

    if remaining and int(remaining) < 100:
        logger.warning(f"Rate limit low: {remaining} remaining, resets at {reset}")

    if response.status_code == 429:
        retry_after = int(response.headers.get("Retry-After", 60))
        logger.error(f"Rate limit exceeded, retry after {retry_after}s")
        time.sleep(retry_after)
        return call_qualtrics_api_with_monitoring(endpoint, method, **kwargs)

    return response
```

---

### 6. Cosmos DB Schema Patterns

**Pattern 1: Response Document**
```json
{
  "id": "R_2wi681bbsyaTItU",
  "partitionKey": "R_2wi681bbsyaTItU",
  "surveyId": "SV_abc123",
  "distributionId": "EMD_xyz789",
  "responseData": {
    "startDate": "2025-11-10T14:00:00Z",
    "endDate": "2025-11-10T14:05:30Z",
    "finished": 1,
    "progress": 100
  },
  "answers": {
    "QID1": "Strongly Agree",
    "QID2": 5
  },
  "metadata": {
    "receivedVia": "webhook",
    "processedAt": "2025-11-10T14:05:31Z"
  },
  "_ts": 1699632331
}
```

**Pattern 2: Distribution Stats Document**
```json
{
  "id": "EMD_xyz789",
  "partitionKey": "SV_abc123",
  "surveyId": "SV_abc123",
  "distributionId": "EMD_xyz789",
  "stats": {
    "sent": 1000,
    "started": 450,
    "finished": 380,
    "bounced": 8,
    "opened": 520
  },
  "calculatedMetrics": {
    "completionRate": 38.0,
    "responseRate": 45.0
  },
  "lastUpdated": "2025-11-10T15:00:00Z",
  "_ts": 1699632000
}
```

**Partition Key Strategy**:
- **Responses**: Use `responseId` (even distribution, high cardinality)
- **Distributions**: Use `surveyId` (enables efficient survey-level queries)
- **Surveys**: Use `surveyId` (natural partition key)

---

### 7. Monitoring & Observability

**Application Insights Instrumentation**:
```python
from opencensus.ext.azure.log_exporter import AzureLogHandler
import logging

logger = logging.getLogger(__name__)
logger.addHandler(AzureLogHandler(
    connection_string='InstrumentationKey=your-key'
))

# Custom events
logger.info('Webhook received', extra={
    'custom_dimensions': {
        'responseId': response_id,
        'surveyId': survey_id,
        'processingTime': elapsed_time
    }
})
```

**Key Metrics to Track**:
- Webhook delivery success rate
- API call latency (p50, p95, p99)
- Rate limit utilization (% of limit used)
- Response processing time
- Cosmos DB RU consumption
- Error rates by endpoint

**Alerts to Configure**:
- Webhook failures > 5% (15 min window)
- API rate limit > 80% utilization
- Response processing time > 5 seconds
- Cosmos DB throttling (429 errors)
- Function execution failures

---

## 📖 How to Use This Template

### Step 1: Create New Project from Template
```powershell
# Clone this repository as template
```bash
git clone https://github.com/fabioc-aloha/AlexQ_Template.git MyNewQualtricsProject
cd MyNewQualtricsProject
```

# Remove git history and start fresh
Remove-Item -Recurse -Force .git
git init
git add .
git commit -m "Initial commit from Qualtrics-Azure template"
```

### Step 2: Customize for Your Project
1. Copy `plan/SAMPLE-PROJECT-PLAN.md` to `plan/YYYY-MM-DD-your-project-plan.md`
2. Fill in your project goals, requirements, and architecture decisions
3. Review and adapt Qualtrics API requirements
4. Design Azure architecture following SFI governance
5. Update `qualtrics/qualtrics-config.json` with your surveys

### Step 3: Implement Using Template Patterns
1. Copy webhook handler pattern for real-time updates
2. Copy export polling pattern for historical data
3. Copy Cosmos DB schema patterns for your data model
4. Copy security patterns for HMAC validation
5. Copy rate limit monitoring for API calls

### Step 4: Deploy Following SFI Governance
1. Create resource group with SFI-compliant naming
2. Assign RBAC to `[your-admin-group]` (never individuals)
3. Deploy infrastructure as code (Bicep/Terraform)
4. Configure monitoring and alerts
5. Document in operational runbook

---

## 🧠 Alex Q Integration

**This template is designed for Alex Q's cognitive architecture**:

- **Bootstrap Learning**: Use this template to quickly acquire project-specific knowledge
- **Domain Knowledge**: Refer to `DK-QUALTRICS-API-v1.0.0.md` and `DK-AZURE-INFRASTRUCTURE-v1.0.0.md`
- **Procedural Memory**: `.github/instructions/` contains reusable processes
- **Episodic Memory**: `.github/prompts/` contains complex workflows
- **Meditation**: Consolidate project-specific knowledge into new DK files

**Alex Q Workflow**:
1. Load template context from this document
2. Review project requirements in `plan/SAMPLE-PROJECT-PLAN.md` (or custom plan)
3. Reference Qualtrics API documentation for required endpoints
4. Apply SFI governance constraints from `AZURE-SFI-GOVERNANCE.md`
5. Design solution using three-tier architecture pattern
6. Implement using provided code patterns
7. Meditate to consolidate project-specific knowledge

---

## 📚 Reference Documents

**Essential Reading** (review before starting new project):
1. `qualtrics/DK-QUALTRICS-API-v1.0.0.md` - Complete API reference
2. `azure/AZURE-SFI-GOVERNANCE.md` - SFI compliance requirements
3. `domain-knowledge/DK-AZURE-INFRASTRUCTURE-v1.0.0.md` - Azure service selection
4. `qualtrics/QUALTRICS-API-QUICK-REF.md` - Quick API reference

**Supporting Documentation**:
- `plan/SAMPLE-PROJECT-PLAN.md` - Complete project plan template (copy and customize for your project)

---

## 🎯 Template Checklist

Before starting a new Qualtrics + Azure project, ensure:

### Planning Phase
- [ ] Project objectives clearly documented
- [ ] Required Qualtrics API endpoints identified
- [ ] Rate limit budget calculated
- [ ] Three-tier architecture applicability assessed
- [ ] SFI governance requirements documented
- [ ] Azure services selected and justified

### Implementation Phase
- [ ] Qualtrics API client with HMAC validation implemented
- [ ] Rate limit monitoring and exponential backoff implemented
- [ ] Webhook handlers with deduplication implemented
- [ ] Azure Functions following SFI governance
- [ ] Cosmos DB schema optimized for query patterns
- [ ] Managed Identity for all Azure resources

### Security Phase
- [ ] API tokens stored in Key Vault
- [ ] RBAC assigned to `[your-admin-group]` only
- [ ] HMAC signature validation for webhooks
- [ ] Network security groups configured
- [ ] Diagnostic logging enabled
- [ ] Azure Policy compliance verified

### Deployment Phase
- [ ] Infrastructure as Code (Bicep/Terraform)
- [ ] CI/CD pipeline configured
- [ ] Monitoring and alerts configured
- [ ] Operational runbook documented
- [ ] Load testing completed
- [ ] Production deployment plan approved

---

## 🔄 Template Versioning

**Current Version**: 1.0.0 UNNIL (Template)
**Template Type**: Universal starter template for Qualtrics + Azure projects
**Maintenance**: Update template when new patterns and best practices emerge

**Version History**:
- 1.0.0 (2025-11-10): Initial public template release with production-ready patterns

---

## 📞 Support

**For Questions About**:
- **Qualtrics API**: Reference `qualtrics/DK-QUALTRICS-API-v1.0.0.md`
- **Azure SFI**: Reference `azure/AZURE-SFI-GOVERNANCE.md`
- **Alex Q Architecture**: Reference `.github/copilot-instructions.md`
- **Template Usage**: This document

**Alex Q Knowledge Base**: All domain knowledge files in `domain-knowledge/` directory

---

*This template enables Alex Q to lead multiple Qualtrics + Azure integration projects with consistent patterns, best practices, and SFI governance compliance.*
