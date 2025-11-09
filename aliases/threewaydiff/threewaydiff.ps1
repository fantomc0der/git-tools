# Compare only changed files between two branches and their common base

param(
    [string]$BranchLeft,
    [string]$BranchRight
)

# Validate arguments
if (-not $BranchLeft -or -not $BranchRight) {
    Write-Host "Usage: Must provide arguments for left and right branch names"
    exit 1
}

# Find merge base
$BASE = git merge-base $BranchLeft $BranchRight
if (-not $BASE) {
    Write-Host "Error: Could not find merge base between $BranchLeft and $BranchRight"
    exit 1
}

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
$meldExe = "meld" # Only supports meld for now
Start-Process $meldExe -ArgumentList @("$LocalDir", "$BaseDir", "$RemoteDir") -NoNewWindow -Wait

# Cleanup temp files after Meld closes
Remove-Item -Recurse -Force $TempRoot
