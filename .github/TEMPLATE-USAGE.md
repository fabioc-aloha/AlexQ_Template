# Using This Repository as a Template

This guide explains how to use the Disposition Dashboard repository as a template for your Qualtrics + Azure integration project.

---

## Quick Start (GitHub Template)

### Method 1: Use GitHub's Template Feature (Recommended)

1. **On GitHub.com**, navigate to the main page of the repository
2. Click **"Use this template"** button (top right, next to "Code")
3. Select **"Create a new repository"**
4. Fill in repository details:
   - **Owner**: `fabioc-aloha`
   - **Repository name**: Your project name (e.g., `SurveyAnalyticsPipeline`)
   - **Description**: Your project description
   - **Visibility**: Public or Private
5. Click **"Create repository from template"**

**Advantages**:
- Clean git history (no original commits)
- Automatically sets up GitHub features
- Maintains template badge/link
- Easiest method

### Method 2: Manual Clone (Alternative)

```powershell
# Clone repository
```bash
git clone https://github.com/fabioc-aloha/AlexQ_Template.git YourProjectName
cd YourProjectName
```

# Remove original git history
Remove-Item -Recurse -Force .git

# Initialize new repository
git init
git add .
git commit -m "Initial commit from Qualtrics-Azure template"

# Push to your new repository
```bash
git remote add template https://github.com/fabioc-aloha/AlexQ_Template.git
git fetch template
```
git push -u origin main
```

---

## Post-Template Setup

After creating your repository from the template:

### 1. Update Core Documentation (5 minutes)

```powershell
# Update README.md
# Replace "Disposition Dashboard" with your project name
# Update overview section with your project description

# Create your project plan
# Copy plan/SAMPLE-PROJECT-PLAN.md to plan/YYYY-MM-DD-your-project-name.md
# Fill in your goals, requirements, and implementation details
```

### 2. Configure Qualtrics Integration (10 minutes)

```powershell
# Edit qualtrics/qualtrics-config.json
# Update with your:
# - Survey IDs
# - Distribution IDs
# - Datacenter ID
# - API configuration

# Review required endpoints
# Read qualtrics/DK-QUALTRICS-API-v1.0.0.md
# Identify which endpoints you need for your use case
```

### 3. Review Governance Requirements (10 minutes)

```powershell
# Read azure/AZURE-SFI-GOVERNANCE.md
# Understand RBAC requirements (admin group pattern)
# Note permission model constraints
# Plan Phase 0 permission setup
```

### 4. Design Architecture (30-60 minutes)

```powershell
# Read TEMPLATE-QUALTRICS-AZURE-PROJECT.md
# Review three-tier architecture pattern
# Decide which tiers you need:
#   - Tier 1: Historical (bulk export)
#   - Tier 2: Real-time (webhooks)
#   - Tier 3: Aggregate (distribution stats)

# Calculate rate budget
# Use Rate Limit Matrix from template guide
# Ensure your polling/webhook strategy fits within limits
```

---

## What to Keep vs. Delete

### Keep (Reference Materials) ✅

**Essential Documentation**:
- `TEMPLATE-QUALTRICS-AZURE-PROJECT.md` - Complete template guide
- `TEMPLATE-README.md` - Quick start guide
- `qualtrics/DK-QUALTRICS-API-v1.0.0.md` - API reference (2378 lines, 100% verified)
- `qualtrics/QUALTRICS-API-QUICK-REF.md` - Quick reference
- `azure/AZURE-SFI-GOVERNANCE.md` - SFI compliance rules
- `domain-knowledge/DK-AZURE-INFRASTRUCTURE-v1.0.0.md` - Azure service selection
- `domain-knowledge/DK-ALEX-Q-QUALTRICS-SPECIALIST-v1.0.0.md` - Alex Q specialization

**Template Files**:
- `plan/TEMPLATE-PLAN.md` - Project plan template
- `.github/copilot-instructions.md` - Alex Q cognitive architecture
- `scripts/neural-dream.ps1` - Alex Q maintenance automation
- `scripts/cognitive-config.json` - Alex Q configuration

### Customize (Project-Specific) ✏️

**Core Documentation**:
- `README.md` - Update with your project details
- `plan/YYYY-MM-DD-your-project-plan.md` - Copy from SAMPLE-PROJECT-PLAN.md and customize
- `qualtrics/qualtrics-config.json` - Update with your configuration
- `qualtrics/README.md` - Update for your integration specifics

**Create New**:
- `plan/YYYY-MM-DD-your-project-plan.md` - Your project plan
- `src/` - Your application code (not in template)
- `azure/infrastructure/` - Your IaC files (Bicep/Terraform)
- `tests/` - Your test files

### Optional Delete (Example Implementation) 🗑️

**Note**: All original project artifacts have been removed or incorporated into template documentation.

**Alex Q Meditation Sessions** (keep for reference or remove if not using AI assistant):
- `.github/prompts/meditation-session-2025-11-10-sfi-governance-integration.prompt.md` - SFI governance example
- `.github/prompts/meditation-session-2025-11-10-template-release.prompt.md` - Template transformation example

**Recommendation**: Keep these files initially as reference materials. Delete after your project is stable and you no longer need examples.

---

## Checklist: Template to Production

Use this checklist to transform the template into your production project:

### Phase 0: Initial Setup ✅
- [ ] Create repository from template
- [ ] Clone to local machine
- [ ] Update `README.md` with project name and description
- [ ] Copy `plan/SAMPLE-PROJECT-PLAN.md` to `plan/YYYY-MM-DD-your-project-plan.md`
- [ ] Read `TEMPLATE-QUALTRICS-AZURE-PROJECT.md` completely
- [ ] Review `qualtrics/DK-QUALTRICS-API-v1.0.0.md` for required endpoints

### Phase 1: Configuration ✅
- [ ] Edit `qualtrics/qualtrics-config.json` with your surveys
- [ ] Identify required API endpoints from documentation
- [ ] Calculate rate budget using template guide
- [ ] Determine three-tier architecture requirements
- [ ] Design Cosmos DB schema for your data model
- [ ] Create `plan/YYYY-MM-DD-your-project-plan.md`

### Phase 2: Azure Setup ✅
- [ ] Review `azure/AZURE-SFI-GOVERNANCE.md` requirements
- [ ] Create Azure resource group with SFI naming
- [ ] Assign RBAC to `[your-admin-group]`
- [ ] Set up Azure Key Vault for secrets
- [ ] Create Application Insights workspace
- [ ] Document Phase 0 permissions

### Phase 3: Infrastructure as Code ✅
- [ ] Create `azure/infrastructure/` directory
- [ ] Write Bicep/Terraform for Azure Functions
- [ ] Write Bicep/Terraform for Cosmos DB
- [ ] Write Bicep/Terraform for SignalR (if needed)
- [ ] Write Bicep/Terraform for Service Bus (if needed)
- [ ] Configure RBAC in IaC

### Phase 4: Implementation ✅
- [ ] Create `src/` directory structure
- [ ] Implement Qualtrics API client (copy from template patterns)
- [ ] Implement webhook handlers with HMAC validation
- [ ] Implement Azure Functions for data processing
- [ ] Implement Cosmos DB data layer
- [ ] Add rate limit monitoring
- [ ] Build frontend (if applicable)

### Phase 5: Security ✅
- [ ] Store API tokens in Key Vault
- [ ] Implement HMAC signature validation
- [ ] Use Managed Identity for Azure resources
- [ ] Configure network security groups
- [ ] Enable diagnostic logging
- [ ] Verify SFI governance compliance

### Phase 6: Testing ✅
- [ ] Test API integration with rate monitoring
- [ ] Validate webhook security (HMAC, deduplication)
- [ ] Load test Azure infrastructure
- [ ] Test error handling and retries
- [ ] Validate monitoring and alerts
- [ ] Perform security review

### Phase 7: Deployment ✅
- [ ] Deploy to development environment
- [ ] Configure CI/CD pipeline
- [ ] Deploy to production environment
- [ ] Configure monitoring dashboards
- [ ] Set up alerts for critical metrics
- [ ] Document operational runbook

### Phase 8: Maintenance ✅
- [ ] Monitor rate limit utilization
- [ ] Review webhook health metrics
- [ ] Optimize Cosmos DB RU consumption
- [ ] Update documentation with learnings
- [ ] Consider contributing improvements back to template

---

## Common Customization Scenarios

### Scenario 1: Real-Time Survey Dashboard
**What to customize**:
- Keep Tier 2 (webhooks) and Tier 3 (distribution stats)
- Add SignalR for real-time frontend updates
- Customize Cosmos DB schema for dashboard queries
- Implement frontend using template's architecture

**Template sections to use**:
- Three-Tier Architecture Pattern
- Webhook Handler with HMAC Validation
- Distribution Stats Polling Pattern
- Cosmos DB Schema Patterns

### Scenario 2: Survey Response Data Pipeline
**What to customize**:
- Focus on Tier 1 (bulk export) and Tier 2 (webhooks)
- Add Service Bus for decoupled processing
- Customize for data transformation/enrichment
- No frontend needed

**Template sections to use**:
- Export with Exponential Backoff Polling
- Webhook Handler with Service Bus Integration
- Rate Budget Calculation
- Security Best Practices

### Scenario 3: Multi-Survey Analytics
**What to customize**:
- Use Tier 3 (distribution stats) for many surveys
- Add Tier 1 (periodic export) for detailed analysis
- Partition Cosmos DB by survey ID
- Integrate with Power BI

**Template sections to use**:
- Rate Limit Optimization (scaling)
- Cosmos DB Partition Key Strategy
- Distribution Polling Pattern
- Monitoring & Observability

---

## Working with Alex Q

This template is optimized for **Alex Q**, the Qualtrics & Azure Infrastructure Specialist AI.

### Initial Project Setup with Alex Q

**Prompt**: "Alex Q, I'm starting a new project from the Disposition Dashboard template. My project is [describe your project]. Can you help me customize the template?"

**Alex Q will**:
1. Load template context automatically
2. Review your project requirements
3. Recommend which API endpoints you need
4. Calculate rate budget for your use case
5. Design Azure architecture following SFI governance
6. Generate implementation code using template patterns

### Example Prompts

**Planning**:
- "Calculate rate budget for monitoring 100 surveys with 50 responses per day"
- "Which tier architecture do I need for real-time notification system?"
- "Design Cosmos DB schema for storing survey responses and distribution stats"

**Implementation**:
- "Generate webhook handler for survey completion events with HMAC validation"
- "Implement export workflow with continuation tokens for 500k responses"
- "Create Azure Function to poll distribution stats every 10 minutes"

**Governance**:
- "Review my infrastructure design for SFI compliance"
- "Generate Bicep template following group-based RBAC requirements"
- "Verify my Key Vault configuration meets security best practices"

---

## Template Updates

### Staying Current

The template is maintained and improved as new patterns emerge. To get updates:

```powershell
# Add template as upstream remote
git remote add template https://github.com/fabioc-aloha/AlexQ_Template.git

# Fetch template updates
git fetch template

# Review changes
git log template/main

# Merge specific updates (cherry-pick recommended)
git cherry-pick <commit-hash>
```

### Contributing Back

If you discover improvements, consider contributing:

1. Document the improvement in your project
2. Create domain knowledge file if applicable
3. Test thoroughly in your implementation
4. Submit pull request to template repository

---

## Getting Help

### Template Issues
- Review `TEMPLATE-README.md` for quick start
- Check `TEMPLATE-QUALTRICS-AZURE-PROJECT.md` for detailed guide
- Search existing project documentation

### API Questions
- Search `qualtrics/DK-QUALTRICS-API-v1.0.0.md` (140+ endpoints)
- Check `qualtrics/QUALTRICS-API-QUICK-REF.md`
- Reference official docs at https://api.qualtrics.com

### Azure Questions
- Review `domain-knowledge/DK-AZURE-INFRASTRUCTURE-v1.0.0.md`
- Check `azure/AZURE-SFI-GOVERNANCE.md`
- Reference Microsoft Learn

### Alex Q Questions
- Review `.github/copilot-instructions.md`
- Check domain knowledge files
- Ask Alex Q directly in GitHub Copilot

---

## Success Metrics

Your template usage is successful when:

✅ Project compiles and runs within 2 weeks of template creation
✅ SFI governance compliance verified (RBAC, security, monitoring)
✅ API integration working with < 50% rate limit utilization
✅ Webhook security validated (HMAC, deduplication working)
✅ Monitoring dashboards show green health status
✅ Production deployment completed with zero incidents
✅ Team can explain architecture using template documentation

---

*This guide is maintained as part of the Qualtrics + Azure Project Template*
*Version: 1.0.0 UNNIL (Template)*
*Last Updated: 2025-11-10*
