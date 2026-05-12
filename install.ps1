#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Installs ai-config into a target project using symlinks.

.DESCRIPTION
    This script creates symbolic links from a target project to the ai-config repository.
    By default, it is conservative and will NOT overwrite existing files.

.PARAMETER Repo
    The path to the target project where ai-config will be installed.
    If not provided, uses the current directory.

.PARAMETER DryRun
    Show what would be done without making any changes.

.PARAMETER Force
    Force refresh of existing symlinks. Without this, existing symlinks are skipped.

.EXAMPLE
    .\install.ps1 --repo "C:\projects\my-project" --dry-run

.EXAMPLE
    .\install.ps1 --repo "C:\projects\my-project"

.EXAMPLE
    .\install.ps1 --repo "C:\projects\my-project" --force
#>

[CmdletBinding()]
param(
    [Parameter()]
    [Alias("r")]
    [string]$Repo = ".",

    [Parameter()]
    [switch]$DryRun,

    [Parameter()]
    [switch]$Force
)

#Requires -RunAsAdministrator

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
function Write-DryRun { param([string]$Message) Write-Host "${Cyan}[DRY-RUN]${Reset} $Message" }

# Determine ai-config path (where this script is located)
$AiConfigPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$AiConfigPath = Resolve-Path $AiConfigPath | Select-Object -ExpandProperty Path

# Resolve target repo path
$Repo = Resolve-Path $Repo | Select-Object -ExpandProperty Path

Write-Host ""
Write-Host "=== AI-Config Installer ==="
Write-Host ""

if ($DryRun) {
    Write-Host "${Cyan}DRY RUN MODE - No changes will be made${Reset}"
    Write-Host ""
}

Write-Host "ai-config path: $AiConfigPath"
Write-Host "Target repo:    $Repo"
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

# Define symlinks to create
$links = @(
    @{ Source = "opencode.jsonc"; Target = "opencode.jsonc"; Type = "File" },
    @{ Source = ".opencode\agents"; Target = ".opencode\agents"; Type = "Directory" },
    @{ Source = ".opencode\commands"; Target = ".opencode\commands"; Type = "Directory" },
    @{ Source = ".opencode\skills"; Target = ".opencode\skills"; Type = "Directory" },
    @{ Source = "templates\AGENTS.md"; Target = "AGENTS.md"; Type = "File" }
)

# Track results
$results = @{
    Created = @()
    Skipped = @()
    Refreshed = @()
    Conflicts = @()
    Errors = @()
}

foreach ($link in $links) {
    $sourcePath = Join-Path $AiConfigPath $link.Source
    $targetPath = Join-Path $Repo $link.Target

    # Ensure parent directory exists (always safe to create empty dirs)
    $parentDir = Split-Path -Parent $targetPath
    if (-not (Test-Path $parentDir)) {
        if ($DryRun) {
            Write-DryRun "Would create directory: $parentDir"
        } else {
            New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
            Write-Info "Created directory: $parentDir"
        }
    }

    # Check what exists at target path
    if (Test-Path $targetPath) {
        $item = Get-Item $targetPath
        $isSymlink = $item.Attributes -band [System.IO.FileAttributes]::ReparsePoint

        if ($isSymlink) {
            # It's a symlink
            if ($Force) {
                # Refresh the symlink
                if ($DryRun) {
                    Write-DryRun "Would refresh symlink: $($link.Target)"
                    $results.Refreshed += $link.Target
                } else {
                    try {
                        Remove-Item $targetPath -Force
                        if ($link.Type -eq "Directory") {
                            New-Item -ItemType SymbolicLink -Path $targetPath -Target $sourcePath -Force | Out-Null
                        } else {
                            New-Item -ItemType SymbolicLink -Path $targetPath -Target $sourcePath -Force | Out-Null
                        }
                        Write-Success "Refreshed symlink: $($link.Target) -> $($link.Source)"
                        $results.Refreshed += $link.Target
                    }
                    catch {
                        Write-Error "Failed to refresh symlink: $($link.Target) - $($_.Exception.Message)"
                        $results.Errors += $link.Target
                    }
                }
            } else {
                # Skip existing symlink
                Write-Warning "Skipped existing symlink (use --force to refresh): $($link.Target)"
                $results.Skipped += $link.Target
            }
        } else {
            # It's a real file/directory - CONFLICT (never touch these)
            Write-Error "CONFLICT - File exists: $($link.Target)"
            Write-Info "  Remove or rename the existing file manually, then re-run"
            $results.Conflicts += $link.Target
        }
    } else {
        # Nothing exists, safe to create
        if ($DryRun) {
            Write-DryRun "Would create symlink: $($link.Target) -> $($link.Source)"
            $results.Created += $link.Target
        } else {
            try {
                if ($link.Type -eq "Directory") {
                    New-Item -ItemType SymbolicLink -Path $targetPath -Target $sourcePath -Force | Out-Null
                } else {
                    New-Item -ItemType SymbolicLink -Path $targetPath -Target $sourcePath -Force | Out-Null
                }
                Write-Success "Created symlink: $($link.Target) -> $($link.Source)"
                $results.Created += $link.Target
            }
            catch {
                Write-Error "Failed to create symlink: $($link.Target) - $($_.Exception.Message)"
                $results.Errors += $link.Target
            }
        }
    }
}

# Summary
Write-Host ""
Write-Host "=== Installation Summary ==="
Write-Host ""

if ($results.Created.Count -gt 0) {
    Write-Success "Created: $($results.Created.Count) symlinks"
}
if ($results.Refreshed.Count -gt 0) {
    Write-Success "Refreshed: $($results.Refreshed.Count) symlinks"
}
if ($results.Skipped.Count -gt 0) {
    Write-Warning "Skipped: $($results.Skipped.Count) existing symlinks"
}
if ($results.Conflicts.Count -gt 0) {
    Write-Error "Conflicts: $($results.Conflicts.Count) files exist (not modified)"
}
if ($results.Errors.Count -gt 0) {
    Write-Error "Errors: $($results.Errors.Count) failed"
}

Write-Host ""

if ($DryRun) {
    Write-Host "${Cyan}This was a dry run. No changes were made.${Reset}"
    Write-Host "Run without --dry-run to apply changes."
} elseif ($results.Conflicts.Count -eq 0 -and $results.Errors.Count -eq 0) {
    Write-Success "Installation complete!"
    Write-Host "Your project is now linked to ai-config."
    
    # Register project in installed-projects.md
    $projectsFile = Join-Path $AiConfigPath "installed-projects.md"
    $projectName = Split-Path -Leaf $Repo
    
    # Create file if it doesn't exist
    if (-not (Test-Path $projectsFile)) {
        @"# Proyectos con ai-config instalado

| Proyecto | Ruta |
|----------|------|
"@ | Out-File -FilePath $projectsFile -Encoding utf8
    }
    
    # Check if already registered
    $content = Get-Content $projectsFile -Raw
    if ($content -notmatch [regex]::Escape($Repo)) {
        # Add new entry
        $newLine = "| $projectName | $Repo |"
        Add-Content -Path $projectsFile -Value $newLine
        Write-Info "Registered in installed-projects.md"
    }
} else {
    Write-Warning "Installation completed with issues."
    Write-Host "Review the conflicts above and re-run after resolving them."
}

Write-Host ""
