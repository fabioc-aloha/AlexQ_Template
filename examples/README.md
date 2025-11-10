# Code Examples

This directory contains standalone, runnable code examples demonstrating production-ready patterns for Qualtrics + Azure integration. Each example is self-contained and can be used as a reference for your own implementation.

---

## 📁 Examples Index

### Core Patterns
- **[webhook-validator.cs](webhook-validator.cs)** - HMAC-SHA256 webhook signature validation
- **[export-processor.cs](export-processor.cs)** - Survey export with exponential backoff
- **[rate-limiter.cs](rate-limiter.cs)** - Request throttling and rate limit management
- **[cosmos-repository.cs](cosmos-repository.cs)** - Cosmos DB repository pattern with partition keys

### Integration Examples
- **[qualtrics-client-basic.cs](qualtrics-client-basic.cs)** - Basic Qualtrics API client
- **[qualtrics-distribution-stats.cs](qualtrics-distribution-stats.cs)** - Fetch distribution statistics
- **[signalr-hub-example.cs](signalr-hub-example.cs)** - SignalR real-time broadcasting

### Configuration Examples
- **[qualtrics-config-loader.cs](qualtrics-config-loader.cs)** - Load and validate qualtrics-config.json
- **[keyvault-integration.cs](keyvault-integration.cs)** - Azure Key Vault secrets management

### Utility Examples
- **[disposition-calculator.cs](disposition-calculator.cs)** - Calculate disposition metrics
- **[retry-policy.cs](retry-policy.cs)** - Polly retry policy configurations

---

## 🚀 How to Use These Examples

### 1. Copy-Paste Ready
Each example is self-contained with:
- All necessary using statements
- Input parameter documentation
- Error handling patterns
- Example usage in comments

### 2. Adapt to Your Needs
- Replace placeholder values (API tokens, URLs)
- Adjust timeout and retry settings
- Customize for your specific requirements

### 3. Integrate into Your Project
- Copy the example file to your project
- Add necessary NuGet packages (documented in comments)
- Wire up dependency injection if needed

---

## 📦 Required NuGet Packages

Most examples require these packages:
```xml
<PackageReference Include="Azure.Identity" Version="1.12.0" />
<PackageReference Include="Azure.Security.KeyVault.Secrets" Version="4.6.0" />
<PackageReference Include="Microsoft.Azure.Cosmos" Version="3.41.0" />
<PackageReference Include="Microsoft.AspNetCore.SignalR.Client" Version="8.0.0" />
<PackageReference Include="Polly" Version="8.4.0" />
<PackageReference Include="System.Text.Json" Version="8.0.0" />
```

---

## 🎓 Learning Path

**For Beginners**:
1. Start with `qualtrics-client-basic.cs` - Understand API basics
2. Try `disposition-calculator.cs` - Learn metric calculations
3. Review `qualtrics-config-loader.cs` - Configuration management

**For Integration**:
1. Study `webhook-validator.cs` - Security fundamentals
2. Implement `export-processor.cs` - Handle large data exports
3. Use `rate-limiter.cs` - Prevent API throttling

**For Production**:
1. Apply `keyvault-integration.cs` - Secure secrets management
2. Implement `cosmos-repository.cs` - Efficient data storage
3. Use `signalr-hub-example.cs` - Real-time updates

---

## 🔗 Related Documentation

- **API Reference**: `domain-knowledge/DK-QUALTRICS-API-v1.0.0.md` (140+ endpoints)
- **Architecture Guide**: `TEMPLATE-QUALTRICS-AZURE-PROJECT.md`
- **Configuration**: `qualtrics/qualtrics-config.json`
- **Development Guide**: `qualtrics/qualtrics-dashboard.instructions.md`

---

## 💡 Tips

- **Test with Postman first** - Verify API calls before coding
- **Use the Cosmos DB Emulator** - Free local development
- **Enable detailed logging** - Helps debug integration issues
- **Start simple** - Get basic API calls working before adding complexity
- **Read the DK file** - Most questions answered in domain knowledge docs

---

*Examples based on production-ready patterns*
*All code tested and verified*
*Ready for copy-paste into your projects*
