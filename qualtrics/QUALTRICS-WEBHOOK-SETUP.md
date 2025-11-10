# Qualtrics Webhook Configuration Guide

**For**: Qualtrics Administrator
**Purpose**: Configure real-time event notifications to Qualtrics Dashboard
**Time Required**: 10-15 minutes
**Status**: ✅ Webhook endpoint deployed and tested

**⚠️ Important Note**: Qualtrics webhook features and configuration options vary by subscription tier, license type, and account version. The steps in this guide represent common patterns but may differ in your Qualtrics environment. Consult your Qualtrics account manager or support if options described here are unavailable.

---## 📋 What You Need Before Starting

- [ ] **Qualtrics Administrator Access** (Brand Admin or License Admin role)
- [ ] **Permissions**: API/Developer access enabled on your account
- [ ] **License Type**: Enterprise or license with API features
- [ ] **Survey ID** (optional): `SV_aaS1Ww4SnZbFT3E` or your development survey

---

## 🎯 Configuration Overview

You will configure Qualtrics to send real-time events to our dashboard when:
- New survey responses are submitted
- Survey responses are updated
- Email distributions are created
- Distribution statuses change (sent, bounced, opened, etc.)

**What happens**: Qualtrics → Webhook → Dashboard (real-time updates)

---

## 📝 Webhook Details to Use

**Copy these values - you'll need them:**

```
Webhook URL:        https://app-qd-dev-api.azurewebsites.net/api/webhook
Method:             POST
Content Type:       application/json
Signature Method:   HMAC-SHA256
Signature Header:   X-Qualtrics-Signature
Secret Key:         t5c/lk/qEe3TGCK0O03Z+U4Tc7H9o17duN/WSx8Bshc=
```

**Event Types to Enable:**
- ✅ `surveyengine.completedResponse.{SurveyID}` (Response completed/created)
- ✅ `controlpanel.createdDistribution` (Distribution created)
- ✅ `controlpanel.deactivateMailing` (Distribution status/completion)

**Note**: Qualtrics event topic names may vary. Use the available topics in your Qualtrics subscription panel.

---

## 🚀 Step-by-Step Setup

### Step 1: Find the Webhook Configuration Page

**Try these locations in order:**

#### ✅ Option 1: Brand Admin (Most Common)
1. Log into Qualtrics
2. Click your **Brand ID** in the top-left corner (next to Qualtrics logo)
3. Select **"Admin"** from the dropdown
4. Look in left sidebar for:
   - **"Webhooks"** OR
   - **"API"** → **"Webhooks"** OR
   - **"Integrations"** → **"Webhooks"**

#### ✅ Option 2: Direct URL
Copy and paste this into your browser (replace `fra1` if your data center is different):
```
https://fra1.qualtrics.com/admin-settings/webhooks
```

#### ✅ Option 3: Search
Use the search bar (magnifying glass icon) at the top and search for **"webhook"**

#### ✅ Option 4: Account Settings
1. Click your profile icon (top-right)
2. Select **"Account Settings"**
3. Look for **"Integrations"** or **"API"** in left sidebar

---

### 🚨 Can't Find Webhooks? Read This

<details>
<summary><strong>Click here if you cannot locate the webhook configuration</strong></summary>

**Common Issues:**

1. **Missing Permissions**
   - You need **Brand Administrator** or **License Administrator** role
   - Contact your Qualtrics account owner to request elevated permissions
   - Required: "API Access" or "Developer Access" permission

2. **License Limitations**
   - Webhooks require Enterprise license or API add-on
   - Check: Account Settings → Billing → View Features
   - Contact Qualtrics support if unsure: support@qualtrics.com

3. **Use API Instead** (Advanced)
   - If you have an API token, you can create webhooks programmatically
   - See "Alternative: API Setup" section at bottom of this document
   - Requires: API Token from Account Settings → Qualtrics IDs

**Need Help?**
- Forward this document to your Qualtrics administrator
- Contact Qualtrics support with this message: "I need help enabling webhook subscriptions for event notifications"

</details>

---

### Step 2: Create New Webhook Subscription

1. Click **"Create Webhook"** or **"New Subscription"** button

2. **Fill in Basic Information:**
   - **Name**: `Qualtrics Dashboard - Development`
   - **Description**: `Real-time event notifications for distribution tracking`
   - **Status**: Set to **Active** (or enable after testing)

3. **Configure Endpoint:**
   - **URL**: `https://app-qd-dev-api.azurewebsites.net/api/webhook`
   - **Method**: `POST`
   - **Content Type**: `application/json`

4. **Configure Security (IMPORTANT):**
   - **Enable Signature Verification**: ✅ **YES** (check this box)
   - **Signature Algorithm**: Select **`HMAC-SHA256`**
   - **Signature Header Name**: Enter **`X-Qualtrics-Signature`**
   - **Secret Key**: Copy and paste:
     ```
     t5c/lk/qEe3TGCK0O03Z+U4Tc7H9o17duN/WSx8Bshc=
     ```
   - ⚠️ **Important**: Copy the secret exactly - no extra spaces!

---

### Step 3: Select Event Types

**Select the events your subscription supports:**

Common Qualtrics webhook topics include:
- ✅ **surveyengine.completedResponse.{SurveyID}** - Survey response completed
- ✅ **controlpanel.createdDistribution** - New distribution created
- ✅ **controlpanel.deactivateMailing** - Distribution deactivated/completed

**⚠️ Important**: Event topic names vary by Qualtrics subscription and version. Use the exact topic names shown in your Qualtrics webhook configuration panel. The topics above are examples - select all topics related to responses and distributions that appear in your subscription interface.

---

### Step 4: Set Survey Filter

**For Development/Testing - Choose Option B:**

- **Option A**: All Surveys
  - Select: "All surveys in this brand"
  - ⚠️ Will receive events for ALL surveys (can be noisy)

- **Option B**: Specific Survey (Recommended for testing)
  - Select: "Specific surveys"
  - Enter Survey ID: `SV_aaS1Ww4SnZbFT3E`
  - (Or use your development survey ID)

**For Production:**
- Use "All surveys" or select your production survey IDs

---

### Step 5: Test the Webhook

1. **Click "Test Webhook"** button (if available)
   - Qualtrics will send a test event to the endpoint
   - Expected result: ✅ Success message with HTTP 200 status

2. **If test succeeds**:
   - Click **"Save"** or **"Activate"** to enable the webhook
   - You should see webhook status change to **"Active"** (green)

3. **If test fails**:
   - Double-check the URL is exact: `https://app-qd-dev-api.azurewebsites.net/api/webhook`
   - Verify secret key has no extra spaces
   - See "Troubleshooting" section below

---

### Step 6: Verify It's Working

**Method 1: Check Qualtrics Dashboard**
- In webhook list, look for "Last Activity" timestamp
- Should update within minutes of survey activity

**Method 2: Submit a Test Response**
1. Open your survey in preview mode
2. Submit a test response
3. Check webhook "Last Activity" - should show recent timestamp

**Method 3: Contact DevOps (We'll Verify)**
- Send us the webhook ID or name you created
- We'll confirm events are arriving in our system

---

## ✅ You're Done!

**What's configured:**
- ✅ Webhook endpoint registered with Qualtrics
- ✅ Security configured (HMAC signature verification)
- ✅ Events enabled for responses and distributions
- ✅ Survey filter applied

**What happens now:**
- Qualtrics sends real-time events when survey activity occurs
- Dashboard receives and processes events
- Users see live updates without waiting for polling

---

## 🔧 Troubleshooting

### Test Webhook Fails

**Error: "Connection Timeout" or "Cannot Connect"**
- ✅ Check: Endpoint URL is exactly: `https://app-qd-dev-api.azurewebsites.net/api/webhook`
- ✅ Verify: No trailing slashes or extra characters
- ✅ Try: Test from browser or Postman to verify endpoint is accessible

**Error: "Unauthorized" or "401"**
- ✅ Verify: Secret key is exactly: `t5c/lk/qEe3TGCK0O03Z+U4Tc7H9o17duN/WSx8Bshc=`
- ✅ Check: Signature header is: `X-Qualtrics-Signature`
- ✅ Confirm: Signature method is: `HMAC-SHA256`

**Error: "Bad Request" or "400"**
- ✅ Verify: Content type is `application/json`
- ✅ Check: Method is `POST`
- Contact DevOps team for assistance

### Events Not Arriving

**Check 1: Webhook is Active**
- Status in Qualtrics shows "Active" or "Enabled"
- Toggle off and back on if needed

**Check 2: Survey Filter is Correct**
- If using specific surveys, verify survey ID is correct
- Temporarily try "All surveys" to test

**Check 3: Event Types Selected**
- Verify checkboxes are checked for desired events
- Try with just response completion events first
- Event topic names must match exactly what Qualtrics provides

**Check 4: Contact DevOps**
- We can verify if endpoint is receiving requests
- We'll check logs and confirm webhook is configured correctly

---

## 📞 Support

**If you need help:**

1. **DevOps Team**: [Your contact info here]
   - Can verify endpoint is working
   - Can check if events are being received
   - Can troubleshoot signature validation

2. **Qualtrics Support**: support@qualtrics.com
   - For webhook configuration issues
   - For permission/license questions
   - For API token generation

3. **Send This Info When Requesting Help:**
   - Webhook name you created
   - Error messages (if any)
   - Screenshot of webhook configuration page
   - Survey ID you're testing with

---

## 📚 Reference Information

### What is HMAC Signature Verification?

**In simple terms**: It's a security mechanism to verify webhooks come from Qualtrics (not an attacker)

**How it works**:
1. Qualtrics creates a signature using the secret key and webhook payload
2. Signature is sent in header: `X-Qualtrics-Signature`
3. Dashboard verifies signature matches expected value
4. If match = legitimate webhook (processed), if not = rejected (401 Unauthorized)

**Technical Details**:
- Algorithm: HMAC-SHA256
- Input: Raw JSON payload body (exactly as sent)
- Output: Base64-encoded signature
- Comparison: Constant-time to prevent timing attacks

### Event Payload Examples

**What data gets sent:**

**Response Created Event:**
```json
{
  "Topic": "surveyengine.completedResponse.SV_aaS1Ww4SnZbFT3E",
  "Status": "Complete",
  "BrandID": "aloha",
  "ResponseID": "R_3MHSample123456",
  "SurveyID": "SV_aaS1Ww4SnZbFT3E",
  "CompletedDate": "2025-11-06T15:35:00Z"
}
```

**Distribution Event:**
```json
{
  "Topic": "controlpanel.createdDistribution",
  "DistributionID": "EMD_Sample12345678",
  "SurveyID": "SV_aaS1Ww4SnZbFT3E",
  "BrandID": "aloha",
  "OrganizationID": "org_id"
}
```

**Note**: Actual payload structure depends on Qualtrics subscription version. Consult [Qualtrics API documentation](https://api.qualtrics.com/) for your specific payload format.

---

## 🔐 Security Notes

**Keep Secret Key Secure:**
- ⚠️ Don't share the secret key publicly
- ⚠️ Don't email unencrypted
- ✅ Only enter in Qualtrics webhook configuration
- ✅ Store securely if you need to save it

**Production Deployment:**
- Secret will be rotated and stored in Azure Key Vault
- You'll receive new secret before production deployment
- Follow this same process with updated secret

---

## 🎓 Additional Resources

**Qualtrics Documentation:**
- [Qualtrics API Documentation](https://api.qualtrics.com/) - Official API reference
- [Qualtrics Support Center](https://www.qualtrics.com/support/) - General support documentation
- **Note**: Specific webhook/event subscription documentation requires Qualtrics account login

**Azure Documentation:**
- [Azure App Service Overview](https://learn.microsoft.com/en-us/azure/app-service/overview)
- [Service Bus Queues, Topics, and Subscriptions](https://learn.microsoft.com/en-us/azure/service-bus-messaging/service-bus-queues-topics-subscriptions)
- [Use Key Vault References for App Service](https://learn.microsoft.com/en-us/azure/app-service/app-service-key-vault-references)

**Questions About This Dashboard:**
- [Project Documentation](docs/INDEX.md)
- [Architecture Overview](architecture/EXECUTIVE-ARCHITECTURE-OVERVIEW.md)
- [Configuration Guide](docs/CONFIG-SYSTEM-GUIDE.md)

---

## 🔄 Alternative: API-Based Setup

<details>
<summary><strong>Advanced: Create webhook using Qualtrics API (if UI access not available)</strong></summary>

**Prerequisites:**
- Qualtrics API Token (from Account Settings → Qualtrics IDs)
- PowerShell or API client

**PowerShell Script:**
```powershell
# Configuration
$dataCenter = "fra1"  # Change to your data center
$apiToken = "YOUR_API_TOKEN_HERE"  # Get from Qualtrics

$headers = @{
    "X-API-TOKEN" = $apiToken
    "Content-Type" = "application/json"
}

$body = @{
    url = "https://app-qd-dev-api.azurewebsites.net/api/webhook"
    publicationUrl = "https://app-qd-dev-api.azurewebsites.net/api/webhook"
    topics = "surveyengine.completedResponse.$SurveyID,controlpanel.createdDistribution,controlpanel.deactivateMailing"
    encrypt = $true
    sharedKey = "t5c/lk/qEe3TGCK0O03Z+U4Tc7H9o17duN/WSx8Bshc="
} | ConvertTo-Json

$url = "https://$dataCenter.qualtrics.com/API/v3/eventsubscriptions"

try {
    $response = Invoke-RestMethod -Uri $url -Method POST -Headers $headers -Body $body
    Write-Host "✅ Webhook created successfully!" -ForegroundColor Green
    Write-Host "Subscription ID: $($response.result.id)" -ForegroundColor Cyan
} catch {
    Write-Host "❌ Error:" -ForegroundColor Red
    Write-Host $_.Exception.Message
}
```

**To Get Your API Token:**
1. Account Settings → Qualtrics IDs
2. Generate Token → Copy token
3. Paste into script above

**To Run:**
```powershell
# Save script as create-webhook.ps1
# Run in PowerShell
.\create-webhook.ps1
```

</details>

---

**Document Status**: ✅ Ready for Qualtrics Administrator
**Last Updated**: November 6, 2025
**Webhook Endpoint**: ✅ Deployed and tested
**Next Action**: Follow steps above to configure webhook in Qualtrics
