// Survey Export Processing with Exponential Backoff Example
// This demonstrates the recommended pattern for exporting survey responses
//
// NuGet Packages Required:
// - Polly (for retry policies)
// - System.Text.Json (for JSON parsing)
//
// Reference: DK-QUALTRICS-API-v1.0.0.md (Export endpoints section)

using System.Net.Http.Headers;
using System.Text.Json;
using Polly;
using Polly.Retry;

namespace DispositionDashboard.Examples;

/// <summary>
/// Handles survey response exports with polling and exponential backoff
/// </summary>
public class SurveyExportProcessor
{
    private readonly HttpClient _httpClient;
    private readonly string _apiToken;
    private readonly string _dataCenter;
    private readonly AsyncRetryPolicy<HttpResponseMessage> _retryPolicy;

    public SurveyExportProcessor(string apiToken, string dataCenter)
    {
        _apiToken = apiToken ?? throw new ArgumentNullException(nameof(apiToken));
        _dataCenter = dataCenter ?? throw new ArgumentNullException(nameof(dataCenter));
        
        _httpClient = new HttpClient
        {
            BaseAddress = new Uri($"https://{_dataCenter}.qualtrics.com/API/v3/"),
            Timeout = TimeSpan.FromMinutes(5)
        };
        _httpClient.DefaultRequestHeaders.Add("X-API-TOKEN", _apiToken);

        // Exponential backoff retry policy
        _retryPolicy = Policy
            .HandleResult<HttpResponseMessage>(r => (int)r.StatusCode == 429) // Rate limited
            .Or<HttpRequestException>()
            .WaitAndRetryAsync(
                retryCount: 5,
                sleepDurationProvider: attempt => TimeSpan.FromSeconds(Math.Pow(2, attempt)),
                onRetry: (outcome, timespan, retryCount, context) =>
                {
                    Console.WriteLine($"Retry {retryCount} after {timespan.TotalSeconds}s delay");
                });
    }

    /// <summary>
    /// Exports survey responses with automatic polling until complete
    /// </summary>
    public async Task<Stream> ExportSurveyResponsesAsync(
        string surveyId,
        DateTime? startDate = null,
        DateTime? endDate = null,
        CancellationToken cancellationToken = default)
    {
        // Step 1: Start the export
        var exportId = await StartExportAsync(surveyId, startDate, endDate, cancellationToken);
        Console.WriteLine($"Export started: {exportId}");

        // Step 2: Poll for completion
        var downloadUrl = await PollExportProgressAsync(surveyId, exportId, cancellationToken);
        Console.WriteLine($"Export complete. Downloading from: {downloadUrl}");

        // Step 3: Download the file
        var fileStream = await DownloadExportFileAsync(surveyId, exportId, cancellationToken);
        Console.WriteLine($"Downloaded {fileStream.Length} bytes");

        return fileStream;
    }

    private async Task<string> StartExportAsync(
        string surveyId,
        DateTime? startDate,
        DateTime? endDate,
        CancellationToken cancellationToken)
    {
        var requestBody = new
        {
            format = "json",
            useLabels = true,
            compress = false,
            startDate = startDate?.ToString("yyyy-MM-ddTHH:mm:ssZ"),
            endDate = endDate?.ToString("yyyy-MM-ddTHH:mm:ssZ")
        };

        var response = await _retryPolicy.ExecuteAsync(async () =>
        {
            var request = new HttpRequestMessage(HttpMethod.Post, 
                $"surveys/{surveyId}/export-responses")
            {
                Content = new StringContent(
                    JsonSerializer.Serialize(requestBody),
                    new MediaTypeHeaderValue("application/json"))
            };

            return await _httpClient.SendAsync(request, cancellationToken);
        });

        response.EnsureSuccessStatusCode();
        
        var responseBody = await response.Content.ReadAsStringAsync(cancellationToken);
        using var doc = JsonDocument.Parse(responseBody);
        
        return doc.RootElement
            .GetProperty("result")
            .GetProperty("progressId")
            .GetString()!;
    }

    private async Task<string> PollExportProgressAsync(
        string surveyId,
        string exportId,
        CancellationToken cancellationToken)
    {
        var maxAttempts = 60; // 5 minutes with 5-second intervals
        var pollInterval = TimeSpan.FromSeconds(5);

        for (int attempt = 0; attempt < maxAttempts; attempt++)
        {
            var response = await _retryPolicy.ExecuteAsync(async () =>
                await _httpClient.GetAsync(
                    $"surveys/{surveyId}/export-responses/{exportId}",
                    cancellationToken));

            response.EnsureSuccessStatusCode();

            var responseBody = await response.Content.ReadAsStringAsync(cancellationToken);
            using var doc = JsonDocument.Parse(responseBody);
            
            var result = doc.RootElement.GetProperty("result");
            var status = result.GetProperty("status").GetString();
            var percentComplete = result.GetProperty("percentComplete").GetDouble();

            Console.WriteLine($"Export progress: {percentComplete}% ({status})");

            if (status == "complete")
            {
                return result.GetProperty("fileId").GetString()!;
            }

            if (status == "failed")
            {
                throw new InvalidOperationException("Export failed");
            }

            // Exponential backoff for polling
            await Task.Delay(pollInterval * (attempt + 1), cancellationToken);
        }

        throw new TimeoutException("Export did not complete within timeout period");
    }

    private async Task<Stream> DownloadExportFileAsync(
        string surveyId,
        string fileId,
        CancellationToken cancellationToken)
    {
        var response = await _retryPolicy.ExecuteAsync(async () =>
            await _httpClient.GetAsync(
                $"surveys/{surveyId}/export-responses/{fileId}/file",
                HttpCompletionOption.ResponseHeadersRead,
                cancellationToken));

        response.EnsureSuccessStatusCode();

        // Return stream directly to avoid loading entire file in memory
        return await response.Content.ReadAsStreamAsync(cancellationToken);
    }

    public void Dispose()
    {
        _httpClient?.Dispose();
    }
}

// Usage Example:
//
// var processor = new SurveyExportProcessor(
//     apiToken: Environment.GetEnvironmentVariable("QUALTRICS_API_TOKEN"),
//     dataCenter: "iad1");
//
// try
// {
//     var exportStream = await processor.ExportSurveyResponsesAsync(
//         surveyId: "SV_abc123",
//         startDate: DateTime.UtcNow.AddDays(-7),
//         endDate: DateTime.UtcNow);
//
//     // Process the stream (parse JSON, save to file, etc.)
//     using var fileStream = File.Create("survey-responses.json");
//     await exportStream.CopyToAsync(fileStream);
//     
//     Console.WriteLine("Export saved successfully");
// }
// finally
// {
//     processor.Dispose();
// }

/* Rate Limiting Notes:
   
   - Export endpoints: 300 requests/minute
   - Use exponential backoff when polling (don't hammer the API)
   - Start with 5s intervals, increase for longer exports
   - Monitor 429 responses and respect Retry-After header
   - Consider caching export results to avoid repeated exports
*/
