#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Lists all projects with ai-config installed.

.DESCRIPTION
    This script displays all registered projects from installed-projects.md
    and checks if their symlinks are still valid.

.EXAMPLE
    .\list.ps1
#>

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

# Determine ai-config path
$AiConfigPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$AiConfigPath = Resolve-Path $AiConfigPath | Select-Object -ExpandProperty Path

Write-Host ""
Write-Host "=== AI-Config Projects ==="
Write-Host ""

# Check if installed-projects.md exists
$projectsFile = Join-Path $AiConfigPath "installed-projects.md"
if (-not (Test-Path $projectsFile)) {
    Write-Error "No installed-projects.md found."
    Write-Info "Run install.ps1 first to register projects."
    exit 1
}

# Parse installed-projects.md
$content = Get-Content $projectsFile -Raw
$projects = @()

# Parse markdown table (skip header rows)
$lines = $content -split "`n" | Where-Object { $_ -match "^\|" }
for ($i = 2; $i -lt $lines.Count; $i++) {
    $line = $lines[$i].Trim()
    if ($line -and $line -ne "") {
        # Extract project name and path from | col1 | col2 |
        $matches = [regex]::Matches($line, "\|\s*([^|]+)\s*\|")
        if ($matches.Count -ge 3) {
            $projectName = $matches[1].Groups[1].Value.Trim()
            $projectPath = $matches[2].Groups[1].Value.Trim()
            $projects += @{ Name = $projectName; Path = $projectPath }
        }
    }
}

if ($projects.Count -eq 0) {
    Write-Warning "No projects found in installed-projects.md"
    exit 0
}

Write-Info "Found $($projects.Count) registered project(s):"
Write-Host ""

foreach ($project in $projects) {
    Write-Host "$($project.Name)"
    Write-Host "  Path: $($project.Path)"
    
    if (Test-Path $project.Path) {
        # Check if symlinks exist
        $symlinks = @(
            (Join-Path $project.Path "opencode.jsonc"),
            (Join-Path $project.Path ".opencode\agents"),
            (Join-Path $project.Path ".opencode\commands"),
            (Join-Path $project.Path ".opencode\skills"),
            (Join-Path $project.Path "AGENTS.md")
        )
        
        $validCount = 0
        $totalCount = $symlinks.Count
        
        foreach ($symlink in $symlinks) {
            if (Test-Path $symlink) {
                $item = Get-Item $symlink
                if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
                    $validCount++
                }
            }
        }
        
        if ($validCount -eq $totalCount) {
            Write-Success "  Status: All symlinks valid ($validCount/$totalCount)"
        } elseif ($validCount -gt 0) {
            Write-Warning "  Status: Partial ($validCount/$totalCount symlinks)"
        } else {
            Write-Error "  Status: No symlinks found"
        }
    } else {
        Write-Error "  Status: Directory not found"
    }
    
    Write-Host ""
}

Write-Host "Run 'update.ps1' to refresh all projects."
Write-Host ""
