# Qualtrics Configuration System

**Version**: 1.0.0
**Status**: ✅ Operational
**Single Source of Truth**: `qualtrics-config.json`

## Overview

The Qualtrics configuration system provides centralized, environment-specific configuration for all Qualtrics API integration. This follows the same proven pattern as the Azure resource configuration system.

## Architecture

```
qualtrics-config.json (Single Source of Truth)
├── environments
│   ├── dev      - Development environment settings
│   ├── stg      - Staging environment settings
│   └── prod     - Production environment settings
└── shared       - Settings common across all environments

↓ Loaded by ↓

scripts/QualtricsConfig.ps1 (PowerShell Module)
├── Get-QualtricsConfig     - Load configuration
├── Get-QualtricsApiUrl     - Build API endpoints
└── Test-QualtricsConfig    - Validate configuration

↓ Synced by ↓

scripts/Update-AppSettings.ps1
└── Syncs both azure-resources.json + qualtrics-config.json → appsettings.json

↓ Used by ↓

C# Application (QualtricsOptions)
└── Reads from appsettings.json at runtime
```

## Configuration File Structure

### Environment-Specific Settings

Each environment (dev, stg, prod) contains:

#### API Configuration
```json
"api": {
  "baseUrl": "https://api.qualtrics.com",
  "dataCenter": "fra1",
  "dataCenterUrl": "https://fra1.qualtrics.com",
  "timeout": 30000,
  "maxRetries": 3,
  "retryDelayMs": 1000
}
```

#### Authentication
```json
"authentication": {
  "tokenSource": "KeyVault",
  "keyVaultSecretName": "Qualtrics--ApiToken"
}
```

#### Surveys
```json
"surveys": {
  "primary": {
    "id": "SURVEY_ID_DEV",
    "name": "Development Survey",
    "description": "Primary survey for development testing"
  }
}
```

#### Distribution Settings
```json
"distributions": {
  "pollingInterval": 60,
  "maxConcurrentPolls": 5,
  "dispositionMapping": {
    "Complete": "Completed",
    "PartiallyComplete": "PartiallyCompleted",
    // ... more mappings
  }
}
```

#### Webhook Configuration
```json
"webhook": {
  "enabled": true,
  "eventTypes": [
    "response.created",
    "response.updated",
    "distribution.created",
    "distribution.status"
  ],
  "retryPolicy": {
    "maxRetries": 3,
    "retryDelayMs": 5000
  }
}
```

#### Rate Limits
```json
"rateLimits": {
  "requestsPerMinute": 60,
  "requestsPerHour": 1000,
  "burstLimit": 10
}
```

#### Feature Flags
```json
"features": {
  "enableDistributionPolling": true,
  "enableWebhooks": true,
  "enableResponseCaching": true,
  "cacheExpirationMinutes": 5
}
```

### Shared Settings

Common across all environments:

#### API Endpoints
```json
"endpoints": {
  "surveys": "/API/v3/surveys",
  "responses": "/API/v3/surveys/{surveyId}/responses",
  "distributions": "/API/v3/distributions",
  "mailingLists": "/API/v3/mailinglists",
  "contacts": "/API/v3/mailinglists/{mailingListId}/contacts"
}
```

#### HTTP Headers
```json
"headers": {
  "contentType": "application/json",
  "userAgent": "QualticsDashboard/1.0"
}
```

#### Disposition Status Mapping
```json
"dispositionStatuses": {
  "completed": ["Complete", "Completed"],
  "partiallyCompleted": ["PartiallyComplete", "PartiallyCompleted", "Started"],
  "sent": ["EmailSent", "Sent"],
  // ... more status mappings
}
```

## PowerShell Usage

### Loading Configuration

```powershell
# Load configuration module
. .\scripts\QualtricsConfig.ps1

# Get dev environment configuration
$config = Get-QualtricsConfig -Environment dev

# Access specific settings
$apiUrl = $config.api.baseUrl           # https://api.qualtrics.com
$dataCenter = $config.api.dataCenter    # fra1
$surveyId = $config.surveys.primary.id  # SURVEY_ID_DEV
$pollingInterval = $config.distributions.pollingInterval  # 60
```

### Getting Specific Configuration Section

```powershell
# Get just survey configuration
$surveys = Get-QualtricsConfig -Environment prod -ConfigSection surveys
$primarySurveyId = $surveys.primary.id

# Get API configuration only
$apiConfig = Get-QualtricsConfig -Environment stg -ConfigSection api
```

### Building API URLs

```powershell
# Get surveys endpoint
$url = Get-QualtricsApiUrl -Environment dev -EndpointPath 'surveys'
# Result: https://api.qualtrics.com/API/v3/surveys

# Get responses endpoint for specific survey
$url = Get-QualtricsApiUrl -Environment prod `
    -EndpointPath 'responses' `
    -SurveyId 'SV_abc123'
# Result: https://api.qualtrics.com/API/v3/surveys/SV_abc123/responses

# Get contacts endpoint
$url = Get-QualtricsApiUrl -Environment dev `
    -EndpointPath 'contacts' `
    -MailingListId 'ML_xyz789'
# Result: https://api.qualtrics.com/API/v3/mailinglists/ML_xyz789/contacts

# Custom endpoint
$url = Get-QualtricsApiUrl -Environment dev `
    -EndpointPath '/API/v3/custom/endpoint'
# Result: https://api.qualtrics.com/API/v3/custom/endpoint
```

### Validating Configuration

```powershell
# Test configuration validity
if (Test-QualtricsConfig -Environment dev) {
    Write-Host "Configuration is valid"
}
else {
    Write-Host "Configuration has issues"
}
```

## C# Usage

### Configuration Class

```csharp
using QualticsDashboard.Core.Configuration;
using Microsoft.Extensions.Options;

public class MyService
{
    private readonly QualtricsOptions _options;

    public MyService(IOptions<QualtricsOptions> options)
    {
        _options = options.Value;
    }

    public void UseConfiguration()
    {
        var apiUrl = _options.ApiBaseUrl;           // https://api.qualtrics.com
        var dataCenter = _options.DataCenter;       // fra1
        var timeout = _options.Timeout;             // 30000
        var maxRetries = _options.MaxRetries;       // 3
        var pollingInterval = _options.PollingInterval; // 60
    }
}
```

### Dependency Injection Setup

Already configured in `Program.cs`:

```csharp
builder.Services.Configure<QualtricsOptions>(
    builder.Configuration.GetSection(QualtricsOptions.SectionName)
);
```

## Syncing Configuration to C#

Use the `Update-AppSettings.ps1` script to sync configuration:

```powershell
# Sync configuration for dev environment
.\scripts\Update-AppSettings.ps1 -Environment dev

# Sync with Azure resource discovery
.\scripts\Update-AppSettings.ps1 -Environment dev -DiscoverResources

# Sync for production
.\scripts\Update-AppSettings.ps1 -Environment prod -DiscoverResources
```

This script:
1. Loads `azure-resources.json` for Azure configuration
2. Loads `qualtrics-config.json` for Qualtrics configuration
3. Updates `src/QualticsDashboard.Api/appsettings.json` with both
4. Preserves all other appsettings.json properties

## Configuration Setup Steps

### 1. Update Survey IDs

Edit `qualtrics-config.json` and replace placeholder survey IDs:

```json
"surveys": {
  "primary": {
    "id": "SV_yourActualSurveyId",  // ← Replace SURVEY_ID_DEV with real ID
    "name": "Development Survey",
    "description": "Primary survey for development testing"
  }
}
```

Do this for all environments (dev, stg, prod).

### 2. Configure Data Center

If your Qualtrics instance is not in `fra1`, update the data center:

```json
"api": {
  "baseUrl": "https://api.qualtrics.com",
  "dataCenter": "yourdatacenterid",  // ← Update this
  "dataCenterUrl": "https://yourdatacenterid.qualtrics.com",  // ← Update this
  // ...
}
```

Common data centers: `fra1` (Frankfurt), `ca1` (Canada), `az1` (Arizona), etc.

### 3. Store API Token in Key Vault

```powershell
# Set the API token in Key Vault (one time per environment)
az keyvault secret set \
  --vault-name kv-qd-dev-jk463tx7e5bwg \
  --name "Qualtrics--ApiToken" \
  --value "YOUR_ACTUAL_API_TOKEN"
```

The application retrieves this token at runtime using Managed Identity.

### 4. Sync Configuration

```powershell
# Sync to appsettings.json
.\scripts\Update-AppSettings.ps1 -Environment dev -DiscoverResources
```

### 5. Verify Configuration

```powershell
# Test configuration validity
. .\scripts\QualtricsConfig.ps1
Test-QualtricsConfig -Environment dev
```

## Environment Differences

| Setting | Dev | Staging | Production |
|---------|-----|---------|------------|
| **Polling Interval** | 60s | 60s | 30s (more frequent) |
| **Max Retries** | 3 | 3 | 5 (more resilient) |
| **Retry Delay** | 1000ms | 1000ms | 2000ms |
| **Concurrent Polls** | 5 | 5 | 10 (higher throughput) |
| **Webhook Retry Delay** | 5000ms | 5000ms | 10000ms |
| **Survey ID** | DEV | STG | PROD (different surveys) |

Production has more aggressive retry policies and higher concurrency for better resilience and performance.

## Configuration Benefits

### Single Source of Truth
- One file (`qualtrics-config.json`) for all Qualtrics settings
- No hardcoded values in scripts or application code
- Easy to update and maintain

### Environment Consistency
- Same configuration structure across dev/stg/prod
- Only values differ, not structure
- Easy to compare environments

### Type Safety
- PowerShell module provides structured objects
- C# QualtricsOptions class with IntelliSense
- Compile-time checking in C#

### Validation
- `Test-QualtricsConfig` function validates configuration
- Warns about placeholder values
- Catches missing required settings

### Cross-Platform Integration
- PowerShell scripts use `QualtricsConfig.ps1`
- C# application uses `QualtricsOptions` class
- Both read from same source of truth
- `Update-AppSettings.ps1` keeps them in sync

## Scripts Using Qualtrics Configuration

Once scripts are migrated, they should use the configuration:

```powershell
# Example script usage
. "$PSScriptRoot\QualtricsConfig.ps1"
$config = Get-QualtricsConfig -Environment $Environment

$apiUrl = Get-QualtricsApiUrl -Environment $Environment -EndpointPath 'distributions'
$surveyId = $config.surveys.primary.id
$pollingInterval = $config.distributions.pollingInterval

# Use configuration in API calls
Invoke-RestMethod -Uri $apiUrl -Headers @{
    "X-API-TOKEN" = $apiToken
    "Content-Type" = $config.shared.headers.contentType
}
```

## Maintenance

### Adding New Configuration

1. Add to `qualtrics-config.json` in appropriate section
2. Update `Update-AppSettings.ps1` if needed for C# sync
3. Update `QualtricsOptions.cs` if exposing to C# application
4. Run `Update-AppSettings.ps1` to sync
5. Update documentation

### Updating Survey IDs

```powershell
# Update qualtrics-config.json with new survey ID
# Then sync to application
.\scripts\Update-AppSettings.ps1 -Environment dev
```

### Changing Data Center

1. Update `api.dataCenter` and `api.dataCenterUrl` in `qualtrics-config.json`
2. Run `Update-AppSettings.ps1`
3. Test configuration with `Test-QualtricsConfig`

## Troubleshooting

### Configuration not loading
```powershell
# Verify file exists
Test-Path .\qualtrics-config.json

# Check JSON syntax
Get-Content .\qualtrics-config.json | ConvertFrom-Json
```

### Survey ID still placeholder
```powershell
# Load config and check
. .\scripts\QualtricsConfig.ps1
$config = Get-QualtricsConfig -Environment dev
$config.surveys.primary.id  # Should not be "SURVEY_ID_DEV"
```

### Configuration not syncing to appsettings.json
```powershell
# Run sync script with verbose output
.\scripts\Update-AppSettings.ps1 -Environment dev -Verbose

# Verify appsettings.json was updated
Get-Content src\QualticsDashboard.Api\appsettings.json | ConvertFrom-Json |
    Select-Object -ExpandProperty Qualtrics
```

## Related Files

- **Configuration**: `qualtrics-config.json` (root directory)
- **PowerShell Module**: `scripts/QualtricsConfig.ps1`
- **Sync Script**: `scripts/Update-AppSettings.ps1`
- **C# Options**: `src/QualticsDashboard.Core/Configuration/QualtricsOptions.cs`
- **Application Settings**: `src/QualticsDashboard.Api/appsettings.json`
- **Azure Configuration**: `azure-resources.json` (parallel system)

## See Also

- [Azure Resource Configuration](infrastructure/README.md#configuration-management-system)
- [Qualtrics API Documentation](https://api.qualtrics.com/ZG9jOjg3NzY3Mg-api-quick-start)
- [Configuration Management Domain Knowledge](domain-knowledge/DK-CONFIGURATION-MANAGEMENT-v1.0.0.md)
