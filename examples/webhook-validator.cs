// Webhook HMAC-SHA256 Signature Validation Example
// This demonstrates how to validate Qualtrics webhook signatures for security
// 
// NuGet Packages Required:
// - Microsoft.AspNetCore.Mvc (built-in with ASP.NET Core)
//
// Reference: DK-QUALTRICS-API-v1.0.0.md (lines ~1000-1200)

using System.Security.Cryptography;
using System.Text;
using Microsoft.AspNetCore.Mvc;

namespace DispositionDashboard.Examples;

/// <summary>
/// Validates Qualtrics webhook signatures using HMAC-SHA256
/// </summary>
public class WebhookValidator
{
    private readonly string _webhookSecret;

    public WebhookValidator(string webhookSecret)
    {
        _webhookSecret = webhookSecret ?? throw new ArgumentNullException(nameof(webhookSecret));
    }

    /// <summary>
    /// Validates the webhook signature from Qualtrics
    /// </summary>
    /// <param name="payload">Raw request body as string</param>
    /// <param name="signature">X-Qualtrics-Signature header value</param>
    /// <returns>True if signature is valid, false otherwise</returns>
    public bool ValidateSignature(string payload, string signature)
    {
        if (string.IsNullOrEmpty(payload) || string.IsNullOrEmpty(signature))
        {
            return false;
        }

        try
        {
            // Compute HMAC-SHA256 hash
            using var hmac = new HMACSHA256(Encoding.UTF8.GetBytes(_webhookSecret));
            var hash = hmac.ComputeHash(Encoding.UTF8.GetBytes(payload));
            var computedSignature = Convert.ToBase64String(hash);

            // Constant-time comparison to prevent timing attacks
            return CryptographicOperations.FixedTimeEquals(
                Encoding.UTF8.GetBytes(computedSignature),
                Encoding.UTF8.GetBytes(signature)
            );
        }
        catch (Exception ex)
        {
            // Log exception (omitted for brevity)
            Console.WriteLine($"Signature validation error: {ex.Message}");
            return false;
        }
    }
}

/// <summary>
/// Example webhook controller with signature validation
/// </summary>
[ApiController]
[Route("api/webhooks")]
public class QualtricsWebhookController : ControllerBase
{
    private readonly WebhookValidator _validator;
    private readonly ILogger<QualtricsWebhookController> _logger;

    public QualtricsWebhookController(
        WebhookValidator validator,
        ILogger<QualtricsWebhookController> logger)
    {
        _validator = validator;
        _logger = logger;
    }

    /// <summary>
    /// Receives webhook events from Qualtrics
    /// IMPORTANT: Qualtrics sends form-urlencoded data, NOT JSON!
    /// </summary>
    [HttpPost("qualtrics")]
    [Consumes("application/x-www-form-urlencoded")]
    public async Task<IActionResult> ReceiveWebhook()
    {
        try
        {
            // Read raw body for signature validation
            Request.EnableBuffering();
            using var reader = new StreamReader(Request.Body, leaveOpen: true);
            var rawBody = await reader.ReadToEndAsync();
            Request.Body.Position = 0; // Reset for model binding

            // Get signature from header
            var signature = Request.Headers["X-Qualtrics-Signature"].FirstOrDefault();
            
            if (string.IsNullOrEmpty(signature))
            {
                _logger.LogWarning("Webhook received without signature");
                return Unauthorized("Missing signature");
            }

            // Validate signature
            if (!_validator.ValidateSignature(rawBody, signature))
            {
                _logger.LogWarning("Webhook signature validation failed");
                return Unauthorized("Invalid signature");
            }

            // Parse form data
            var form = await Request.ReadFormAsync();
            var topic = form["Topic"].ToString();
            var brandId = form["BrandID"].ToString();
            var responseId = form["ResponseID"].ToString();
            var surveyId = form["SurveyID"].ToString();

            _logger.LogInformation(
                "Valid webhook received: Topic={Topic}, Survey={SurveyId}, Response={ResponseId}",
                topic, surveyId, responseId);

            // IMPORTANT: Return 200 within 5 seconds!
            // Queue actual processing to avoid timeout
            // Example: await _serviceBus.SendMessageAsync(new WebhookMessage { ... });

            return Ok(new { status = "received", responseId });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing webhook");
            return StatusCode(500, "Internal server error");
        }
    }
}

// Usage Example in Startup.cs or Program.cs:
//
// builder.Services.AddSingleton<WebhookValidator>(sp => 
//     new WebhookValidator(builder.Configuration["WEBHOOK_SECRET"]));
//
// Or from Azure Key Vault:
//
// var keyVaultUrl = $"https://{builder.Configuration["AZURE_KEY_VAULT_NAME"]}.vault.azure.net/";
// var secretClient = new SecretClient(new Uri(keyVaultUrl), new DefaultAzureCredential());
// var webhookSecret = await secretClient.GetSecretAsync("WebhookSecret");
// builder.Services.AddSingleton<WebhookValidator>(sp => 
//     new WebhookValidator(webhookSecret.Value.Value));

/* Testing with cURL:
   
   # Generate signature
   echo -n "Topic=surveyengine.completedResponse&ResponseID=R_123" | \
     openssl dgst -sha256 -hmac "your_secret" -binary | base64
   
   # Send test webhook
   curl -X POST https://localhost:5001/api/webhooks/qualtrics \
     -H "X-Qualtrics-Signature: generated_signature_here" \
     -H "Content-Type: application/x-www-form-urlencoded" \
     -d "Topic=surveyengine.completedResponse&ResponseID=R_123&SurveyID=SV_456&BrandID=brand123"
*/
