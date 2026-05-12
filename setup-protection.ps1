#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Sets up branch protection hooks for a repository.

.DESCRIPTION
    This script installs git hooks to prevent direct pushes to main/master branches.
    It should be run in each target repository.

.PARAMETER Repo
    The path to the target repository. If not provided, uses the current directory.

.EXAMPLE
    .\setup-protection.ps1 --repo "C:\projects\my-project"

.EXAMPLE
    .\setup-protection.ps1
#>

[CmdletBinding()]
param(
    [Parameter()]
    [Alias("r")]
    [string]$Repo = "."
)

# Colors for output
$Green = "`e[32m"
$Yellow = "`e[33m"
$Red = "`e[31m"
$Cyan = "`e[36m"
$Reset = "`e[0m"

function Write-Success { param([string]$Message) Write-Host "${Green}✓${Reset} $Message" }
function Write-Warning { param([string]$Message) Write-Host "${Yellow}⚠${Reset} $Message" }
function Write-Error { param([string]$Message) Write-Host "${Red}✗${Reset} $Message" }
function Write-Info { param([string]$Message) Write-Host "${Cyan}ℹ${Reset} $Message" }

# Resolve target repo path
$Repo = Resolve-Path $Repo | Select-Object -ExpandProperty Path

Write-Host ""
Write-Host "=== Git Branch Protection Setup ==="
Write-Host ""
Write-Host "Target repo: $Repo"
Write-Host ""

# Check if it's a git repository
$gitDir = Join-Path $Repo ".git"
if (-not (Test-Path $gitDir)) {
    Write-Error "Not a git repository: $Repo"
    exit 1
}

# Determine ai-config path
$AiConfigPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$AiConfigPath = Resolve-Path $AiConfigPath | Select-Object -ExpandProperty Path

# Path to hooks
$hooksDir = Join-Path $Repo ".git\hooks"
$sourceHook = Join-Path $AiConfigPath ".git-hooks\pre-push.ps1"
$targetHook = Join-Path $hooksDir "pre-push"

if (-not (Test-Path $sourceHook)) {
    Write-Error "Source hook not found: $sourceHook"
    exit 1
}

# Check if hook already exists
if (Test-Path $targetHook) {
    Write-Warning "A pre-push hook already exists."
    Write-Info "Current hook will be backed up to: pre-push.backup"
    
    $backupPath = "$targetHook.backup.$(Get-Date -Format 'yyyyMMddHHmmss')"
    Copy-Item $targetHook $backupPath -Force
    Write-Success "Backed up existing hook"
}

# Copy the hook
Copy-Item $sourceHook $targetHook -Force

# Make it executable (not needed on Windows but good practice)
# On Windows PowerShell scripts don't need +x

Write-Success "Installed pre-push hook to: $targetHook"
Write-Host ""
Write-Info "This will prevent direct pushes to main/master branches."
Write-Info "To bypass (not recommended): git push --no-verify"
Write-Host ""
