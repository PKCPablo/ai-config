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
        Write-Fail "Missing required path: $req"
        $validConfig = $false
    }
}

if (-not $validConfig) {
    Write-Fail "Invalid ai-config repository structure"
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
                    # Verify it's really a symlink before removing
                    $item = Get-Item $targetPath
                    $isReparsePoint = $item.Attributes -band [System.IO.FileAttributes]::ReparsePoint
                    
                    if (-not $isReparsePoint) {
                        Write-Fail "Cannot refresh: $($link.Target) exists but is NOT a symlink"
                        Write-Info "It's a regular file/directory. Manual intervention required."
                        $results.Conflicts += $link.Target
                        continue
                    }
                    
                    try {
                        Remove-Item $targetPath -Force -Confirm:$false -Recurse -ErrorAction SilentlyContinue
                        if ($link.Type -eq "Directory") {
                            New-Item -ItemType SymbolicLink -Path $targetPath -Target $sourcePath -Force | Out-Null
                        } else {
                            New-Item -ItemType SymbolicLink -Path $targetPath -Target $sourcePath -Force | Out-Null
                        }
                        Write-Success "Refreshed symlink: $($link.Target) -> $($link.Source)"
                        $results.Refreshed += $link.Target
                    }
                    catch {
                        Write-Fail "Failed to refresh symlink: $($link.Target)"
                        Write-Info "Error: $($_.Exception.Message)"
                        Write-Host ""
                        Write-Info "Options:"
                        Write-Info "  [R]etry - Try again"
                        Write-Info "  [S]kip - Skip this file and continue"
                        Write-Info "  [A]bort - Stop installation"
                        Write-Host ""
                        $choice = Read-Host "Choose an option (R/S/A)"
                        switch ($choice.ToUpper()) {
                            "R" { 
                                # Will retry on next iteration if we rethrow or handle differently
                                # For now, treat as error
                                $results.Errors += $link.Target
                            }
                            "S" {
                                Write-Info "Skipping $($link.Target)"
                                $results.Skipped += $link.Target
                            }
                            default {
                                Write-Fail "Installation aborted by user"
                                exit 1
                            }
                        }
                    }
                }
            } else {
                # Skip existing symlink
                Write-Warn "Skipped existing symlink (use --force to refresh): $($link.Target)"
                $results.Skipped += $link.Target
            }
        } else {
            # It's a real file/directory - CONFLICT (never touch these)
            Write-Fail "CONFLICT - File exists: $($link.Target)"
            Write-Info "  Remove or rename the existing file manually, then re-run"
            $results.Conflicts += $link.Target
        }
    } else {
        # Nothing exists, safe to create
        if ($DryRun) {
            Write-DryRun "Would create symlink: $($link.Target) -> $($link.Source)"
            $results.Created += $link.Target
        } else {
            $symlinkCreated = $false
            $retryCount = 0
            $maxRetries = 3
            
            while (-not $symlinkCreated -and $retryCount -lt $maxRetries) {
                try {
                    if ($link.Type -eq "Directory") {
                        New-Item -ItemType SymbolicLink -Path $targetPath -Target $sourcePath -Force | Out-Null
                    } else {
                        New-Item -ItemType SymbolicLink -Path $targetPath -Target $sourcePath -Force | Out-Null
                    }
                    Write-Success "Created symlink: $($link.Target) -> $($link.Source)"
                    $results.Created += $link.Target
                    $symlinkCreated = $true
                }
                catch {
                    $retryCount++
                    if ($retryCount -eq $maxRetries) {
                        Write-Fail "Failed to create symlink: $($link.Target)"
                        Write-Info "Error: $($_.Exception.Message)"
                        Write-Host ""
                        
                        # Check if it's a permission issue
                        if ($_.Exception.Message -match "access|permission|denied|administrator") {
                            Write-Fail "Administrator privileges may be required to create symlinks"
                            Write-Info "Please run PowerShell as Administrator and try again"
                        }
                        
                        Write-Info "Options:"
                        Write-Info "  [R]etry - Try again ($retryCount/$maxRetries attempts)"
                        Write-Info "  [S]kip - Skip this file and continue"
                        Write-Info "  [A]bort - Stop installation"
                        Write-Host ""
                        $choice = Read-Host "Choose an option (R/S/A)"
                        switch ($choice.ToUpper()) {
                            "R" { 
                                $retryCount = 0  # Reset counter for another round
                                Write-Info "Retrying..."
                            }
                            "S" {
                                Write-Info "Skipping $($link.Target)"
                                $results.Errors += $link.Target
                                $symlinkCreated = $true  # Exit loop but mark as error
                            }
                            default {
                                Write-Fail "Installation aborted by user"
                                exit 1
                            }
                        }
                    } else {
                        Write-Warn "Attempt $retryCount failed, retrying..."
                        Start-Sleep -Milliseconds 500
                    }
                }
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
    Write-Warn "Skipped: $($results.Skipped.Count) existing symlinks"
}
if ($results.Conflicts.Count -gt 0) {
    Write-Fail "Conflicts: $($results.Conflicts.Count) files exist (not modified)"
}
if ($results.Errors.Count -gt 0) {
    Write-Fail "Errors: $($results.Errors.Count) failed"
}

Write-Host ""

if ($DryRun) {
    Write-Host "${Cyan}This was a dry run. No changes were made.${Reset}"
    Write-Host "Run without --dry-run to apply changes."
} elseif ($results.Conflicts.Count -eq 0 -and $results.Errors.Count -eq 0) {
    Write-Success "Installation complete!"
    Write-Host "Your project is now linked to ai-config."
    
    # Install node_modules for OpenCode/Bun compatibility
    Write-Host ""
    Write-Info "Installing OpenCode dependencies..."
    
    $packageJsonSource = Join-Path $AiConfigPath ".opencode\package.json"
    $packageJsonTarget = Join-Path $Repo ".opencode\package.json"
    
    if (Test-Path $packageJsonSource) {
        if (-not $DryRun) {
            try {
                # Copy package.json to target project
                Copy-Item -Path $packageJsonSource -Destination $packageJsonTarget -Force
                Write-Success "Copied package.json to .opencode/"
                
                # Copy .gitignore to target project
                $gitignoreSource = Join-Path $AiConfigPath ".opencode\.gitignore"
                $gitignoreTarget = Join-Path $Repo ".opencode\.gitignore"
                if (Test-Path $gitignoreSource) {
                    Copy-Item -Path $gitignoreSource -Destination $gitignoreTarget -Force
                    Write-Success "Copied .gitignore to .opencode/"
                }
                
                # Install dependencies with bun
                $originalLocation = Get-Location
                Set-Location -Path (Join-Path $Repo ".opencode")
                
                $bunInstalled = Get-Command bun -ErrorAction SilentlyContinue
                if ($bunInstalled) {
                    $bunOutput = bun install 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        Write-Success "Installed dependencies with bun"
                    } else {
                        Write-Warn "bun install had warnings (this is usually OK)"
                    }
                } else {
                    Write-Warn "bun not found in PATH. Please install bun and run 'bun install' in .opencode/"
                }
                
                Set-Location -Path $originalLocation
            }
            catch {
                Write-Warn "Could not install dependencies: $($_.Exception.Message)"
                Write-Info "To manually install, run: cd '$Repo\.opencode' && bun install"
            }
        } else {
            Write-DryRun "Would copy package.json and run bun install in .opencode/"
        }
    } else {
        Write-Warn "package.json not found in ai-config/.opencode/"
    }
    
    # Register project in installed-projects.md
    $projectsFile = Join-Path $AiConfigPath "installed-projects.md"
    $projectName = Split-Path -Leaf $Repo
    
    try {
        # Create file if it doesn't exist
        if (-not (Test-Path $projectsFile)) {
            $headerContent = @"
# Proyectos con ai-config instalado

| Proyecto | Ruta |
|----------|------|
"@
            $headerContent | Out-File -FilePath $projectsFile -Encoding utf8
        }
        
        # Check if already registered
        $content = Get-Content $projectsFile -Raw
        if ($content -notmatch [regex]::Escape($Repo)) {
            # Add new entry
            $newLine = "| $projectName | $Repo |"
            Add-Content -Path $projectsFile -Value $newLine
            Write-Info "Registered in installed-projects.md"
        }
    }
    catch {
        Write-Warn "Could not update installed-projects.md (permission denied)"
        Write-Info "To manually register, add this line to installed-projects.md:"
        Write-Host "    | $projectName | $Repo |"
        Write-Host ""
        Write-Info "Or run PowerShell as Administrator and retry."
    }
} else {
    Write-Warn "Installation completed with issues."
    Write-Host "Review the conflicts above and re-run after resolving them."
}

Write-Host ""
