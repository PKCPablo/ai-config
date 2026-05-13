#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Uninstalls ai-config from a target project by removing symlinks.

.DESCRIPTION
    This script removes the symbolic links created by install.ps1.

.PARAMETER Repo
    The path to the target project where ai-config is installed.
    If not provided, uses the current directory.

.PARAMETER DryRun
    Show what would be done without making any changes.

.EXAMPLE
    .\uninstall.ps1 --repo "C:\projects\my-project" --dry-run

.EXAMPLE
    .\uninstall.ps1 --repo "C:\projects\my-project"
#>

[CmdletBinding()]
param(
    [Parameter()]
    [Alias("r")]
    [string]$Repo = ".",

    [Parameter()]
    [switch]$DryRun
)

# Colors for output (compatible with PowerShell 5.1)
$ESC = [char]27
$Green = "$ESC[32m"
$Yellow = "$ESC[33m"
$Red = "$ESC[31m"
$Cyan = "$ESC[36m"
$Reset = "$ESC[0m"

function Write-Success { param([string]$Message) Write-Host "$Green[OK]$Reset $Message" }
function Write-Warn { param([string]$Message) Write-Host "$Yellow[WARN]$Reset $Message" }
function Write-Fail { param([string]$Message) Write-Host "$Red[ERROR]$Reset $Message" }
function Write-Info { param([string]$Message) Write-Host "$Cyan[INFO]$Reset $Message" }
function Write-DryRun { param([string]$Message) Write-Host "$Cyan[DRY-RUN]$Reset $Message" }

# Resolve repo path
$Repo = Resolve-Path $Repo | Select-Object -ExpandProperty Path

Write-Host ""
Write-Host "=== AI-Config Uninstaller ==="
Write-Host ""

if ($DryRun) {
    Write-Host "${Cyan}DRY RUN MODE - No changes will be made${Reset}"
    Write-Host ""
}

Write-Host "Target repo: $Repo"
Write-Host ""

# Links to remove
$links = @(
    "opencode.jsonc",
    ".opencode\agents",
    ".opencode\commands",
    ".opencode\skills",
    "AGENTS.md"
)

# Track results
$results = @{
    Removed = @()
    NotFound = @()
    Skipped = @()
}

foreach ($link in $links) {
    $targetPath = Join-Path $Repo $link

    if (Test-Path $targetPath) {
        $item = Get-Item $targetPath
        $isSymlink = $item.Attributes -band [System.IO.FileAttributes]::ReparsePoint

        if ($isSymlink) {
            if ($DryRun) {
                Write-DryRun "Would remove symlink: $link"
                $results.Removed += $link
            } else {
                Remove-Item $targetPath -Force -Confirm:$false -Recurse -ErrorAction SilentlyContinue
                Write-Success "Removed symlink: $link"
                $results.Removed += $link
            }
        } else {
            Write-Warn "Not a symlink (skipping): $link"
            $results.Skipped += $link
        }
    } else {
        $results.NotFound += $link
    }
}

# Clean up .opencode directory completely (remove all files including node_modules, package.json, etc.)
$openCodePath = Join-Path $Repo ".opencode"
if (Test-Path $openCodePath) {
    if ($DryRun) {
        Write-DryRun "Would remove entire directory: .opencode (including node_modules, package.json, etc.)"
    } else {
        Remove-Item $openCodePath -Force -Confirm:$false -Recurse -ErrorAction SilentlyContinue
        Write-Success "Removed entire directory: .opencode (including node_modules, package.json, bun.lock, .gitignore)"
    }
}

# Determine ai-config path (parent of install directory)
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$AiConfigPath = Split-Path -Parent $ScriptPath
$AiConfigPath = Resolve-Path $AiConfigPath | Select-Object -ExpandProperty Path

# Update installed-projects.md to remove this project
$projectsFile = Join-Path $AiConfigPath "installed-projects.md"
if ((Test-Path $projectsFile) -and (-not $DryRun)) {
    $content = Get-Content $projectsFile
    $updatedContent = @()
    $removed = $false
    
    foreach ($line in $content) {
        # Check if this line contains the repo path (matching by path)
        if ($line -match [regex]::Escape($Repo)) {
            $removed = $true
            continue  # Skip this line (remove it)
        }
        $updatedContent += $line
    }
    
    if ($removed) {
        try {
            $updatedContent | Out-File -FilePath $projectsFile -Encoding utf8
            Write-Info "Removed from installed-projects.md"
        }
        catch {
            Write-Warn "Could not update installed-projects.md (permission denied)"
            Write-Info "To manually update, remove this line from installed-projects.md:"
            Write-Host "    | $(Split-Path -Leaf $Repo) | $Repo |"
            Write-Host ""
            Write-Info "Or run PowerShell as Administrator and retry."
        }
    }
} elseif ($DryRun -and (Test-Path $projectsFile)) {
    $content = Get-Content $projectsFile
    foreach ($line in $content) {
        if ($line -match [regex]::Escape($Repo)) {
            Write-DryRun "Would remove entry from installed-projects.md: $line"
            break
        }
    }
}

Write-Host ""
Write-Host "=== Uninstallation Summary ==="
Write-Host ""

if ($results.Removed.Count -gt 0) {
    Write-Success "Removed: $($results.Removed.Count) symlinks"
}
if ($results.Skipped.Count -gt 0) {
    Write-Warn "Skipped: $($results.Skipped.Count) non-symlinks"
}
if ($results.NotFound.Count -gt 0) {
    Write-Info "Not found: $($results.NotFound.Count) links"
}

Write-Host ""

if ($DryRun) {
    Write-Host "${Cyan}This was a dry run. No changes were made.${Reset}"
} else {
    Write-Host "ai-config has been uninstalled from this project."
    Write-Host ""
    Write-Info "Project list updated in installed-projects.md"
}

Write-Host ""
