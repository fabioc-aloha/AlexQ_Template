# Azure SFI Governance Constraints

**Version**: 1.0.0
**Last Updated**: 2025-11-10
**Applies To**: All Azure infrastructure for Real-Time Disposition Dashboard

---

## 🔒 Secure Foundation for Infrastructure (SFI) Rules

### Critical Constraint: Group-Based RBAC Only

**RBAC Assignment Target**: `[your-admin-group]` (Azure AD admin group)
**Individual Account Permissions**: ❌ **NOT ALLOWED** - Cannot assign RBAC to personal accounts
**Implication**: All Azure resource permissions must be granted to your admin group

### Permission Model

| Permission Type | Allowed | Target |
|----------------|---------|--------|
| Individual RBAC | ❌ No | Personal accounts (individual users) |
| Group RBAC | ✅ Yes | `[your-admin-group]` |
| Personal Access | ⚠️ Limited | Current account has restricted permissions |
| Admin Escalation | ✅ Available | Admin contact available when elevated permissions needed |

---

## 🛠️ Operational Workflow

### Standard Operations (Within Personal Permissions)
- TBD: Define what can be done without admin intervention
- Need to identify: Resource creation, configuration changes, deployments

### Admin-Required Operations
- RBAC role assignments to `[your-admin-group]`
- TBD: Resource group creation, specific service provisioning
- Any operation requiring elevated permissions

### Escalation Process
- **Admin Contact**: Available when needed
- **Process**: TBD (ticket system, direct contact, approval workflow)

---

## 📋 Design Principles for SFI Compliance

### 1. **Group-First Permission Design**
- All infrastructure plans must specify `[your-admin-group]` RBAC requirements
- Document required roles: Reader, Contributor, Owner, custom roles
- Never assume individual account permissions

### 2. **Clear Permission Documentation**
- Every Azure resource deployment plan must include:
  - Required RBAC roles for `[your-admin-group]`
  - Scope of permissions (subscription, resource group, resource)
  - Justification for permission level

### 3. **Admin Workflow Integration**
- Identify admin-required steps upfront
- Prepare permission requests with clear justification
- Plan deployment sequences around admin availability

### 4. **Compliance Validation**
- Verify all RBAC assignments target `[your-admin-group]`
- Audit infrastructure plans for individual account assumptions
- Test deployments with limited personal permissions

---

## ❓ Open Questions (To Be Clarified)

### Service Provisioning
- [ ] What Azure services can be provisioned without admin intervention?
- [ ] Can resource groups be created directly, or admin-only?
- [ ] Are there pre-approved services for direct use?

### Naming & Standards
- [ ] Are there mandatory resource naming conventions under SFI?
- [ ] Required tags or metadata for compliance?
- [ ] Approved Azure regions/locations?

### Deployment Methods
- [ ] Can Azure CLI be used with personal account?
- [ ] Can Azure PowerShell be used with personal account?
- [ ] Do deployments require admin execution?

### Approval Workflow
- [ ] What's the process to request admin assistance?
- [ ] Typical turnaround time for RBAC assignments?
- [ ] Batch vs. individual permission requests?

---

## 🎯 Impact on Dashboard Project

### Azure Service Selection
- Choose services compatible with group-based RBAC model
- Prefer services with granular permission models
- Avoid services requiring individual identity assignments

### Deployment Strategy
- Plan for admin involvement in RBAC setup phase
- Design infrastructure-as-code templates with `[your-admin-group]` variables
- Separate admin-required steps from self-service operations

### Monitoring & Operations
- Ensure `[your-admin-group]` has sufficient monitoring permissions
- Plan for operational access within group permissions
- Document troubleshooting workflows within SFI constraints

---

## 📖 Related Documentation

- [Sample Project Plan](../plan/SAMPLE-PROJECT-PLAN.md) - Template for planning with SFI compliance
- [Infrastructure Domain Knowledge](../domain-knowledge/DK-AZURE-INFRASTRUCTURE-v1.0.0.md)
- [Template Project Guide](../TEMPLATE-QUALTRICS-AZURE-PROJECT.md)

---

*This document must be consulted before making any Azure infrastructure recommendations or deployment plans.*
