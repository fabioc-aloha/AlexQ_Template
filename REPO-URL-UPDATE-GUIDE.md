# Repository URL Update Guide

**Status**: ✅ **TEMPLATE REPOSITORY CONFIGURED**
**Repository**: `https://github.com/fabioc-aloha/AlexQ_Template.git`

---

## 🎯 Template Usage

This template is now published at: **https://github.com/fabioc-aloha/AlexQ_Template**

### Placeholder Patterns for Customization

When you clone this template for your project, replace these placeholders:
- `[your-admin-group]` - Your Azure AD RBAC group name
- `[Your Organization Name]` - For license copyright
- `[your-security-email@example.com]` - Your security contact email

**Template Repository URLs are already configured and do NOT need changes.**---

## 📝 Files Requiring Updates

### 1. TEMPLATE-QUALTRICS-AZURE-PROJECT.md

**Line 449**:
```markdown
# Current:
git clone https://github.com/fabioc-aloha/AlexQ_Template.git MyNewQualtricsProject

# Update to:
git clone https://github.com/fabioc-aloha/AlexQ_Template.git MyNewQualtricsProject
```

---

### 2. TEMPLATE-README.md

**Line 28**:
```markdown
# Current:
git clone https://github.com/fabioc-aloha/AlexQ_Template.git YourProjectName

# Update to:
git clone https://github.com/fabioc-aloha/AlexQ_Template.git YourProjectName
```

---

### 3. .github/TEMPLATE-USAGE.md

**Line 15**:
```markdown
# Current:
   - **Owner**: Your organization (e.g., `[your-org-name]`)

# Update to:
   - **Owner**: Your organization (e.g., `your-org-name`)
```

**Line 31**:
```markdown
# Current:
git clone https://github.com/fabioc-aloha/AlexQ_Template.git YourProjectName

# Update to:
git clone https://github.com/fabioc-aloha/AlexQ_Template.git YourProjectName
```

**Line 319**:
```markdown
# Current:
git remote add template https://github.com/fabioc-aloha/AlexQ_Template.git

# Update to:
git remote add template https://github.com/fabioc-aloha/AlexQ_Template.git
```

---

### 4. SECURITY.md

**Multiple locations** - Update all instances of:
```markdown
# Current:
https://github.com/fabioc-aloha/AlexQ_Template/security/advisories/new
https://github.com/fabioc-aloha/AlexQ_Template/discussions
https://github.com/fabioc-aloha/AlexQ_Template/issues

# Update to:
https://github.com/your-actual-org/your-actual-repo/security/advisories/new
https://github.com/your-actual-org/your-actual-repo/discussions
https://github.com/your-actual-org/your-actual-repo/issues
```

**Email placeholder**:
```markdown
# Current:
Email security concerns to `[your-security-email@example.com]`

# Update to:
Email security concerns to `security@your-domain.com`
```

---

### 5. LICENSE.md

**Line 3**:
```markdown
# Current:
Copyright (c) 2025 [Your Organization Name]

# Update to:
Copyright (c) 2025 Your Actual Organization Name
```

---

### 6. PUBLIC-RELEASE-CHECKLIST.md

**Final Sign-Off section**:
```markdown
# Current:
**Public Repository URL**: _____________________

# Update to:
**Public Repository URL**: https://github.com/your-org/your-repo
```

---

## 🔍 How to Find All Instances

Use PowerShell to find all references:

```powershell
# Find [your-org-name] references
Get-ChildItem -Recurse -File -Include "*.md" | Select-String "[your-org-name]" | Select-Object Path, LineNumber, Line

# Find [YOUR-ORG] placeholders
Get-ChildItem -Recurse -File -Include "*.md" | Select-String "\[YOUR-ORG\]" | Select-Object Path, LineNumber, Line

# Find [Your Organization Name] placeholders
Get-ChildItem -Recurse -File -Include "*.md" | Select-String "\[Your Organization Name\]" | Select-Object Path, LineNumber, Line

# Find email placeholders
Get-ChildItem -Recurse -File -Include "*.md" | Select-String "\[your-security-email" | Select-Object Path, LineNumber, Line
```

---

## 🔄 Automated Update Script

Create a PowerShell script to update all URLs at once:

```powershell
# update-repo-urls.ps1
param(
    [Parameter(Mandatory=$true)]
    [string]$OrgName,

    [Parameter(Mandatory=$true)]
    [string]$RepoName,

    [Parameter(Mandatory=$false)]
    [string]$SecurityEmail = "security@example.com",

    [Parameter(Mandatory=$false)]
    [string]$OrgFullName = "Your Organization"
)

$files = @(
    "TEMPLATE-QUALTRICS-AZURE-PROJECT.md",
    "TEMPLATE-README.md",
    ".github/TEMPLATE-USAGE.md",
    "SECURITY.md",
    "LICENSE.md",
    "PUBLIC-RELEASE-CHECKLIST.md"
)

foreach ($file in $files) {
    if (Test-Path $file) {
        $content = Get-Content $file -Raw

        # Replace repository URLs
        $content = $content -replace "fabioc-aloha/AlexQ_Template", "$OrgName/$RepoName"
        $content = $content -replace "\[YOUR-ORG\]/\[YOUR-REPO\]", "$OrgName/$RepoName"

        # Replace organization name
        $content = $content -replace "\[Your Organization Name\]", $OrgFullName

        # Replace security email
        $content = $content -replace "\[your-security-email@example\.com\]", $SecurityEmail

        Set-Content $file -Value $content -NoNewline
        Write-Host "✅ Updated: $file" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Not found: $file" -ForegroundColor Yellow
    }
}

Write-Host "`n✅ All repository URLs updated!" -ForegroundColor Green
Write-Host "📋 Review changes before committing:" -ForegroundColor Cyan
Write-Host "   git diff" -ForegroundColor Gray
```

### Usage Example:
```powershell
.\update-repo-urls.ps1 `
    -OrgName "mycompany" `
    -RepoName "qualtrics-azure-template" `
    -SecurityEmail "security@mycompany.com" `
    -OrgFullName "My Company Inc."
```

---

## ✅ Verification Checklist

After updating URLs, verify:

- [ ] All git clone commands point to correct repository
- [ ] All GitHub links are correct
- [ ] Security email is your actual contact
- [ ] Organization name in LICENSE is correct
- [ ] No `[placeholder]` patterns remain in these files
- [ ] Run `git diff` to review all changes
- [ ] Test one git clone command to ensure URL is valid

---

## 🚨 Important Notes

1. **Update URLs BEFORE making repository public**
   - Users will copy these URLs immediately
   - Incorrect URLs lead to confusion

2. **Test after updating**
   - Clone repository using new URL
   - Verify all links work
   - Check markdown rendering on GitHub

3. **Keep consistent**
   - Use same URL format everywhere
   - Don't mix HTTP/HTTPS
   - Include `.git` extension or omit consistently

4. **Security email**
   - Use dedicated security email if possible
   - Or use GitHub Security Advisories exclusively
   - Don't use personal email addresses

---

## 📊 Impact Summary

**Files to Update**: 6
**References to Replace**: ~10-15
**Time Estimate**: 10-15 minutes (manual) or 2 minutes (automated script)
**Priority**: 🔴 **CRITICAL** - Must complete before public release

---

*Use the automated script above to update all URLs consistently in one operation.*
