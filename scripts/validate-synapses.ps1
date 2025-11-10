# Comprehensive Synapse Detection Validation
# Verifies synapse patterns across ALL memory files and domain knowledge

# Auto-detect working directory and adjust paths
$currentDir = Get-Location
$isRunningFromScripts = (Split-Path -Leaf $currentDir) -eq "scripts"

if ($isRunningFromScripts) {
    # Running from scripts/ directory, need to go up one level
    Set-Location ".."
}

$SynapsePatterns = @{
    "Full_Format" = '\[([^\]]+\.md)\]\s*\(([^,)]+)(?:,\s*([^,)]+))?(?:,\s*([^)]+))?\)\s*-\s*"([^"]*)"'
    "Basic_Reference" = '\[([^\]]+\.md)\](?!\s*\()'
    "Partial_Format" = '\[([^\]]+\.md)\]\s*\([^)]*\)'
}

Write-Host "🔍 Comprehensive Synapse Pattern Detection Analysis" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor DarkGray

# Get all memory and domain files
$AllFiles = @()
$AllFiles += Get-ChildItem ".github/instructions/*.md" -ErrorAction SilentlyContinue
$AllFiles += Get-ChildItem ".github/prompts/*.md" -ErrorAction SilentlyContinue  
$AllFiles += Get-ChildItem "domain-knowledge/*.md" -ErrorAction SilentlyContinue
$AllFiles += Get-ChildItem ".github/copilot-instructions.md" -ErrorAction SilentlyContinue

$TotalResults = @{}
$DetailedResults = @()

foreach ($pattern in $SynapsePatterns.Keys) {
    $regex = $SynapsePatterns[$pattern]
    $patternResults = @()
    
    Write-Host "`n📊 Pattern: $pattern" -ForegroundColor Yellow
    Write-Host "Regex: $regex" -ForegroundColor Gray
    
    foreach ($file in $AllFiles) {
        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
        if ($content) {
            $synapseMatches = [regex]::Matches($content, $regex)
            if ($synapseMatches.Count -gt 0) {
                $patternResults += @{
                    File = $file.Name
                    Count = $synapseMatches.Count
                    Matches = $synapseMatches
                }
                Write-Host "  ✅ $($file.Name): $($synapseMatches.Count) matches" -ForegroundColor Green
            }
        }
    }
    
    $total = ($patternResults | Measure-Object -Property Count -Sum).Sum
    $TotalResults[$pattern] = $total
    $DetailedResults += @{
        Pattern = $pattern
        Total = $total
        Files = $patternResults
    }
    
    Write-Host "  📈 Total for $pattern`: $total matches" -ForegroundColor Cyan
}

Write-Host ("`n" + "=" * 60) -ForegroundColor DarkGray
Write-Host "🎯 SUMMARY RESULTS" -ForegroundColor Magenta

foreach ($pattern in $TotalResults.Keys) {
    Write-Host "  $pattern`: $($TotalResults[$pattern]) synapses detected" -ForegroundColor White
}

# Check for potential missed patterns
Write-Host "`n🔍 Pattern Overlap Analysis:" -ForegroundColor Yellow
$basicRefFiles = ($DetailedResults | Where-Object {$_.Pattern -eq "Basic_Reference"}).Files

if ($basicRefFiles) {
    Write-Host "⚠️  Basic references found (potential synapse candidates):" -ForegroundColor DarkYellow
    foreach ($fileResult in $basicRefFiles) {
        Write-Host "    - $($fileResult.File): $($fileResult.Count) basic references" -ForegroundColor Gray
    }
}

Write-Host "`n✅ Synapse Detection Validation Complete" -ForegroundColor Green
