# Setup New Project from Template
# This script helps initialize a new Qualtrics + Azure project from the template
# 
# Usage: .\setup-new-project.ps1 -ProjectName "MyProject" -AzureSubscription "sub-id"

param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectName,
    
    [Parameter(Mandatory=$false)]
    [string]$AzureSubscription,
    
    [Parameter(Mandatory=$false)]
    [string]$AzureResourceGroup,
    
    [Parameter(Mandatory=$false)]
    [string]$QualtricsDataCenter = "iad1",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipAzureResources,
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  Qualtrics + Azure Project Setup                        ║" -ForegroundColor Cyan
Write-Host "║  Template Version: 1.0.0                                ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Validate project name
if ($ProjectName -notmatch '^[a-zA-Z][a-zA-Z0-9-]*$') {
    Write-Error "Project name must start with a letter and contain only letters, numbers, and hyphens"
}

$ProjectNameLower = $ProjectName.ToLower()
Write-Host "📦 Project Name: $ProjectName" -ForegroundColor Green
Write-Host ""

# Step 1: Update placeholders in key files
Write-Host "📝 Step 1: Updating project placeholders..." -ForegroundColor Yellow

$filesToUpdate = @(
    "README.md",
    ".env.example",
    "plan/SAMPLE-PROJECT-PLAN.md",
    "TEMPLATE-README.md"
)

$placeholders = @{
    "[Your Project Name]" = $ProjectName
    "[your-project-name]" = $ProjectNameLower
    "[YYYY-MM-DD]" = (Get-Date -Format "yyyy-MM-dd")
    "[Project Owner]" = $env:USERNAME
}

if (-not $DryRun) {
    foreach ($file in $filesToUpdate) {
        if (Test-Path $file) {
            Write-Host "  Updating $file..." -ForegroundColor Gray
            $content = Get-Content $file -Raw
            
            foreach ($placeholder in $placeholders.Keys) {
                $content = $content.Replace($placeholder, $placeholders[$placeholder])
            }
            
            Set-Content $file -Value $content -NoNewline
        }
    }
    Write-Host "  ✓ Placeholders updated" -ForegroundColor Green
} else {
    Write-Host "  [DRY RUN] Would update placeholders in $($filesToUpdate.Count) files" -ForegroundColor Gray
}
Write-Host ""

# Step 2: Create .env from .env.example
Write-Host "🔧 Step 2: Creating .env file..." -ForegroundColor Yellow

if (-not $DryRun) {
    if (-not (Test-Path ".env")) {
        Copy-Item ".env.example" ".env"
        Write-Host "  ✓ Created .env file from .env.example" -ForegroundColor Green
        Write-Host "  ⚠️  Remember to fill in your actual values in .env!" -ForegroundColor Yellow
    } else {
        Write-Host "  ⚠️  .env already exists, skipping" -ForegroundColor Gray
    }
} else {
    Write-Host "  [DRY RUN] Would create .env from .env.example" -ForegroundColor Gray
}
Write-Host ""

# Step 3: Azure Resources (if not skipped)
if (-not $SkipAzureResources) {
    Write-Host "☁️  Step 3: Azure Resources Setup..." -ForegroundColor Yellow
    
    if ([string]::IsNullOrEmpty($AzureSubscription)) {
        Write-Host "  ⚠️  No Azure subscription provided. Skipping Azure setup." -ForegroundColor Yellow
        Write-Host "  💡 Run with -AzureSubscription <subscription-id> to provision resources" -ForegroundColor Cyan
    } else {
        Write-Host "  Subscription: $AzureSubscription" -ForegroundColor Gray
        
        # Set Azure context
        if (-not $DryRun) {
            try {
                Write-Host "  Setting Azure context..." -ForegroundColor Gray
                az account set --subscription $AzureSubscription
                Write-Host "  ✓ Azure context set" -ForegroundColor Green
            } catch {
                Write-Error "Failed to set Azure context. Ensure Azure CLI is installed and you're logged in (az login)"
            }
        }
        
        # Create resource group if provided
        if (-not [string]::IsNullOrEmpty($AzureResourceGroup)) {
            $location = "eastus"
            Write-Host "  Creating resource group: $AzureResourceGroup in $location..." -ForegroundColor Gray
            
            if (-not $DryRun) {
                az group create --name $AzureResourceGroup --location $location
                Write-Host "  ✓ Resource group created" -ForegroundColor Green
            } else {
                Write-Host "  [DRY RUN] Would create resource group $AzureResourceGroup" -ForegroundColor Gray
            }
        }
        
        # Suggest Azure resources to create
        Write-Host ""
        Write-Host "  📋 Recommended Azure Resources:" -ForegroundColor Cyan
        Write-Host "     • Azure Key Vault (secrets: $ProjectNameLower-kv)" -ForegroundColor Gray
        Write-Host "     • Azure Cosmos DB (database: $ProjectNameLower-cosmos)" -ForegroundColor Gray
        Write-Host "     • Azure SignalR Service (real-time: $ProjectNameLower-signalr)" -ForegroundColor Gray
        Write-Host "     • Azure Container Apps (hosting: $ProjectNameLower-app)" -ForegroundColor Gray
        Write-Host "     • Application Insights (monitoring: $ProjectNameLower-insights)" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  💡 Use Azure Portal or Bicep/Terraform for infrastructure provisioning" -ForegroundColor Cyan
        Write-Host "  📖 See TEMPLATE-QUALTRICS-AZURE-PROJECT.md for architecture guidance" -ForegroundColor Cyan
    }
} else {
    Write-Host "☁️  Step 3: Skipping Azure resources setup (--SkipAzureResources specified)" -ForegroundColor Gray
}
Write-Host ""

# Step 4: Initialize Git (if not already initialized)
Write-Host "📦 Step 4: Git Repository Setup..." -ForegroundColor Yellow

if (Test-Path ".git") {
    Write-Host "  ✓ Git repository already initialized" -ForegroundColor Green
} else {
    if (-not $DryRun) {
        git init
        Write-Host "  ✓ Git repository initialized" -ForegroundColor Green
    } else {
        Write-Host "  [DRY RUN] Would initialize git repository" -ForegroundColor Gray
    }
}
Write-Host ""

# Step 5: Create initial project structure
Write-Host "📁 Step 5: Project Structure..." -ForegroundColor Yellow

$directories = @(
    "src",
    "tests",
    "docs",
    "infrastructure",
    ".vscode"
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        if (-not $DryRun) {
            New-Item -ItemType Directory -Path $dir | Out-Null
            Write-Host "  ✓ Created $dir/" -ForegroundColor Green
        } else {
            Write-Host "  [DRY RUN] Would create $dir/" -ForegroundColor Gray
        }
    } else {
        Write-Host "  ✓ $dir/ exists" -ForegroundColor Gray
    }
}
Write-Host ""

# Step 6: Summary and next steps
Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  ✓ Project Setup Complete!                              ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

Write-Host "📋 Next Steps:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Configure Environment" -ForegroundColor Yellow
Write-Host "   • Edit .env file with your Qualtrics API token" -ForegroundColor Gray
Write-Host "   • Update Azure resource names" -ForegroundColor Gray
Write-Host "   • Set datacenter: $QualtricsDataCenter" -ForegroundColor Gray
Write-Host ""

Write-Host "2. Review Documentation" -ForegroundColor Yellow
Write-Host "   • Read domain-knowledge/DK-QUALTRICS-API-v1.0.0.md (140+ endpoints)" -ForegroundColor Gray
Write-Host "   • Study TEMPLATE-QUALTRICS-AZURE-PROJECT.md (architecture patterns)" -ForegroundColor Gray
Write-Host "   • Check examples/ directory (webhook, export, rate-limiter)" -ForegroundColor Gray
Write-Host ""

Write-Host "3. Update Project Plan" -ForegroundColor Yellow
Write-Host "   • Customize plan/SAMPLE-PROJECT-PLAN.md for your needs" -ForegroundColor Gray
Write-Host "   • Replace remaining [placeholders] with specifics" -ForegroundColor Gray
Write-Host "   • Define your success metrics and timeline" -ForegroundColor Gray
Write-Host ""

Write-Host "4. Provision Azure Resources" -ForegroundColor Yellow
if ([string]::IsNullOrEmpty($AzureResourceGroup)) {
    Write-Host "   • Create resource group first" -ForegroundColor Gray
} else {
    Write-Host "   • Resource group: $AzureResourceGroup" -ForegroundColor Gray
}
Write-Host "   • Deploy Key Vault, Cosmos DB, SignalR" -ForegroundColor Gray
Write-Host "   • Configure Managed Identity and RBAC" -ForegroundColor Gray
Write-Host ""

Write-Host "5. Start Development" -ForegroundColor Yellow
Write-Host "   • Copy code from examples/ to src/" -ForegroundColor Gray
Write-Host "   • Implement QualtricsService based on DK patterns" -ForegroundColor Gray
Write-Host "   • Test with Qualtrics API sandbox" -ForegroundColor Gray
Write-Host ""

Write-Host "📖 Documentation:" -ForegroundColor Cyan
Write-Host "   • Quick Start: TEMPLATE-README.md" -ForegroundColor Gray
Write-Host "   • API Reference: domain-knowledge/DK-QUALTRICS-API-v1.0.0.md" -ForegroundColor Gray
Write-Host "   • Architecture: TEMPLATE-QUALTRICS-AZURE-PROJECT.md" -ForegroundColor Gray
Write-Host "   • Plan Template: plan/SAMPLE-PROJECT-PLAN.md" -ForegroundColor Gray
Write-Host ""

Write-Host "🤖 Alex Q Integration:" -ForegroundColor Cyan
Write-Host "   • Domain knowledge files are AI-readable" -ForegroundColor Gray
Write-Host "   • Use 'Ask about [topic]' to leverage expertise" -ForegroundColor Gray
Write-Host "   • Template patterns optimized for AI-assisted development" -ForegroundColor Gray
Write-Host ""

Write-Host "Happy coding! 🚀" -ForegroundColor Green
Write-Host ""

# Export project info for later use
$projectInfo = @{
    ProjectName = $ProjectName
    ProjectNameLower = $ProjectNameLower
    CreatedDate = Get-Date -Format "yyyy-MM-dd"
    Creator = $env:USERNAME
    AzureSubscription = $AzureSubscription
    AzureResourceGroup = $AzureResourceGroup
    QualtricsDataCenter = $QualtricsDataCenter
    TemplateVersion = "1.0.0"
}

if (-not $DryRun) {
    $projectInfo | ConvertTo-Json | Out-File ".project-info.json" -Encoding UTF8
    Write-Host "💾 Project info saved to .project-info.json" -ForegroundColor Gray
    Write-Host ""
}
