# Generic Neural Dream State Automation System - v1.1.0 DOCUMENTATION_EXCELLENCE

A configurable PowerShell-based cognitive architecture maintenance system for AI agents with embedded synaptic networks.

## 🧠 Overview

This system provides automated neural maintenance capabilities for cognitive architectures that use:
- File-based memory systems (procedural, episodic, domain knowledge)
- Embedded synapse network notation with 183+ validated connections
- Multi-file configuration management with dual-directory execution support
- Automated orphan detection and network optimization with health scoring
- Direct command execution with `dream --parameter` syntax

## 🚀 Quick Start

### 1. Dream Protocol Initialization
```powershell
# Load dream commands into current session
. scripts/init-dream.ps1
```

### 2. Basic Usage (Alex 'Mini' Finch Architecture - v1.1.0 DOCUMENTATION_EXCELLENCE)
```powershell
# Use the included Alex configuration with direct commands
dream --health-check
dream --status
dream --neural-maintenance
```

### 3. Alternative Script Execution Methods
```powershell
# From repository root
scripts/neural-dream.ps1 -HealthCheck

# From scripts directory
cd scripts
./neural-dream.ps1 -Status
```

### 4. Custom Cognitive Architecture
```powershell
# Create your own config file based on template
Copy-Item scripts/cognitive-config-template.json scripts/my-system-config.json
# Edit paths and patterns for your system
dream --health-check -ConfigFile "scripts/my-system-config.json"
```

## 📁 Configuration Structure

### Required Files
- **Configuration file** (`scripts/cognitive-config.json`): Defines paths, patterns, and system identity
- **Memory files**: Your cognitive architecture's memory stores
- **Report directory**: Where dream state reports are saved

### Configuration Schema
```json
{
  "architecture_name": "Your System Name",
  "version": "1.0.0",
  "global_memory_files": ["path/to/main-config.md"],
  "core_memory_files": ["path/to/core-instructions.md"],
  "procedural_path": "memory/procedural/*.instructions.md",
  "episodic_path": "memory/episodic/*.prompt.md",
  "archive_path": "archive/*.md",
  "domain_knowledge_path": "knowledge/*.md",
  "report_path": "archive",
  "synapse_patterns": [
    "\\\\[.*\\\\.md\\\\].*\\\\(.*\\\\).*-.*\\\".*\\\"",
    "\\\\[.*\\\\.md\\\\].*\\\\("
  ],
  "debug_patterns": ["*critical*", "*core*"]
}
```

## 🔧 Core Commands

### Health & Diagnostics
```powershell
dream --health-check           # Quick network connectivity assessment
dream --status                # Detailed system status
dream --full-scan             # Comprehensive architecture analysis
```

### Maintenance Operations
```powershell
dream --neural-maintenance     # Complete neural network maintenance
dream --synaptic-repair       # Optimize synaptic connections
dream --prune-orphans         # Detect and analyze orphaned files
dream --network-optimization  # Network topology optimization
```

### Advanced Protocols
```powershell
dream --lucid-dream           # AI-enhanced optimization analysis
dream --emergency-repair      # Multi-stage repair sequence
```

### Options
```powershell
-ReportOnly                   # Generate reports without making changes
-DetailedOutput              # Show detailed processing information
-ConfigFile "path"           # Use custom configuration file
```

## 🧬 Embedded Synapse Network Format

The system detects connections using these patterns:

### Standard Format
```markdown
[target-file.md] (strength, relationship-type, direction) - "activation-condition"
```

### Examples
```markdown
[azure-sql.md] (0.95, database-optimization, bidirectional) - "Database performance queries"
[business-requirements.md] (0.8, documentation, forward) - "BRD creation workflows"
```

### Alternative Patterns
```markdown
[file.md] (connection-info)
→ linked-file.md
[Reference](path/to/file.md)
```

## 📊 Network Health Metrics

### Connection Types
- **Strongly Connected**: Direct filename references in core memory files
- **Weakly Connected**: Partial name matches in memory files
- **Embedded Synapses**: Files with internal synapse notation
- **Orphaned**: No detectable connections to the network

### Health Scores
- **EXCELLENT**: No orphans, 200+ synaptic connections
- **GOOD**: ≤2 orphans, 150+ synaptic connections
- **FAIR**: ≤5 orphans, 100+ synaptic connections
- **NEEDS_ATTENTION**: >5 orphans or <100 connections

## 🔄 Automated Maintenance Activities

### Dream State Operations
- **Synaptic Connection Optimization**: Strengthen pathways between memory files
- **Memory Consolidation**: Enhance cross-domain knowledge transfer
- **Network Topology Enhancement**: Optimize connection patterns
- **Orphan Detection**: Identify disconnected memory components
- **Connection Strength Calibration**: Balance synapse weights

### Report Generation
All operations generate detailed reports in the configured report directory:
- **Dream State Reports**: Network connectivity analysis and system status (`dream-state-*.md`)
- **Maintenance Records**: Automated maintenance activity logs (`automated-maintenance-*.md`)
- **Synaptic Connection Metrics**: Network health and optimization data
- **Unified Archive Structure**: All reports stored in single archive location for consistency

### Archive Management
The system uses a unified archive structure:
- **Location**: Single `archive/` directory (configurable via `report_path`)
- **Report Types**: Dream state reports and maintenance records co-located
- **Lifecycle**: Archive files can be safely deleted as they are diagnostic snapshots
- **Retention**: Keep recent files for troubleshooting, older files can be removed without affecting cognitive architecture

## 🛠️ Customization for Your System

### 1. Directory Structure
Adapt the configuration paths to match your cognitive architecture:
```json
{
  "procedural_path": "your-path/instructions/*.md",
  "episodic_path": "your-path/workflows/*.md",
  "domain_knowledge_path": "your-path/knowledge/*.md"
}
```

### 2. Synapse Patterns
Define how your system represents connections:
```json
{
  "synapse_patterns": [
    "your-connection-pattern-regex",
    "alternative-pattern-regex"
  ]
}
```

### 3. Debug Patterns
Specify which files are critical for debugging:
```json
{
  "debug_patterns": ["*core*", "*critical*", "*primary*"]
}
```

### 4. Architecture Identity
Customize system identification:
```json
{
  "architecture_name": "Your Cognitive System",
  "version": "1.0.0",
  "architecture_specific": {
    "system_type": "Your specific AI type",
    "capabilities": ["list", "of", "capabilities"]
  }
}
```

## 📋 Integration Examples

### Basic Integration
```powershell
# Load the neural dream script
.\scripts\neural-dream.ps1

# Configure for your system
$config = "scripts/my-cognitive-config.json"

# Run maintenance
dream --neural-maintenance -ConfigFile $config
```

### Automated Monitoring
```powershell
# Health check script for CI/CD
$result = dream --health-check -ReportOnly -ConfigFile "scripts/production-config.json"
if ($result.OrphanCount -gt 0) {
    Write-Error "Cognitive architecture has orphaned files"
    exit 1
}
```

### Custom Workflow Integration
```powershell
# Integration with existing workflows
function Invoke-CognitiveMaintenanance {
    param([string]$Environment = "development")

    $configFile = "scripts/configs/$Environment-config.json"
    dream --neural-maintenance -ConfigFile $configFile

    # Process results...
}
```

## 🔍 Troubleshooting

### Common Issues

1. **No memory files found**
   - Check paths in configuration file
   - Verify directory structure exists
   - Ensure file permissions allow reading

2. **High orphan count**
   - Review synapse patterns in config
   - Check if memory files reference each other
   - Add missing references to core memory files

3. **Low synaptic connections**
   - Increase embedded synapse usage
   - Add more cross-references between files
   - Review connection strength calculations

### Debug Mode
Use debug patterns to trace specific file processing:
```json
{
  "debug_patterns": ["*your-critical-files*"]
}
```

## 🌟 Advanced Features

### Lucid Dream Protocol
AI-enhanced optimization that detects improvement opportunities and provides recommendations for cognitive architecture enhancement.

### Emergency Repair
Multi-stage repair sequence for critical network failures:
1. Full architecture scan
2. Synaptic repair
3. Network optimization
4. Validation check

### Custom Maintenance Activities
Extend the system by adding custom maintenance functions to the automated maintenance engine.

## 📝 License

This cognitive architecture maintenance system is designed to be generic and adaptable to various AI cognitive architectures. Modify and extend as needed for your specific implementation.

---

*Neural Dream State Automation - Enabling automated cognitive architecture maintenance for AI systems*
