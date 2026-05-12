#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Updates ai-config and refreshes all linked projects.

.DESCRIPTION
    This script performs a git pull on ai-config repository and then
    refreshes the symlinks in all registered projects.

.PARAMETER DryRun
    Show what would be done without making any changes.

.EXAMPLE
    .\update.ps1 --dry-run

.EXAMPLE
    .\update.ps1
#>

[CmdletBinding()]
param(
    [Parameter()]
    [switch]$DryRun
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

# Determine ai-config path
$AiConfigPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$AiConfigPath = Resolve-Path $AiConfigPath | Select-Object -ExpandProperty Path

Write-Host ""
Write-Host "=== AI-Config Updater ==="
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
    Write-Error "No installed-projects.md found."
    Write-Info "Run install.ps1 first to register projects."
    exit 1
}

# Step 1: Git pull
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
        Write-Error "Git pull failed: $gitOutput"
        exit 1
    }
}

Write-Host ""

# Step 2: Parse installed-projects.md
Write-Host "Step 2: Loading registered projects..."
Write-Host ""

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

Write-Info "Found $($projects.Count) registered project(s)"
Write-Host ""

# Step 3: Update each project
Write-Host "Step 3: Updating projects..."
Write-Host ""

$results = @{
    Updated = @()
    NotFound = @()
    Skipped = @()
    Failed = @()
}

foreach ($project in $projects) {
    Write-Host "Processing: $($project.Name)"
    Write-Host "  Path: $($project.Path)"
    
    if (-not (Test-Path $project.Path)) {
        Write-Warning "  Project not found at: $($project.Path)"
        
        # Ask user what to do
        if (-not $DryRun) {
            Write-Host ""
            Write-Host "  What would you like to do?"
            Write-Host "  [E]liminar de la lista"
            Write-Host "  [D]etener script"
            Write-Host "  [S]altar (mantener en lista)"
            Write-Host ""
            
            $choice = Read-Host "  Elige una opción (E/D/S)"
            
            switch ($choice.ToUpper()) {
                "E" {
                    # Remove from list - we'll rebuild the file
                    $results.NotFound += $project
                    Write-Info "  Will be removed from list"
                }
                "D" {
                    Write-Error "  Script detenido por el usuario"
                    exit 1
                }
                default {
                    # Skip
                    $results.Skipped += $project
                    Write-Info "  Skipped"
                }
            }
        } else {
            $results.Skipped += $project
            Write-DryRun "  Would ask user (project not found)"
        }
    } else {
        # Project exists, update it
        if ($DryRun) {
            Write-DryRun "  Would refresh symlinks"
            $results.Updated += $project
        } else {
            # Call install.ps1 with --force
            $installScript = Join-Path $AiConfigPath "install.ps1"
            $output = & $installScript --repo $project.Path --force 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Success "  Updated successfully"
                $results.Updated += $project
            } else {
                Write-Error "  Update failed"
                $results.Failed += $project
            }
        }
    }
    
    Write-Host ""
}

# Step 4: Rebuild installed-projects.md if needed (remove deleted projects)
if ($results.NotFound.Count -gt 0 -and -not $DryRun) {
    Write-Host "Step 4: Cleaning up projects list..."
    Write-Host ""
    
    $newContent = @"# Proyectos con ai-config instalado

| Proyecto | Ruta |
|----------|------|
"@
    
    foreach ($project in $projects) {
        $shouldKeep = $true
        foreach ($notFound in $results.NotFound) {
            if ($project.Path -eq $notFound.Path) {
                $shouldKeep = $false
                break
            }
        }
        if ($shouldKeep) {
            $newContent += "`n| $($project.Name) | $($project.Path) |"
        }
    }
    
    $newContent | Out-File -FilePath $projectsFile -Encoding utf8
    Write-Success "Removed $($results.NotFound.Count) project(s) from list"
    Write-Host ""
}

# Summary
Write-Host "=== Update Summary ==="
Write-Host ""

if ($results.Updated.Count -gt 0) {
    Write-Success "Updated: $($results.Updated.Count) project(s)"
}
if ($results.NotFound.Count -gt 0) {
    Write-Warning "Removed from list: $($results.NotFound.Count) project(s)"
}
if ($results.Skipped.Count -gt 0) {
    Write-Warning "Skipped: $($results.Skipped.Count) project(s)"
}
if ($results.Failed.Count -gt 0) {
    Write-Error "Failed: $($results.Failed.Count) project(s)"
}

Write-Host ""

if ($DryRun) {
    Write-Host "${Cyan}This was a dry run. No changes were made.${Reset}"
} else {
    Write-Success "Update complete!"
}

Write-Host ""
