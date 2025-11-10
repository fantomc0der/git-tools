# Compare files between two branches and their common base
# Supports both changed-files mode and full branch state comparison

param(
    [string]$BranchLeft,
    [string]$BranchRight
)

# Check for --changed-files flag in remaining arguments
$ChangedFilesOnly = $args -contains "--changed-files"

# Validate arguments
if (-not $BranchLeft -or -not $BranchRight) {
    Write-Host "Usage: git threewaydiff <branch1> <branch2> [--changed-files]"
    Write-Host ""
    Write-Host "  Default: Shows complete branch state using git worktrees"
    Write-Host "  --changed-files: Shows only changed files between branches"
    exit 1
}

# Find merge base
$BASE = git merge-base $BranchLeft $BranchRight
if (-not $BASE) {
    Write-Host "Error: Could not find merge base between $BranchLeft and $BranchRight"
    exit 1
}

if (-not $ChangedFilesOnly) {
    # Full branch state comparison using git worktrees
    Write-Host "Using full branch state comparison with git worktrees..."
    
    # Prepare worktree directories
    $WorktreeRoot = Join-Path $env:TEMP "git-worktree-threewaydiff"
    $BaseWorktree = Join-Path $WorktreeRoot "base"
    $LeftWorktree = Join-Path $WorktreeRoot "left"
    $RightWorktree = Join-Path $WorktreeRoot "right"

    # Cleanup function for worktrees
    function CleanupWorktrees {
        param($Root, $Base, $Left, $Right)
        
        # Remove worktrees gracefully (ignore errors if already gone)
        @($Base, $Left, $Right) | ForEach-Object {
            if ($_ -and (git worktree list | Select-String -SimpleMatch $_)) {
                try {
                    git worktree remove $_ --force
                } catch {
                    # Ignore cleanup errors
                }
            }
        }
        
        # Final cleanup of temp directory
        if (Test-Path $Root) {
            Remove-Item -Recurse -Force $Root -ErrorAction SilentlyContinue
        }
    }

    # Helper function to create worktree with error handling
    function CreateWorktree {
        param($Path, $Commit, $BranchName)
        
        Write-Host "Creating worktree for $BranchName ($Commit)..."
        git worktree add --force $Path $Commit
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Error: Failed to create worktree for $BranchName"
            exit 1
        }
    }

    # Cleanup any existing worktrees and prune stale registrations
    CleanupWorktrees $WorktreeRoot $BaseWorktree $LeftWorktree $RightWorktree
    git worktree prune
    
    # Create root directory
    New-Item -ItemType Directory -Path $WorktreeRoot -Force | Out-Null

    try {
        # Verify commits exist before creating worktrees
        foreach ($commit in @($BASE, $BranchLeft, $BranchRight)) {
            try {
                $null = git rev-parse --verify $commit
                if ($LASTEXITCODE -ne 0) {
                    Write-Host "Error: Invalid commit reference: $commit"
                    exit 1
                }
            } catch {
                Write-Host "Error: Invalid commit reference: $commit"
                exit 1
            }
        }

        # Create worktrees
        CreateWorktree $BaseWorktree $BASE "merge base"
        CreateWorktree $LeftWorktree $BranchLeft $BranchLeft
        CreateWorktree $RightWorktree $BranchRight $BranchRight

        Write-Host "Launching Meld with full branch states..."
        
        # Launch Meld with worktrees
        $meldExe = "meld"
        Start-Process $meldExe -ArgumentList @($LeftWorktree, $BaseWorktree, $RightWorktree) -NoNewWindow -Wait

    } finally {
        # Always cleanup worktrees
        Write-Host "Cleaning up worktrees..."
        CleanupWorktrees $WorktreeRoot $BaseWorktree $LeftWorktree $RightWorktree
    }

} else {
    # Changed-files only mode (when --changed-files flag is used)
    Write-Host "Using changed files comparison mode..."
    
    # Get changed files
    $ChangedFiles = git diff --name-only $BranchLeft $BranchRight
    if (-not $ChangedFiles) {
        Write-Host "No changed files between $BranchLeft and $BranchRight"
        exit 0
    }

    # Prepare temp directories
    $TempRoot = Join-Path $env:TEMP "git-alias-threewaydiff"
    $BaseDir = Join-Path $TempRoot "base"
    $LocalDir = Join-Path $TempRoot "local"
    $RemoteDir = Join-Path $TempRoot "remote"

    if (Test-Path $TempRoot) { Remove-Item -Recurse -Force $TempRoot }
    New-Item -ItemType Directory -Force -Path $BaseDir, $LocalDir, $RemoteDir | Out-Null

    try {
        # Extract only changed files
        foreach ($file in $ChangedFiles) {
            $basePath = Join-Path $BaseDir $file
            $localPath = Join-Path $LocalDir $file
            $remotePath = Join-Path $RemoteDir $file

            New-Item -ItemType Directory -Force -Path (Split-Path $basePath), (Split-Path $localPath), (Split-Path $remotePath) | Out-Null

            try { git show "${BASE}:$file" | Out-File -Encoding utf8 $basePath } catch {}
            try { git show "${BranchLeft}:$file" | Out-File -Encoding utf8 $localPath } catch {}
            try { git show "${BranchRight}:$file" | Out-File -Encoding utf8 $remotePath } catch {}
        }

        # Launch Meld with proper flags
        $meldExe = "meld"
        Start-Process $meldExe -ArgumentList @("$LocalDir", "$BaseDir", "$RemoteDir") -NoNewWindow -Wait

    } finally {
        # Always cleanup temp files
        Write-Host "Cleaning up temporary files..."
        if (Test-Path $TempRoot) {
            Remove-Item -Recurse -Force $TempRoot -ErrorAction SilentlyContinue
        }
    }
}
