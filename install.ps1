#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Installs ai-config into a target project using symlinks.

.DESCRIPTION
    This script creates symbolic links from a target project to the ai-config repository,
    linking configuration files and directories.

.PARAMETER TargetPath
    The path to the target project where ai-config will be installed.
    If not provided, uses the current directory.

.PARAMETER AiConfigPath
    The path to the ai-config repository.
    If not provided, uses the directory where this script is located.

.EXAMPLE
    .\install.ps1 -TargetPath "C:\projects\my-project"

.EXAMPLE
    .\install.ps1
    # Installs in the current directory
#>

param(
    [string]$TargetPath = ".",
    [string]$AiConfigPath = $null
)

#Requires -RunAsAdministrator

# Colors for output
$Green = "`e[32m"
$Yellow = "`e[33m"
$Red = "`e[31m"
$Reset = "`e[0m"

function Write-Success { param([string]$Message) Write-Host "${Green}✓${Reset} $Message" }
function Write-Warning { param([string]$Message) Write-Host "${Yellow}⚠${Reset} $Message" }
function Write-Error { param([string]$Message) Write-Host "${Red}✗${Reset} $Message" }

# Resolve paths to absolute paths
$TargetPath = Resolve-Path $TargetPath | Select-Object -ExpandProperty Path

# Determine ai-config path
if ([string]::IsNullOrEmpty($AiConfigPath)) {
    $AiConfigPath = Split-Path -Parent $MyInvocation.MyCommand.Path
}
$AiConfigPath = Resolve-Path $AiConfigPath | Select-Object -ExpandProperty Path

Write-Host ""
Write-Host "=== AI-Config Installer ==="
Write-Host ""
Write-Host "ai-config path: $AiConfigPath"
Write-Host "Target path:    $TargetPath"
Write-Host ""

# Verify ai-config structure exists
$requiredPaths = @(
    "opencode.jsonc",
    ".opencode\agents",
    ".opencode\commands",
    ".opencode\skills",
    "templates\AGENTS.md"
)

$validConfig = $true
foreach ($req in $requiredPaths) {
    $fullPath = Join-Path $AiConfigPath $req
    if (-not (Test-Path $fullPath)) {
        Write-Error "Missing required path: $req"
        $validConfig = $false
    }
}

if (-not $validConfig) {
    Write-Error "Invalid ai-config repository structure"
    exit 1
}

# Create symlinks
$links = @(
    @{ Source = "opencode.jsonc"; Target = "opencode.jsonc"; Type = "File" },
    @{ Source = ".opencode\agents"; Target = ".opencode\agents"; Type = "Directory" },
    @{ Source = ".opencode\commands"; Target = ".opencode\commands"; Type = "Directory" },
    @{ Source = ".opencode\skills"; Target = ".opencode\skills"; Type = "Directory" },
    @{ Source = "templates\AGENTS.md"; Target = "AGENTS.md"; Type = "File" }
)

$successCount = 0
$warningCount = 0

foreach ($link in $links) {
    $sourcePath = Join-Path $AiConfigPath $link.Source
    $targetPath = Join-Path $TargetPath $link.Target

    # Ensure parent directory exists for .opencode
    $parentDir = Split-Path -Parent $targetPath
    if (-not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
        Write-Success "Created directory: $parentDir"
    }

    # Remove existing file/directory if it exists
    if (Test-Path $targetPath) {
        $item = Get-Item $targetPath
        if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
            # It's already a symlink, remove it
            Remove-Item $targetPath -Force
            Write-Warning "Removed existing symlink: $($link.Target)"
        } else {
            # It's a real file/directory, back it up
            $backupPath = "$targetPath.backup.$(Get-Date -Format 'yyyyMMddHHmmss')"
            Rename-Item $targetPath $backupPath
            Write-Warning "Backed up existing file: $($link.Target) -> $backupPath"
        }
    }

    # Create the symlink
    try {
        if ($link.Type -eq "Directory") {
            New-Item -ItemType SymbolicLink -Path $targetPath -Target $sourcePath -Force | Out-Null
        } else {
            New-Item -ItemType SymbolicLink -Path $targetPath -Target $sourcePath -Force | Out-Null
        }
        Write-Success "Created symlink: $($link.Target) -> $($link.Source)"
        $successCount++
    }
    catch {
        Write-Error "Failed to create symlink: $($link.Target) - $($_.Exception.Message)"
    }
}

Write-Host ""
Write-Host "=== Installation Summary ==="
Write-Host ""
Write-Success "Successfully created $successCount/$($links.Count) symlinks"
if ($warningCount -gt 0) {
    Write-Warning "$warningCount warnings"
}
Write-Host ""
Write-Host "Your project is now linked to ai-config!"
Write-Host "Any changes in ai-config will be reflected in this project."
Write-Host ""
