// Rate Limiting and Throttling Example
// This demonstrates how to stay within Qualtrics API rate limits
//
// NuGet Packages Required:
// - System.Threading.RateLimiting (built-in .NET 7+)
// - Polly (for retry policies)
//
// Reference: DK-QUALTRICS-API-v1.0.0.md (Rate limits section)

using System.Threading.RateLimiting;
using Polly;
using Polly.RateLimit;

namespace DispositionDashboard.Examples;

/// <summary>
/// Manages rate limiting for Qualtrics API calls
/// Brand-level: 3000 requests/minute
/// Per-endpoint limits vary (see DK-QUALTRICS-API-v1.0.0.md)
/// </summary>
public class QualtricsRateLimiter
{
    private readonly RateLimiter _brandLevelLimiter;
    private readonly Dictionary<string, RateLimiter> _endpointLimiters;
    private readonly SemaphoreSlim _semaphore;

    public QualtricsRateLimiter(int maxConcurrentRequests = 10)
    {
        // Brand-level rate limiter: 3000 requests per minute
        _brandLevelLimiter = new SlidingWindowRateLimiter(new SlidingWindowRateLimiterOptions
        {
            PermitLimit = 3000,
            Window = TimeSpan.FromMinutes(1),
            SegmentsPerWindow = 6, // 10-second segments
            QueueProcessingOrder = QueueProcessingOrder.OldestFirst,
            QueueLimit = 100
        });

        // Endpoint-specific rate limiters
        _endpointLimiters = new Dictionary<string, RateLimiter>
        {
            // Distribution stats: 3000 RPM (same as brand level)
            ["distributions"] = new SlidingWindowRateLimiter(new SlidingWindowRateLimiterOptions
            {
                PermitLimit = 3000,
                Window = TimeSpan.FromMinutes(1),
                SegmentsPerWindow = 6,
                QueueProcessingOrder = QueueProcessingOrder.OldestFirst,
                QueueLimit = 50
            }),

            // Survey responses export: 300 RPM
            ["export-responses"] = new SlidingWindowRateLimiter(new SlidingWindowRateLimiterOptions
            {
                PermitLimit = 300,
                Window = TimeSpan.FromMinutes(1),
                SegmentsPerWindow = 6,
                QueueProcessingOrder = QueueProcessingOrder.OldestFirst,
                QueueLimit = 20
            }),

            // Individual response retrieval: 300 RPM
            ["responses"] = new SlidingWindowRateLimiter(new SlidingWindowRateLimiterOptions
            {
                PermitLimit = 300,
                Window = TimeSpan.FromMinutes(1),
                SegmentsPerWindow = 6,
                QueueProcessingOrder = QueueProcessingOrder.OldestFirst,
                QueueLimit = 20
            })
        };

        _semaphore = new SemaphoreSlim(maxConcurrentRequests);
    }

    /// <summary>
    /// Executes an API call with rate limiting and retry logic
    /// </summary>
    public async Task<T> ExecuteAsync<T>(
        string endpointCategory,
        Func<Task<T>> apiCall,
        CancellationToken cancellationToken = default)
    {
        // Acquire semaphore for concurrency control
        await _semaphore.WaitAsync(cancellationToken);

        try
        {
            // Check brand-level rate limit
            using var brandLease = await _brandLevelLimiter.AcquireAsync(1, cancellationToken);
            if (!brandLease.IsAcquired)
            {
                var retryAfterBrand = brandLease.TryGetMetadata(MetadataName.RetryAfter, out var brandRetry) ? brandRetry.ToString() : "unknown";
                throw new RateLimitRejectedException($"Brand-level rate limit exceeded. Retry after: {retryAfterBrand}");
            }

            // Check endpoint-specific rate limit
            if (_endpointLimiters.TryGetValue(endpointCategory, out var endpointLimiter))
            {
                using var endpointLease = await endpointLimiter.AcquireAsync(1, cancellationToken);
                if (!endpointLease.IsAcquired)
                {
                    var retryAfterEndpoint = endpointLease.TryGetMetadata(MetadataName.RetryAfter, out var endpointRetry) ? endpointRetry.ToString() : "unknown";
                    throw new RateLimitRejectedException($"Endpoint '{endpointCategory}' rate limit exceeded. Retry after: {retryAfterEndpoint}");
                }
            }

            // Execute the API call with Polly retry policy
            var retryPolicy = Policy
                .Handle<HttpRequestException>()
                .Or<RateLimitRejectedException>()
                .WaitAndRetryAsync(
                    retryCount: 3,
                    sleepDurationProvider: attempt => TimeSpan.FromSeconds(Math.Pow(2, attempt)),
                    onRetry: (exception, timeSpan, retryCount, context) =>
                    {
                        Console.WriteLine($"Rate limit retry {retryCount} after {timeSpan.TotalSeconds}s: {exception.Message}");
                    });

            return await retryPolicy.ExecuteAsync(apiCall);
        }
        finally
        {
            _semaphore.Release();
        }
    }

    /// <summary>
    /// Gets current rate limit statistics
    /// </summary>
    public RateLimitStats GetStats()
    {
        var stats = new RateLimitStats
        {
            BrandLevelRemaining = _brandLevelLimiter.GetStatistics()?.CurrentAvailablePermits ?? 0,
            EndpointStats = new Dictionary<string, int>()
        };

        foreach (var (endpoint, limiter) in _endpointLimiters)
        {
            stats.EndpointStats[endpoint] = limiter.GetStatistics()?.CurrentAvailablePermits ?? 0;
        }

        return stats;
    }

    public void Dispose()
    {
        _brandLevelLimiter?.Dispose();
        foreach (var limiter in _endpointLimiters.Values)
        {
            limiter?.Dispose();
        }
        _semaphore?.Dispose();
    }
}

public class RateLimitStats
{
    public int BrandLevelRemaining { get; set; }
    public Dictionary<string, int> EndpointStats { get; set; } = new();
}

// Usage Example:
//
// var rateLimiter = new QualtricsRateLimiter(maxConcurrentRequests: 10);
//
// try
// {
//     // Execute rate-limited API call
//     var result = await rateLimiter.ExecuteAsync(
//         endpointCategory: "distributions",
//         apiCall: async () =>
//         {
//             var response = await httpClient.GetAsync($"surveys/{surveyId}/distributions");
//             response.EnsureSuccessStatusCode();
//             return await response.Content.ReadAsStringAsync();
//         });
//
//     // Check rate limit status
//     var stats = rateLimiter.GetStats();
//     Console.WriteLine($"Brand-level remaining: {stats.BrandLevelRemaining}/3000");
//     Console.WriteLine($"Distribution endpoint remaining: {stats.EndpointStats["distributions"]}/3000");
// }
// finally
// {
//     rateLimiter.Dispose();
// }

/* Best Practices:
   
   1. Use the most efficient endpoint for your use case
      - Distribution stats (3000 RPM) vs Response export (300 RPM)
      - 10x difference in rate limits!
   
   2. Implement exponential backoff for retries
      - Don't hammer the API after hitting rate limit
      - Respect Retry-After header in 429 responses
   
   3. Monitor rate limit usage
      - Track requests per endpoint
      - Set alerts at 80% utilization
      - Adjust polling intervals dynamically
   
   4. Batch operations when possible
      - Fetch multiple distributions in single call
      - Use aggregate endpoints over individual lookups
   
   5. Cache aggressively
      - Survey metadata rarely changes
      - Distribution stats can tolerate 30-60s staleness
      - Implement conditional requests (ETags)
*/
