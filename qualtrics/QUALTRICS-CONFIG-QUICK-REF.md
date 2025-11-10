# Qualtrics Configuration Quick Reference

## 🎯 Quick Start

```powershell
# 1. Load configuration
. .\scripts\QualtricsConfig.ps1
$config = Get-QualtricsConfig -Environment dev

# 2. Sync to C# application
.\scripts\Update-AppSettings.ps1 -Environment dev -DiscoverResources

# 3. Access in C# via IOptions<QualtricsOptions>
```

## 📂 Key Files

| File | Purpose |
|------|---------|
| `qualtrics-config.json` | **Single source of truth** - All Qualtrics settings |
| `scripts/QualtricsConfig.ps1` | PowerShell module to load configuration |
| `scripts/Update-AppSettings.ps1` | Syncs config to appsettings.json |
| `src/.../QualtricsOptions.cs` | C# configuration class |

## 🔧 Common Tasks

### Get Configuration Value
```powershell
. .\scripts\QualtricsConfig.ps1
$config = Get-QualtricsConfig -Environment dev

$config.api.baseUrl              # https://api.qualtrics.com
$config.api.dataCenter           # fra1
$config.surveys.primary.id       # SURVEY_ID_DEV
$config.distributions.pollingInterval  # 60
```

### Build API URL
```powershell
# Surveys endpoint
Get-QualtricsApiUrl -Environment dev -EndpointPath 'surveys'
# → https://api.qualtrics.com/API/v3/surveys

# Responses for specific survey
Get-QualtricsApiUrl -Environment prod -EndpointPath 'responses' -SurveyId 'SV_abc123'
# → https://api.qualtrics.com/API/v3/surveys/SV_abc123/responses
```

### Update Survey ID
```powershell
# 1. Edit qualtrics-config.json
# "surveys": {
#   "primary": {
#     "id": "SV_yourActualSurveyId"  ← Update this
#   }
# }

# 2. Sync to appsettings.json
.\scripts\Update-AppSettings.ps1 -Environment dev
```

### Store API Token
```powershell
az keyvault secret set \
  --vault-name kv-qd-dev-jk463tx7e5bwg \
  --name "Qualtrics--ApiToken" \
  --value "YOUR_API_TOKEN"
```

## 🏗️ Configuration Structure

```json
{
  "environments": {
    "dev": {
      "api": { "baseUrl", "dataCenter", "timeout", "maxRetries" },
      "authentication": { "tokenSource", "keyVaultSecretName" },
      "surveys": { "primary": { "id", "name", "description" } },
      "distributions": { "pollingInterval", "maxConcurrentPolls", "dispositionMapping" },
      "webhook": { "enabled", "eventTypes", "retryPolicy" },
      "rateLimits": { "requestsPerMinute", "requestsPerHour", "burstLimit" },
      "features": { "enableDistributionPolling", "enableWebhooks", "enableResponseCaching" }
    },
    "stg": { /* same structure */ },
    "prod": { /* same structure */ }
  },
  "shared": {
    "endpoints": { "surveys", "responses", "distributions", "mailingLists", "contacts" },
    "headers": { "contentType", "userAgent" },
    "dispositionStatuses": { /* status mappings */ }
  }
}
```

## 💻 C# Usage

```csharp
public class MyService
{
    private readonly QualtricsOptions _options;

    public MyService(IOptions<QualtricsOptions> options)
    {
        _options = options.Value;
    }

    public void UseConfig()
    {
        var apiUrl = _options.ApiBaseUrl;      // https://api.qualtrics.com
        var dataCenter = _options.DataCenter;  // fra1
        var timeout = _options.Timeout;        // 30000
        var interval = _options.PollingInterval; // 60
    }
}
```

## ✅ Validation

```powershell
# Test configuration validity
. .\scripts\QualtricsConfig.ps1
Test-QualtricsConfig -Environment dev
```

## 📊 Environment Differences

| Setting | Dev | Prod |
|---------|-----|------|
| Polling Interval | 60s | 30s ⚡ |
| Max Retries | 3 | 5 🛡️ |
| Concurrent Polls | 5 | 10 ⚡ |
| Survey ID | DEV | PROD 🔒 |

## 🔗 See Full Documentation

[QUALTRICS-CONFIGURATION.md](QUALTRICS-CONFIGURATION.md)
