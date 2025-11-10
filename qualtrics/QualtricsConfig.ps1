<#
.SYNOPSIS
    Load Qualtrics API configuration from qualtrics-config.json

.DESCRIPTION
    Provides easy access to Qualtrics API settings, survey IDs, distribution
    configuration, and webhook settings for all environments. This is the single
    source of truth for Qualtrics configuration.

.PARAMETER Environment
    The environment to load configuration for (dev, stg, prod)

.PARAMETER ConfigSection
    Optional: Filter to specific configuration section (api, surveys, distributions, etc.)

.EXAMPLE
    # Load dev environment configuration
    $config = Get-QualtricsConfig -Environment dev
    
    # Access specific settings
    $config.api.baseUrl              # https://api.qualtrics.com
    $config.api.dataCenter           # fra1
    $config.surveys.primary.id       # SURVEY_ID_DEV
    $config.distributions.pollingInterval  # 60

.EXAMPLE
    # Get just survey config for production
    $surveyConfig = Get-QualtricsConfig -Environment prod -ConfigSection surveys
    $surveyConfig.primary.id         # SURVEY_ID_PROD
    $surveyConfig.primary.name       # Production Survey

.EXAMPLE
    # Use in script to poll distributions
    $config = Get-QualtricsConfig -Environment dev
    $apiUrl = "$($config.api.baseUrl)$($config.shared.endpoints.distributions)"
    $pollingInterval = $config.distributions.pollingInterval
    # Poll every 60 seconds

.EXAMPLE
    # Access shared endpoints
    $config = Get-QualtricsConfig -Environment dev
    $surveysEndpoint = $config.shared.endpoints.surveys
    # Result: /API/v3/surveys

.EXAMPLE
    # Get rate limits
    $config = Get-QualtricsConfig -Environment prod
    $maxRequests = $config.rateLimits.requestsPerMinute
    # Production has higher limits
#>

function Get-QualtricsConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('dev', 'stg', 'prod')]
        [string]$Environment,

        [Parameter(Mandatory = $false)]
        [ValidateSet('api', 'authentication', 'surveys', 'distributions', 'webhook', 'rateLimits', 'features', 'shared')]
        [string]$ConfigSection
    )

    # Find the config file
    $configPath = Join-Path $PSScriptRoot ".." "qualtrics-config.json"
    
    if (-not (Test-Path $configPath)) {
        throw "Qualtrics configuration file not found: $configPath"
    }

    Write-Verbose "Loading Qualtrics configuration from: $configPath"
    $configJson = Get-Content $configPath -Raw | ConvertFrom-Json

    # Get environment-specific configuration
    $envConfig = $configJson.environments.$Environment
    if (-not $envConfig) {
        throw "Configuration for environment '$Environment' not found in qualtrics-config.json"
    }

    # Add shared configuration to environment config
    $config = [PSCustomObject]@{
        api = $envConfig.api
        authentication = $envConfig.authentication
        surveys = $envConfig.surveys
        distributions = $envConfig.distributions
        webhook = $envConfig.webhook
        rateLimits = $envConfig.rateLimits
        features = $envConfig.features
        shared = $configJson.shared
    }

    # Return specific section if requested
    if ($ConfigSection) {
        return $config.$ConfigSection
    }

    return $config
}

<#
.SYNOPSIS
    Get a fully qualified Qualtrics API endpoint URL

.DESCRIPTION
    Combines the base URL, data center, and endpoint path to create a complete API URL

.PARAMETER Environment
    The environment (dev, stg, prod)

.PARAMETER EndpointPath
    The endpoint path (e.g., '/API/v3/surveys' or use named endpoints like 'surveys', 'distributions')

.PARAMETER SurveyId
    Optional: Survey ID to inject into endpoint path (for endpoints requiring {surveyId})

.PARAMETER MailingListId
    Optional: Mailing list ID to inject into endpoint path

.EXAMPLE
    # Get surveys endpoint
    $url = Get-QualtricsApiUrl -Environment dev -EndpointPath 'surveys'
    # Result: https://api.qualtrics.com/API/v3/surveys

.EXAMPLE
    # Get responses endpoint for specific survey
    $url = Get-QualtricsApiUrl -Environment prod -EndpointPath 'responses' -SurveyId 'SV_abc123'
    # Result: https://api.qualtrics.com/API/v3/surveys/SV_abc123/responses

.EXAMPLE
    # Custom endpoint
    $url = Get-QualtricsApiUrl -Environment dev -EndpointPath '/API/v3/custom/endpoint'
    # Result: https://api.qualtrics.com/API/v3/custom/endpoint
#>

function Get-QualtricsApiUrl {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('dev', 'stg', 'prod')]
        [string]$Environment,

        [Parameter(Mandatory = $true)]
        [string]$EndpointPath,

        [Parameter(Mandatory = $false)]
        [string]$SurveyId,

        [Parameter(Mandatory = $false)]
        [string]$MailingListId
    )

    $config = Get-QualtricsConfig -Environment $Environment
    $baseUrl = $config.api.baseUrl

    # Check if EndpointPath is a named endpoint
    $namedEndpoints = @{
        'surveys' = $config.shared.endpoints.surveys
        'responses' = $config.shared.endpoints.responses
        'distributions' = $config.shared.endpoints.distributions
        'mailingLists' = $config.shared.endpoints.mailingLists
        'contacts' = $config.shared.endpoints.contacts
    }

    if ($namedEndpoints.ContainsKey($EndpointPath)) {
        $EndpointPath = $namedEndpoints[$EndpointPath]
    }

    # Replace placeholders
    if ($SurveyId) {
        $EndpointPath = $EndpointPath -replace '\{surveyId\}', $SurveyId
    }
    if ($MailingListId) {
        $EndpointPath = $EndpointPath -replace '\{mailingListId\}', $MailingListId
    }

    # Ensure endpoint starts with /
    if (-not $EndpointPath.StartsWith('/')) {
        $EndpointPath = "/$EndpointPath"
    }

    return "$baseUrl$EndpointPath"
}

<#
.SYNOPSIS
    Test if Qualtrics configuration is valid for the specified environment

.DESCRIPTION
    Validates that all required configuration sections exist and contain expected values

.PARAMETER Environment
    The environment to test (dev, stg, prod)

.EXAMPLE
    Test-QualtricsConfig -Environment dev
    # Returns $true if configuration is valid, $false otherwise
#>

function Test-QualtricsConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('dev', 'stg', 'prod')]
        [string]$Environment
    )

    try {
        $config = Get-QualtricsConfig -Environment $Environment
        
        # Validate required sections
        $requiredSections = @('api', 'authentication', 'surveys', 'distributions', 'webhook', 'rateLimits', 'features', 'shared')
        foreach ($section in $requiredSections) {
            if (-not $config.$section) {
                Write-Error "Missing required configuration section: $section"
                return $false
            }
        }

        # Validate API settings
        if ([string]::IsNullOrWhiteSpace($config.api.baseUrl)) {
            Write-Error "API base URL is not configured"
            return $false
        }
        if ([string]::IsNullOrWhiteSpace($config.api.dataCenter)) {
            Write-Error "Data center is not configured"
            return $false
        }

        # Validate survey ID is set (not placeholder)
        if ($config.surveys.primary.id -like "SURVEY_ID_*") {
            Write-Warning "Survey ID is still set to placeholder value: $($config.surveys.primary.id)"
            Write-Warning "Update qualtrics-config.json with actual survey ID for $Environment environment"
        }

        Write-Verbose "Qualtrics configuration for '$Environment' is valid"
        return $true
    }
    catch {
        Write-Error "Failed to validate Qualtrics configuration: $_"
        return $false
    }
}

# Only export if running as a module (not dot-sourced)
if ($MyInvocation.MyCommand.CommandType -eq 'ExternalScript') {
    # Dot-sourced - functions are already in scope
}
else {
    # Running as module
    Export-ModuleMember -Function Get-QualtricsConfig, Get-QualtricsApiUrl, Test-QualtricsConfig
}
