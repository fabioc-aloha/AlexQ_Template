# Qualtrics Documentation Hub

Centralized repository for all Qualtrics API integration documentation.

## 📚 Documentation Index

### 🎯 Primary API Reference (Essential)
- **[DK-QUALTRICS-API-v1.0.0.md](DK-QUALTRICS-API-v1.0.0.md)** (2,378 lines)
  **THE** definitive Qualtrics API reference - 140+ endpoints, 100% verified, production-ready code examples

- **[QUALTRICS-API-QUICK-REF.md](QUALTRICS-API-QUICK-REF.md)**
  Quick reference guide for developers - rate limits, critical endpoints, common patterns

### Configuration & Setup
- **[qualtrics-config.json](qualtrics-config.json)**
  Template configuration file with API settings and survey mappings

- **[QualtricsConfig.ps1](QualtricsConfig.ps1)**
  PowerShell script for Qualtrics configuration management

- **[qualtrics-dashboard.instructions.md](qualtrics-dashboard.instructions.md)**
  Development guidelines and patterns for Qualtrics Dashboard project

---

## 🔧 Quick Access

### Configuration
```json
// qualtrics-config.json structure
{
  "dataCenter": "iad1",
  "apiToken": "[Set in Azure App Settings]",
  "surveys": {
    "surveyId": "config..."
  }
}
```

### API Endpoints
- **Base URL**: `https://{dataCenter}.qualtrics.com/API/v3/`
- **Authentication**: `X-API-TOKEN` header
- **Rate Limiting**: 3,000 requests/minute brand-level (per-endpoint limits in DK file)

### Key Integration Points
- **Configuration**: Template in qualtrics-config.json
- **Webhooks**: HMAC validation, form-urlencoded payloads (see DK-QUALTRICS-API)
- **Rate Limiting**: Per-endpoint optimization strategies documented
- **Three-Tier Architecture**: Historical (export) + Real-Time (webhooks) + Aggregate (distributions)

---

## 📖 Quick Start Guide

### For Template Users
1. **Read** `DK-QUALTRICS-API-v1.0.0.md` - Complete API reference (THE authoritative source)
2. **Review** `QUALTRICS-API-QUICK-REF.md` - Quick reference for common operations
3. **Configure** `qualtrics-config.json` - Update with your survey IDs and datacenter
4. **Implement** using production-ready code examples from DK file

### For API Integration
- **140+ Endpoints Documented**: Complete reference in DK-QUALTRICS-API-v1.0.0.md
- **Production Code Examples**: Webhook handlers, export workflows, polling patterns
- **Security Best Practices**: HMAC validation, Key Vault integration, Managed Identity
- **Rate Limit Optimization**: Per-endpoint limits, budget calculations, strategies

### For Webhook Implementation
1. Reference webhook section in `DK-QUALTRICS-API-v1.0.0.md` (lines ~1000-1200)
2. Implement HMAC-SHA256 validation (code example provided)
3. Handle form-urlencoded payloads (NOT JSON)
4. Return 200 within 5 seconds, queue to Service Bus for processing

---

## 🎯 Essential Information

**Primary Documentation**: [DK-QUALTRICS-API-v1.0.0.md](DK-QUALTRICS-API-v1.0.0.md)
- 2,378 lines of comprehensive, 100% verified documentation
- 140+ endpoints with parameters, responses, error handling
- Production-ready code examples (Python, Azure Functions)
- Security implementations (HMAC, encryption, Key Vault)
- Rate limit optimization strategies
- Three-tier architecture patterns

**All other files support or reference this primary documentation.**

---

*Last Updated: November 10, 2025*
*Total Documentation: 13 files (226KB)*
