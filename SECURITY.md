# Security Policy

## Supported Versions

We release patches for security vulnerabilities in the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

We take the security of this template seriously. If you discover a security vulnerability, please follow these steps:

### 1. **DO NOT** Open a Public Issue

Please do not report security vulnerabilities through public GitHub issues, discussions, or pull requests.

### 2. Report Privately

Instead, please report security issues by:

- **Preferred**: Use GitHub's [Security Advisories](https://github.com/fabioc-aloha/AlexQ_Template/security/advisories/new)
- **Alternative**: Open a private security advisory on the repository

### 3. Include in Your Report

To help us triage and fix the issue quickly, please include:

- **Description** of the vulnerability
- **Steps to reproduce** the issue
- **Potential impact** (what could an attacker do?)
- **Suggested fix** (if you have one)
- **Your contact information** for follow-up questions

### Example Report Template

```
## Vulnerability Description
Brief description of the security issue

## Steps to Reproduce
1. Step one
2. Step two
3. Step three

## Impact
What could an attacker do with this vulnerability?

## Affected Components
- File: path/to/file.cs
- Lines: 123-456
- Function: FunctionName()

## Suggested Fix
If applicable, describe how to fix the issue

## Environment
- Template Version: 1.0.0
- Operating System: Windows 11 / macOS / Linux
- Framework: .NET 8.0
```

---

## What to Expect

### Response Timeline

- **Initial Response**: Within 48 hours
- **Status Update**: Within 7 days
- **Fix Timeline**: Depends on severity (see below)

### Severity Levels

| Severity | Description | Target Fix Time |
|----------|-------------|-----------------|
| **Critical** | Exposes secrets, credentials, or allows remote code execution | 1-7 days |
| **High** | Significant security impact, affects multiple users | 7-14 days |
| **Medium** | Moderate security impact, limited scope | 14-30 days |
| **Low** | Minimal security impact, best practice improvements | 30-90 days |

### Our Commitment

- We will acknowledge receipt of your report within 48 hours
- We will provide a detailed response including:
  - Confirmation of the vulnerability (if valid)
  - Our assessment of severity
  - Timeline for a fix
- We will keep you informed of progress toward a fix
- We will credit you in the security advisory (if desired)

---

## Security Best Practices for Template Users

This template includes security best practices, but users must properly configure and deploy it:

### 🔐 Required Security Steps

1. **Never Commit Secrets**
   - Use `.env` files (already in `.gitignore`)
   - Use Azure Key Vault for production
   - Enable GitHub secret scanning

2. **Azure Security**
   - Enable Managed Identity (no keys in code)
   - Configure RBAC properly (use group-based pattern)
   - Use Azure Key Vault for all secrets
   - Enable Azure Monitor and alerts

3. **Webhook Security**
   - Always validate HMAC signatures (see `webhook-validator.cs`)
   - Use HTTPS endpoints only
   - Rotate webhook secrets regularly
   - Implement rate limiting

4. **API Security**
   - Implement rate limiting (see `rate-limiter.cs`)
   - Use exponential backoff (see `export-processor.cs`)
   - Monitor API usage
   - Respect Qualtrics rate limits (3000 RPM)

5. **Dependency Management**
   - Enable Dependabot security updates
   - Review and update NuGet packages regularly
   - Monitor GitHub security advisories
   - Test updates in non-production first

---

## Known Security Considerations

### Template Placeholders

This template contains many placeholders (e.g., `[your-api-token]`). When using this template:

- ⚠️ **Replace ALL placeholders** before deployment
- ⚠️ **Never commit actual secrets** to your repository
- ⚠️ **Use Azure Key Vault** for production secrets
- ⚠️ **Review `.env.example`** and create proper `.env`

### Configuration Files

The following files contain placeholders that MUST be updated:

- `.env.example` → Copy to `.env` and fill real values
- `qualtrics-config.json` → Update with actual survey/datacenter IDs
- Azure resource names → Update with actual resource names
- RBAC group → Update `[your-admin-group]` to your actual Azure AD group

### Azure Governance Note

The template includes Azure governance patterns using group-based RBAC (e.g., `[your-admin-group]`). This is an **example pattern** - update to match your organization's RBAC structure.

---

## Security Features Included

This template includes built-in security patterns:

✅ **HMAC Webhook Validation** (`webhook-validator.cs`)
✅ **Rate Limiting** (`rate-limiter.cs`)
✅ **Azure Key Vault Integration** (examples and documentation)
✅ **Managed Identity Patterns** (no keys in code)
✅ **Secure Configuration Loading** (environment variables)
✅ **Exponential Backoff** (prevent API abuse)
✅ **Comprehensive .gitignore** (prevents secret commits)

---

## Third-Party Dependencies

This template uses several NuGet packages. Users should:

1. **Monitor for vulnerabilities** using Dependabot
2. **Update regularly** to latest stable versions
3. **Review release notes** before updating
4. **Test updates** in non-production first

Key dependencies:
- `Polly` - Resilience and transient fault handling
- `Azure.Identity` - Azure authentication
- `Azure.Security.KeyVault.Secrets` - Secret management
- `Microsoft.AspNetCore.*` - Web framework

---

## Security Audit

This repository underwent a comprehensive security audit on November 10, 2025:

- ✅ No hardcoded secrets or credentials
- ✅ All configuration uses placeholders or environment variables
- ✅ Comprehensive .gitignore prevents secret commits
- ✅ Documentation emphasizes security best practices
- ✅ Code examples demonstrate proper secret management

**Full audit report**: See `SECURITY-AUDIT.md`

---

## Hall of Fame

We appreciate security researchers who help make this template safer:

<!-- Security contributors will be listed here -->
*No security issues reported yet*

---

## Questions?

For non-security questions, please:
- Open a [GitHub Discussion](https://github.com/fabioc-aloha/AlexQ_Template/discussions)
- Open a regular [GitHub Issue](https://github.com/fabioc-aloha/AlexQ_Template/issues)
- Review the [documentation](README.md)

**Only use security reporting channels for actual security vulnerabilities.**

---

*Last Updated: November 10, 2025*
*Template Version: 1.0.0*
