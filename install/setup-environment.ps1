# Script to configure OpenCode environment variables permanently
# Run as: .\setup-environment.ps1

param(
    [string]$ApiKey = "",
    [string]$BaseUrl = "https://marc-mi78c7vc-swedencentral.services.ai.azure.com/models",
    [string]$ApiVersion = "2024-05-01-preview"
)

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "OpenCode Environment Setup" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Ask for API Key if not provided
if ([string]::IsNullOrWhiteSpace($ApiKey)) {
    $ApiKeySecure = Read-Host "Enter your KIMI_API_KEY" -AsSecureString
    $ApiKey = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($ApiKeySecure))
}

if ([string]::IsNullOrWhiteSpace($ApiKey)) {
    Write-Host "Error: API Key is required" -ForegroundColor Red
    exit 1
}

# Configure environment variables permanently (user level)
Write-Host "Configuring environment variables..." -ForegroundColor Yellow

[Environment]::SetEnvironmentVariable("KIMI_API_KEY", $ApiKey, "User")
[Environment]::SetEnvironmentVariable("KIMI_BASE_URL", $BaseUrl, "User")
[Environment]::SetEnvironmentVariable("KIMI_API_VERSION", $ApiVersion, "User")

Write-Host ""
Write-Host "Environment variables configured successfully!" -ForegroundColor Green
Write-Host "   - KIMI_API_KEY: *** (hidden)" -ForegroundColor Gray
Write-Host "   - KIMI_BASE_URL: $BaseUrl" -ForegroundColor Gray
Write-Host "   - KIMI_API_VERSION: $ApiVersion" -ForegroundColor Gray
Write-Host ""

Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "   1. Open a new PowerShell window (to load environment variables)" -ForegroundColor White
Write-Host "   2. Run 'opencode --version' to verify it works" -ForegroundColor White
Write-Host "   3. Run 'opencode' to start using OpenCode" -ForegroundColor White
Write-Host ""
Write-Host "Note: OpenCode will read configuration from each project's" -ForegroundColor Gray
Write-Host "      symlinked opencode.jsonc file (created by install.ps1)" -ForegroundColor Gray
Write-Host ""
Write-Host "To install ai-config in a project, run:" -ForegroundColor Gray
Write-Host "   .\install\install.ps1 --repo 'C:\path\to\project'" -ForegroundColor Gray
