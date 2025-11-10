# Real-Time Disposition Reporting Dashboard Plan

**Plan Name**: Real-Time Survey Fielding Disposition Dashboard
**Date**: 2025-11-10
**Type**: Feature | Architecture
**Priority**: P0 (Critical - Core Product Feature)
**Status**: In Progress
**Owner**: Alex Q (Qualtrics Specialist)

---

## 🎯 Objective

Build a **real-time disposition reporting dashboard** that monitors Qualtrics survey fielding with live updates on email distribution performance, enabling campaign managers to track engagement metrics (sent, bounced, opened, clicked, completed) as they happen.

**Key Value**: Transform static distribution reports into live, actionable insights with sub-minute latency.

---

## 📋 Background

### Context
Survey campaign managers need real-time visibility into distribution performance to:
- Detect delivery issues immediately (high bounce rates)
- Monitor engagement patterns (open/click rates)
- Track response velocity (responses per hour)
- Make timely adjustments to improve campaign outcomes

**Current Pain Points**:
- Manual Qualtrics dashboard checking (time-consuming)
- Delayed visibility into distribution problems
- No consolidated multi-survey view
- Lack of historical trend comparison

### Current State
- ✅ Qualtrics API integration (`QualtricsService`) operational
- ✅ Configuration management with `qualtrics-config.json`
- ✅ Rate limiting optimization (3000 RPM on distribution endpoint)
- ✅ Azure infrastructure (Cosmos DB, SignalR Service, Key Vault)
- ✅ Domain knowledge established (6,000+ lines documentation)

### Desired State
- 🎯 Live dashboard with auto-refresh (30-60 second updates)
- 🎯 Real-time disposition metrics for active distributions
- 🎯 Historical trend visualization (7/30/90 day views)
- 🎯 Multi-survey monitoring on single screen
- 🎯 Anomaly detection and alerts (bounce spikes, low engagement)

---

## 🔍 Requirements

### Functional Requirements

#### Real-Time Monitoring
- [ ] **Live Disposition Updates**: Display sent/bounced/opened/clicked/completed counts with auto-refresh
- [ ] **Response Velocity**: Show responses per hour/day with trend indicators
- [ ] **Active Session Tracking**: Count of respondents currently taking survey
- [ ] **Distribution Status**: Active/completed/paused status with timestamps

#### Disposition Metrics
- [ ] **Email Sent Count**: Total emails sent in distribution
- [ ] **Bounce Rate**: `(bounced / sent) × 100%` with color coding (< 5% green, 5-10% yellow, > 10% red)
- [ ] **Open Rate**: `(opened / (sent - bounced)) × 100%`
- [ ] **Click Rate**: `(clicked / opened) × 100%`
- [ ] **Response Rate**: `(finished / sent) × 100%`
- [ ] **Completion Rate**: `(finished / opened) × 100%`

#### Historical Analysis
- [ ] **Time-Series Charts**: 7/30/90 day trend lines for all metrics
- [ ] **Comparative Views**: Current vs previous distribution performance
- [ ] **Peak Activity Times**: Heatmap of response timing patterns

#### Multi-Survey Support
- [ ] **Survey Selector**: Dropdown to switch between active surveys
- [ ] **Multi-Survey Grid**: Side-by-side comparison of 2-4 surveys
- [ ] **Aggregate View**: Combined metrics across all surveys

### Non-Functional Requirements

#### Performance
- [ ] **Dashboard Load Time**: < 3 seconds initial load
- [ ] **Update Latency**: < 60 seconds from API poll to UI update
- [ ] **API Response Time**: < 500ms for aggregate queries
- [ ] **Concurrent Users**: Support 50+ simultaneous dashboard users

#### Reliability
- [ ] **Uptime**: 99.9% availability (Azure SLA)
- [ ] **Polling Reliability**: 99.5% successful poll rate
- [ ] **Error Recovery**: Auto-retry with exponential backoff
- [ ] **Graceful Degradation**: Show last known data if API unavailable

#### Scalability
- [ ] **Survey Count**: Support 100+ surveys per brand
- [ ] **Data Retention**: 365 days time-series history
- [ ] **Polling Efficiency**: < 50% of Qualtrics rate limits
- [ ] **Cost Optimization**: < $0.10 per survey per month (Cosmos DB + compute)

#### Security & Privacy
- [ ] **Aggregate-Only Data**: Zero PII storage (counts and rates only)
- [ ] **Secure API Tokens**: Azure Key Vault storage
- [ ] **HTTPS Only**: All communication encrypted
- [ ] **Authentication**: Azure AD integration (future)

---

## 🏗️ Architecture

### High-Level Design

```
┌─────────────────────────────────────────────────────────────────┐
│                     React Dashboard (Frontend)                   │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────────┐   │
│  │ Live Metrics │  │ Trend Charts │  │ Survey Comparison  │   │
│  │ Panel        │  │ (7/30/90d)   │  │ Grid               │   │
│  └──────────────┘  └──────────────┘  └────────────────────┘   │
│           ▲ SignalR WebSocket (Real-time updates)              │
└───────────┼────────────────────────────────────────────────────┘
            │
┌───────────▼────────────────────────────────────────────────────┐
│              Azure SignalR Service (Hub)                        │
│         (Broadcasts updates to all connected clients)           │
└───────────▲────────────────────────────────────────────────────┘
            │
┌───────────┼────────────────────────────────────────────────────┐
│           │      ASP.NET Core Backend API                       │
│  ┌────────┴──────────┐         ┌────────────────────────┐     │
│  │ SignalR Hub        │         │ Disposition API        │     │
│  │ (Broadcast)        │         │ Controllers            │     │
│  └────────▲──────────┘         └────────┬───────────────┘     │
│           │                              │                      │
│  ┌────────┴──────────────────────────────▼───────────────┐    │
│  │     DistributionPollingService (Background)            │    │
│  │  - Polls Qualtrics API every 30-60 seconds             │    │
│  │  - Fetches distribution stats (3000 RPM limit)         │    │
│  │  - Calculates disposition metrics                      │    │
│  │  - Writes to Cosmos DB                                 │    │
│  │  - Triggers SignalR broadcast                          │    │
│  └────────┬──────────────────────────────▲───────────────┘    │
│           │                               │                     │
└───────────┼───────────────────────────────┼─────────────────────┘
            │                               │
            ▼                               │
┌────────────────────────────┐   ┌─────────┴──────────────┐
│    Azure Cosmos DB         │   │  Qualtrics REST API    │
│  ┌──────────────────────┐  │   │  - Distribution Stats  │
│  │ DistributionSnapshot │  │   │  - Survey Metadata     │
│  │ (Time-series)        │  │   │  - Response Counts     │
│  ├──────────────────────┤  │   └────────────────────────┘
│  │ DispositionAggregate │  │
│  │ (Survey rollups)     │  │
│  ├──────────────────────┤  │
│  │ PollingConfiguration │  │
│  │ (User preferences)   │  │
│  └──────────────────────┘  │
└────────────────────────────┘
```

### Data Flow

**Polling Cycle** (every 30-60 seconds):
```
1. DistributionPollingService (Background Timer)
   ↓
2. QualtricsService.GetDistributionsForSurveyAsync(surveyId)
   → Returns list of distribution IDs
   ↓
3. For each distribution:
   QualtricsService.GetDistributionStatsAsync(distributionId)
   → Returns { sent, bounced, opened, clicked, finished, ... }
   ↓
4. Calculate disposition metrics:
   - bounceRate = (bounced / sent) × 100
   - openRate = (opened / (sent - bounced)) × 100
   - clickRate = (clicked / opened) × 100
   - responseRate = (finished / sent) × 100
   - completionRate = (finished / opened) × 100
   ↓
5. Create DistributionSnapshot document
   ↓
6. Upsert to Cosmos DB (partition key: surveyId)
   ↓
7. SignalR Hub broadcasts to clients:
   await Clients.Group($"survey_{surveyId}")
       .SendAsync("DispositionUpdate", snapshot);
   ↓
8. React Dashboard receives update via WebSocket
   ↓
9. UI updates metrics without page refresh
```

### Component Details

#### 1. DistributionPollingService (Background Service)
**Technology**: ASP.NET Core `BackgroundService`
**Trigger**: Timer (configurable 30-60 second interval)
**Responsibilities**:
- Poll Qualtrics API for active survey distributions
- Fetch distribution stats from optimized endpoint (3000 RPM)
- Calculate disposition metrics with proper null handling
- Write time-series snapshots to Cosmos DB
- Trigger SignalR broadcasts to connected clients
- Handle rate limiting with exponential backoff
- Log polling metrics to Application Insights

**Configuration** (from `qualtrics-config.json`):
```json
{
  "distributions": {
    "pollingInterval": 60,        // seconds
    "maxConcurrentPolls": 5,      // parallel surveys
    "dispositionMapping": { ... }
  }
}
```

#### 2. Cosmos DB Data Models

**DistributionSnapshot** (Time-Series):
```csharp
public class DistributionSnapshot
{
    public string Id { get; set; }              // distributionId_timestamp
    public string DistributionId { get; set; }
    public string SurveyId { get; set; }        // Partition key
    public DateTime Timestamp { get; set; }

    // Raw Counts
    public int Sent { get; set; }
    public int Bounced { get; set; }
    public int Opened { get; set; }
    public int Clicked { get; set; }
    public int Started { get; set; }
    public int Finished { get; set; }

    // Calculated Rates
    public decimal BounceRate { get; set; }
    public decimal OpenRate { get; set; }
    public decimal ClickRate { get; set; }
    public decimal ResponseRate { get; set; }
    public decimal CompletionRate { get; set; }

    // Metadata
    public string DistributionChannel { get; set; }
    public DateTime? SentDate { get; set; }
    public string Status { get; set; }          // Active, Completed, Paused
}
```

**DispositionAggregate** (Survey Rollup):
```csharp
public class DispositionAggregate
{
    public string Id { get; set; }              // surveyId
    public string SurveyId { get; set; }        // Partition key
    public string SurveyName { get; set; }

    // Aggregate Counts (all distributions)
    public int TotalSent { get; set; }
    public int TotalBounced { get; set; }
    public int TotalOpened { get; set; }
    public int TotalClicked { get; set; }
    public int TotalFinished { get; set; }

    // Aggregate Rates
    public decimal AvgBounceRate { get; set; }
    public decimal AvgOpenRate { get; set; }
    public decimal AvgClickRate { get; set; }
    public decimal AvgResponseRate { get; set; }

    // Activity Metrics
    public int ActiveDistributions { get; set; }
    public int TotalDistributions { get; set; }
    public DateTime? LastActivityDate { get; set; }
    public DateTime LastUpdated { get; set; }
}
```

**PollingConfiguration** (User Preferences):
```csharp
public class PollingConfiguration
{
    public string Id { get; set; }              // userId or "default"
    public string UserId { get; set; }
    public int PollingIntervalSeconds { get; set; } = 60;
    public List<string> MonitoredSurveyIds { get; set; }
    public bool EnableNotifications { get; set; }
    public Dictionary<string, decimal> AlertThresholds { get; set; }
}
```

#### 3. SignalR Hub
**Technology**: Azure SignalR Service + ASP.NET Core SignalR Hub
**Responsibilities**:
- Accept WebSocket connections from React clients
- Manage survey subscription groups
- Broadcast disposition updates to subscribed clients
- Handle connection lifecycle (connect/disconnect)

**Implementation**:
```csharp
public class DispositionHub : Hub
{
    public async Task SubscribeToSurvey(string surveyId)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, $"survey_{surveyId}");

        // Send current stats immediately
        var aggregate = await _dispositionService.GetCurrentAggregateAsync(surveyId);
        await Clients.Caller.SendAsync("InitialStats", aggregate);
    }

    public async Task UnsubscribeFromSurvey(string surveyId)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"survey_{surveyId}");
    }
}
```

#### 4. React Dashboard
**Technology**: React 18+ with TypeScript, SignalR client
**Responsibilities**:
- Display real-time disposition metrics
- Render trend charts (7/30/90 day views)
- Handle SignalR connection management
- Survey selection and filtering
- Responsive design for mobile/desktop

**Key Components**:
- `DispositionDashboard` - Main container
- `MetricsPanel` - Live metric cards with color coding
- `TrendChart` - Time-series visualization (Chart.js or Recharts)
- `SurveySelector` - Multi-survey dropdown
- `ComparisonGrid` - Side-by-side survey comparison

---

## 📝 Implementation Steps

### Phase 1: Backend Foundation (Week 1)

1. **Create Data Models** (Day 1)
   - Define `DistributionSnapshot`, `DispositionAggregate`, `PollingConfiguration`
   - Create DTOs for API responses
   - Set up Cosmos DB containers with proper indexing

2. **Implement DistributionPollingService** (Days 2-3)
   - Background service with timer-based polling
   - Fetch distributions using `QualtricsService.GetDistributionsForSurveyAsync()`
   - Fetch stats using `QualtricsService.GetDistributionStatsAsync()` (3000 RPM)
   - Calculate disposition metrics with null handling
   - Upsert snapshots to Cosmos DB
   - Error handling with exponential backoff
   - Application Insights logging

3. **Build Disposition API** (Day 4)
   - `GET /api/disposition/surveys/{surveyId}/aggregate` - Current aggregate
   - `GET /api/disposition/surveys/{surveyId}/history?days=7` - Time-series
   - `GET /api/disposition/distributions/{distributionId}` - Single distribution
   - `GET /api/disposition/surveys` - All monitored surveys

4. **Integrate SignalR Hub** (Day 5)
   - Create `DispositionHub` with subscribe/unsubscribe methods
   - Trigger broadcasts from polling service
   - Configure Azure SignalR Service connection
   - Test real-time updates with Postman + SignalR client

### Phase 2: Frontend Dashboard (Week 2)

5. **Setup React Application** (Day 1)
   - Create React app with TypeScript
   - Install SignalR client (`@microsoft/signalr`)
   - Setup routing and layout structure
   - Configure API client (axios or fetch)

6. **Build Core Components** (Days 2-3)
   - `MetricsPanel` - Display disposition metrics with color coding
   - `TrendChart` - Line chart for time-series (use Recharts)
   - `SurveySelector` - Dropdown with search
   - `StatusIndicator` - Live connection status

7. **Implement Real-Time Updates** (Day 4)
   - SignalR connection management hook
   - Subscribe to survey updates on mount
   - Handle disconnection and reconnection
   - Optimistic UI updates

8. **Polish & Responsive Design** (Day 5)
   - Mobile-responsive layout (CSS Grid/Flexbox)
   - Loading states and skeletons
   - Error boundaries and fallback UI
   - Accessibility improvements (ARIA labels)

### Phase 3: Advanced Features (Week 3)

9. **Historical Trend Visualization** (Days 1-2)
   - Fetch time-series data from API
   - Render 7/30/90 day charts with selectable periods
   - Add comparison overlays (current vs previous period)
   - Peak activity time heatmap

10. **Multi-Survey Comparison** (Days 3-4)
    - Grid layout for 2-4 surveys side-by-side
    - Comparative metrics highlighting (best/worst)
    - Export to CSV functionality

11. **Alerting & Notifications** (Day 5)
    - Define alert thresholds (bounce > 10%, open < 20%)
    - Visual indicators for anomalies
    - Browser notifications (Notification API)
    - Alert configuration panel

### Phase 4: Production Readiness (Week 4)

12. **Testing** (Days 1-2)
    - Unit tests for polling service (90%+ coverage)
    - Integration tests for API endpoints
    - E2E tests for critical user flows (Playwright)
    - Load testing with K6 (simulate 50+ concurrent users)

13. **Observability** (Day 3)
    - Application Insights dashboard
    - Custom metrics (poll success rate, update latency)
    - Alerts for polling failures
    - Cost monitoring dashboard

14. **Documentation** (Day 4)
    - User guide with screenshots
    - API documentation (Swagger)
    - Deployment runbook
    - Troubleshooting guide

15. **Deployment** (Day 5)
    - Deploy to Azure Container Apps
    - Configure CI/CD pipeline
    - Production smoke tests
    - Monitoring validation

---

## 🧪 Testing Strategy

### Unit Tests
- **Disposition Calculation Logic**: Test all metric calculations with edge cases (zero sent, all bounced)
- **Polling Service**: Mock Qualtrics API, verify Cosmos DB writes
- **SignalR Hub**: Test group management and broadcasting

### Integration Tests
- **API Endpoints**: Verify response formats and status codes
- **Cosmos DB Queries**: Test partition key efficiency
- **SignalR Connection**: End-to-end message flow

### Performance Tests
- **Polling Efficiency**: Measure API call count and RU consumption
- **Dashboard Load Time**: Verify < 3 second target
- **Concurrent Users**: Test 50+ simultaneous connections

### Validation Criteria
- [ ] All disposition metrics calculate correctly
- [ ] Real-time updates arrive within 60 seconds
- [ ] No PII data stored in database
- [ ] Dashboard loads in < 3 seconds
- [ ] 99.5%+ polling success rate

---

## 📊 Success Metrics

### Quantitative Targets
- **Update Latency**: < 60 seconds (poll → UI update)
- **Dashboard Load Time**: < 3 seconds initial load
- **API Response Time**: < 500ms for aggregate queries
- **Polling Success Rate**: > 99.5%
- **Cost per Survey**: < $0.10/month (Cosmos DB + compute)
- **Rate Limit Utilization**: < 50% of Qualtrics 3000 RPM limit

### Qualitative Goals
- **User Experience**: Intuitive, responsive, professional design
- **Reliability**: Zero data loss during polling failures
- **Privacy**: 100% aggregate-only data validation
- **Maintainability**: Clean code, comprehensive documentation

---

## 🔗 Dependencies

### Prerequisites
- [x] Qualtrics API integration (`QualtricsService`) - **Complete**
- [x] Azure Cosmos DB provisioned - **Complete**
- [x] Azure SignalR Service created - **Complete**
- [x] Configuration management system - **Complete**
- [ ] React development environment setup
- [ ] CI/CD pipeline configured

### Related Work
- `DK-QUALTRICS-API-v1.0.0.md` - API integration patterns
- `qualtrics-dashboard.instructions.md` - Development guidelines
- `QUALTRICS-API-REFERENCE.md` - Complete endpoint documentation

---

## ⚠️ Risks & Mitigation

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| **Rate Limit Exceeded** | High - Polling stops | Medium | Use optimized endpoint (3000 RPM), implement exponential backoff, monitor utilization |
| **Qualtrics API Downtime** | Medium - Stale data | Low | Cache last known values, show "last updated" timestamp, auto-retry |
| **Cosmos DB Throttling** | Medium - Update delays | Low | Optimize partition key usage, use bulk operations, monitor RU consumption |
| **SignalR Connection Drops** | Low - Temporary staleness | Medium | Auto-reconnect logic, show connection status, fallback to polling |
| **Cost Overruns** | Medium - Budget impact | Low | Set budget alerts, optimize polling interval, implement data retention policy |

---

## 📚 Resources

### Documentation
- [Qualtrics API Documentation](https://api.qualtrics.com/)
- [Azure SignalR Service Docs](https://learn.microsoft.com/azure/azure-signalr/)
- [React SignalR Client](https://learn.microsoft.com/aspnet/core/signalr/javascript-client)
- [Cosmos DB Best Practices](https://learn.microsoft.com/azure/cosmos-db/nosql/best-practice)

### Tools
- **Development**: VS Code, .NET 8 SDK, Node.js 20+
- **Testing**: xUnit, Playwright, K6
- **Monitoring**: Application Insights, Azure Monitor

### References
- Meditation session: `meditation-session-2025-11-04-qualtrics-api-optimization.prompt.md`
- Rate limiting case study: 10x improvement achieved (300 RPM → 3000 RPM)

---

## 📅 Timeline

| Milestone | Target Date | Status |
|-----------|-------------|--------|
| **Phase 1**: Backend foundation complete | 2025-11-17 | 🔄 In Progress |
| **Phase 2**: Frontend dashboard operational | 2025-11-24 | ⏳ Planned |
| **Phase 3**: Advanced features implemented | 2025-12-01 | ⏳ Planned |
| **Phase 4**: Production deployment | 2025-12-08 | ⏳ Planned |
| **Launch**: Public availability | 2025-12-15 | 🎯 Target |

---

## 💬 Notes

### Key Design Decisions

**Why Polling Over Webhooks?**
- Webhooks require public endpoint (additional security complexity)
- Polling with 30-60 second interval is sufficient for "real-time" perception
- More predictable API usage (easier to stay under rate limits)
- Simpler failure recovery (just retry next poll)

**Why Distribution Endpoint Over History?**
- 10x better rate limit (3000 RPM vs 300 RPM)
- Single request vs paginated aggregation
- Officially supported stats object
- 57% less code complexity

**Why Cosmos DB Over SQL?**
- Better scalability for time-series data
- Lower latency for high-throughput writes
- Partition key strategy optimizes for per-survey queries
- Pay-per-RU model more cost-effective at scale

### Open Questions
- [ ] Should we support webhook fallback for < 30 second latency needs?
- [ ] What's the optimal polling interval (30s vs 60s vs user-configurable)?
- [ ] Do we need offline mode with service worker caching?
- [ ] Should comparison views support > 4 surveys?

---

## ✅ Completion Checklist

### Backend
- [ ] Data models created and deployed to Cosmos DB
- [ ] DistributionPollingService implemented and tested
- [ ] Disposition API endpoints functional
- [ ] SignalR Hub integrated and broadcasting
- [ ] Error handling and retry logic verified
- [ ] Application Insights logging configured

### Frontend
- [ ] React app structure complete
- [ ] SignalR client connected successfully
- [ ] MetricsPanel displaying live updates
- [ ] TrendChart rendering historical data
- [ ] SurveySelector functional
- [ ] Responsive design validated on mobile/desktop

### Testing
- [ ] Unit tests passing (> 80% coverage)
- [ ] Integration tests successful
- [ ] Performance targets validated
- [ ] Security audit passed (no PII leakage)

### Deployment
- [ ] CI/CD pipeline operational
- [ ] Production environment deployed
- [ ] Monitoring dashboards created
- [ ] Documentation published
- [ ] User acceptance testing complete

### Launch
- [ ] Smoke tests in production passed
- [ ] Performance metrics validated
- [ ] Cost monitoring active
- [ ] User training completed
- [ ] Retrospective documented

---

*Plan created by: Alex Q (Qualtrics Specialist)*
*Last updated: 2025-11-10*
*Status: Ready for implementation - Phase 1 starting*
