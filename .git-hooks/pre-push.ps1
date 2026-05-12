#!/usr/bin/env pwsh
#
# Pre-push hook to prevent direct pushes to main/master
# Install: copy to .git/hooks/pre-push in your repository
#

$protectedBranches = @("main", "master")

# Read stdin for ref information
$inputLines = @($input)

foreach ($line in $inputLines) {
    $parts = $line -split "\s+"
    if ($parts.Length -ge 4) {
        $localRef = $parts[0]
        $localSha = $parts[1]
        $remoteRef = $parts[2]
        $remoteSha = $parts[3]
        
        foreach ($branch in $protectedBranches) {
            if ($remoteRef -eq "refs/heads/$branch") {
                Write-Host "❌ ERROR: Direct push to '$branch' branch is not allowed!" -ForegroundColor Red
                Write-Host ""
                Write-Host "Please create a pull request instead:"
                Write-Host "  1. Create a new branch: git checkout -b feature/my-change"
                Write-Host "  2. Make your changes and commit"
                Write-Host "  3. Push the branch: git push origin feature/my-change"
                Write-Host "  4. Create a pull request on GitHub"
                Write-Host ""
                exit 1
            }
        }
    }
}

exit 0
