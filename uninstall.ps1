#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Uninstalls ai-config from a target project by removing symlinks.

.DESCRIPTION
    This script removes the symbolic links created by install.ps1.

.PARAMETER TargetPath
    The path to the target project where ai-config is installed.
    If not provided, uses the current directory.

.EXAMPLE
    .\uninstall.ps1 -TargetPath "C:\projects\my-project"
#>

param(
    [string]$TargetPath = "."
)

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

Write-Host ""
Write-Host "=== AI-Config Uninstaller ==="
Write-Host ""
Write-Host "Target path: $TargetPath"
Write-Host ""

# Links to remove
$links = @(
    "opencode.jsonc",
    ".opencode\agents",
    ".opencode\commands",
    ".opencode\skills",
    "AGENTS.md"
)

$successCount = 0
$notFoundCount = 0

foreach ($link in $links) {
    $targetPath = Join-Path $TargetPath $link

    if (Test-Path $targetPath) {
        $item = Get-Item $targetPath
        if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
            # It's a symlink, remove it
            Remove-Item $targetPath -Force
            Write-Success "Removed symlink: $link"
            $successCount++
        } else {
            Write-Warning "Not a symlink (skipping): $link"
        }
    } else {
        $notFoundCount++
    }
}

# Clean up empty .opencode directory if it exists
$openCodePath = Join-Path $TargetPath ".opencode"
if (Test-Path $openCodePath) {
    $children = Get-ChildItem $openCodePath -ErrorAction SilentlyContinue
    if (-not $children) {
        Remove-Item $openCodePath -Force
        Write-Success "Removed empty directory: .opencode"
    }
}

Write-Host ""
Write-Host "=== Uninstallation Summary ==="
Write-Host ""
Write-Success "Removed $successCount symlinks"
if ($notFoundCount -gt 0) {
    Write-Warning "$notFoundCount links not found"
}
Write-Host ""
Write-Host "ai-config has been uninstalled from this project."
Write-Host ""
