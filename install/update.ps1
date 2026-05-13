#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Updates ai-config and verifies integrity of all linked projects.

.DESCRIPTION
    This script performs a git pull on ai-config repository and then
    verifies the integrity of symlinks in all registered projects.
    Reports any issues and offers to repair them.

.PARAMETER DryRun
    Show what would be done without making any changes.

.PARAMETER SkipPull
    Skip git pull and only verify integrity.

.PARAMETER Yes
    Automatically repair issues without asking for confirmation.

.EXAMPLE
    .\update.ps1 --dry-run

.EXAMPLE
    .\update.ps1 --skip-pull

.EXAMPLE
    .\update.ps1 --yes
#>

[CmdletBinding()]
param(
    [Parameter()]
    [switch]$DryRun,

    [Parameter()]
    [switch]$SkipPull,

    [Parameter()]
    [switch]$Yes
)

#Requires -RunAsAdministrator

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

# Determine ai-config path (parent of install directory)
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$AiConfigPath = Split-Path -Parent $ScriptPath
$AiConfigPath = Resolve-Path $AiConfigPath | Select-Object -ExpandProperty Path

Write-Host ""
Write-Host "=== AI-Config Update & Integrity Check ==="
Write-Host ""

if ($DryRun) {
    Write-Host "${Cyan}DRY RUN MODE - No changes will be made${Reset}"
    Write-Host ""
}

Write-Host "ai-config path: $AiConfigPath"
Write-Host ""

# Check if installed-projects.md exists
$projectsFile = Join-Path $AiConfigPath "installed-projects.md"
if (-not (Test-Path $projectsFile)) {
    Write-Fail "No installed-projects.md found."
    Write-Info "Run install.ps1 first to register projects."
    exit 1
}

# Step 1: Git pull (optional)
if (-not $SkipPull) {
    Write-Host "Step 1: Updating ai-config repository..."
    Write-Host ""

    if ($DryRun) {
        Write-DryRun "Would execute: git pull"
    } else {
        Set-Location -Path $AiConfigPath
        $gitOutput = git pull 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Repository updated successfully"
            if ($gitOutput -match "Already up to date") {
                Write-Info "Already up to date"
            } else {
                Write-Info $gitOutput
            }
        } else {
            Write-Fail "Git pull failed: $gitOutput"
            exit 1
        }
    }

    Write-Host ""
}

# Step 2: Parse installed-projects.md
Write-Host "Step 2: Loading registered projects..."
Write-Host ""

$content = Get-Content $projectsFile -Raw
$projects = @()

# Parse markdown table (skip header rows)
$lines = $content -split "`r?`n" | Where-Object { $_ -match "^\|" }
for ($i = 2; $i -lt $lines.Count; $i++) {
    $line = $lines[$i].Trim()
    if ($line -and $line -ne "" -and $line -notmatch "^-+") {
        # Split by | and extract columns (skip first empty column)
        $columns = $line.Split('|', [System.StringSplitOptions]::RemoveEmptyEntries)
        if ($columns.Count -ge 2) {
            $projectName = $columns[0].Trim()
            $projectPath = $columns[1].Trim()
            if ($projectName -and $projectPath -and $projectName -ne "Proyecto") {
                $projects += @{ Name = $projectName; Path = $projectPath }
            }
        }
    }
}

if ($projects.Count -eq 0) {
    Write-Warn "No projects found in installed-projects.md"
    exit 0
}

Write-Info "Found $($projects.Count) registered project(s)"
Write-Host ""

# Define expected symlinks
$expectedLinks = @(
    @{ Target = "opencode.jsonc"; Type = "File" },
    @{ Target = ".opencode\agents"; Type = "Directory" },
    @{ Target = ".opencode\commands"; Type = "Directory" },
    @{ Target = ".opencode\skills"; Type = "Directory" },
    @{ Target = "AGENTS.md"; Type = "File" }
)

# Step 3: Verify each project
Write-Host "Step 3: Verifying project integrity..."
Write-Host ""

$results = @{
    Healthy = @()
    Issues = @()
    NotFound = @()
    Repaired = @()
}

foreach ($project in $projects) {
    Write-Host "Project: $($project.Name)"
    Write-Host "  Path: $($project.Path)"
    
    if (-not (Test-Path $project.Path)) {
        Write-Fail "  Status: Directory not found"
        $results.NotFound += $project
        
        # Ask what to do
        if (-not $DryRun) {
            Write-Host ""
            Write-Host "  What would you like to do?"
            Write-Host "  [R]emove from the list"
            Write-Host "  [S]kip (keep in list)"
            Write-Host ""
            
            $choice = Read-Host "  Choose an option (R/S)"
            
            if ($choice.ToUpper() -eq "R") {
                $project.RemoveFromList = $true
                Write-Info "  Will be removed from list"
            } else {
                Write-Info "  Kept in list"
            }
        }
        
        Write-Host ""
        continue
    }
    
    # Check each expected symlink
    $projectIssues = @()
    foreach ($link in $expectedLinks) {
        $linkPath = Join-Path $project.Path $link.Target
        $linkStatus = @{ Target = $link.Target; Status = "OK"; Details = "" }
        
        if (Test-Path $linkPath) {
            $item = Get-Item $linkPath
            $isSymlink = $item.Attributes -band [System.IO.FileAttributes]::ReparsePoint
            
            if ($isSymlink) {
                # Verify it points to ai-config
                $actualTarget = $item.Target
                $expectedTarget = Join-Path $AiConfigPath $link.Target
                if ($link.Target -eq "AGENTS.md") {
                    $expectedTarget = Join-Path $AiConfigPath "templates\AGENTS.md"
                }
                
                if ($actualTarget -ne $expectedTarget) {
                    $linkStatus.Status = "WRONG_TARGET"
                    $linkStatus.Details = "Points to: $actualTarget"
                }
            } else {
                $linkStatus.Status = "NOT_SYMLINK"
                $linkStatus.Details = "Is a regular file/directory"
            }
        } else {
            $linkStatus.Status = "MISSING"
            $linkStatus.Details = "File does not exist"
        }
        
        if ($linkStatus.Status -ne "OK") {
            $projectIssues += $linkStatus
        }
    }
    
    # Display status
    if ($projectIssues.Count -eq 0) {
        Write-Success "  Status: All symlinks valid"
        $results.Healthy += $project
    } else {
        Write-Warn "  Status: $($projectIssues.Count) issue(s) found"
        foreach ($issue in $projectIssues) {
            switch ($issue.Status) {
                "MISSING" { Write-Fail "    ❌ $($issue.Target): Missing" }
                "NOT_SYMLINK" { Write-Warn "    ⚠️  $($issue.Target): Not a symlink ($($issue.Details))" }
                "WRONG_TARGET" { Write-Warn "    ⚠️  $($issue.Target): Wrong target ($($issue.Details))" }
            }
        }
        
        $project.Issues = $projectIssues
        $results.Issues += $project
        
        # Offer to repair
        if (-not $DryRun) {
            $repair = $Yes
            if (-not $Yes) {
                Write-Host ""
                $choice = Read-Host "  Repair this project? (Y/N)"
                $repair = ($choice.ToUpper() -eq "Y")
            }
            
            if ($repair) {
                Write-Info "  Repairing..."
                $installScript = Join-Path $AiConfigPath "install\install.ps1"
                $output = & $installScript --repo $project.Path --force 2>&1
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Success "  Repaired successfully"
                    $results.Repaired += $project
                } else {
                    Write-Fail "  Repair failed"
                }
            }
        }
    }
    
    Write-Host ""
}

# Step 4: Rebuild installed-projects.md if needed (remove deleted projects)
$projectsToRemove = $projects | Where-Object { $_.RemoveFromList -eq $true }
if ($projectsToRemove.Count -gt 0 -and -not $DryRun) {
    Write-Host "Step 4: Cleaning up projects list..."
    Write-Host ""
    
    $newContent = @"
# Proyectos con ai-config instalado

| Proyecto | Ruta |
|----------|------|
"@

    foreach ($project in $projects) {
        if (-not $project.RemoveFromList) {
            $newLine = "`n| $($project.Name) | $($project.Path) |"
            $newContent = $newContent + $newLine
        }
    }
    
    $newContent | Out-File -FilePath $projectsFile -Encoding utf8
    Write-Success "Removed $($projectsToRemove.Count) project(s) from list"
    Write-Host ""
}

# Summary
Write-Host "=== Summary ==="
Write-Host ""

if ($results.Healthy.Count -gt 0) {
    Write-Success "Healthy: $($results.Healthy.Count) project(s)"
}
if ($results.Repaired.Count -gt 0) {
    Write-Success "Repaired: $($results.Repaired.Count) project(s)"
}
if ($results.Issues.Count -gt $results.Repaired.Count) {
    $remainingIssues = $results.Issues.Count - $results.Repaired.Count
    Write-Warn "Issues remaining: $remainingIssues project(s)"
}
if ($results.NotFound.Count -gt 0) {
    Write-Warn "Not found: $($results.NotFound.Count) project(s)"
}
if ($projectsToRemove.Count -gt 0) {
    Write-Info "Removed from list: $($projectsToRemove.Count) project(s)"
}

Write-Host ""

if ($DryRun) {
    Write-Host "${Cyan}This was a dry run. No changes were made.${Reset}"
} else {
    Write-Success "Update complete!"
}

Write-Host ""
