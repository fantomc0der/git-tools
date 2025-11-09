# Git Three-Way Diff Alias Installer
# This script installs the git threewaydiff alias for comparing changes between branches

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Git Three-Way Diff Alias Installer" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Check if Meld is installed
Write-Host "Checking for Meld dependency..." -ForegroundColor Yellow
$meldCommand = Get-Command meld -ErrorAction SilentlyContinue

if (-not $meldCommand) {
    Write-Host ""
    Write-Host "ERROR: Meld is not installed or not in PATH" -ForegroundColor Red
    Write-Host ""
    Write-Host "Meld is required for this git alias to work. Please install it first:" -ForegroundColor Yellow
    Write-Host "  Using Chocolatey: choco install meld" -ForegroundColor White
    Write-Host "  Or download from:  https://meldmerge.org/" -ForegroundColor White
    Write-Host ""
    Write-Host "Installation aborted." -ForegroundColor Red
    exit 1
}

Write-Host "✓ Meld found at: $($meldCommand.Source)" -ForegroundColor Green

# Define source and destination paths
$sourceScript = Join-Path $PSScriptRoot "threewaydiff.ps1"
$userProfile = $env:USERPROFILE
$destinationScript = Join-Path $userProfile "git-threewaydiff-alias.ps1"

# Check if source script exists
if (-not (Test-Path $sourceScript)) {
    Write-Host ""
    Write-Host "ERROR: Could not find threewaydiff.ps1 in the current directory" -ForegroundColor Red
    Write-Host "Expected path: $sourceScript" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Make sure you're running this script from the same directory as threewaydiff.ps1" -ForegroundColor Yellow
    Write-Host "Installation aborted." -ForegroundColor Red
    exit 1
}

# Check if destination file already exists
if (Test-Path $destinationScript) {
    Write-Host ""
    Write-Host "Warning: git-threewaydiff-alias.ps1 already exists in your user profile:" -ForegroundColor Yellow
    Write-Host "  $destinationScript" -ForegroundColor White
    Write-Host ""
    
    do {
        $response = Read-Host "Do you want to overwrite it? (y/N)"
        $response = $response.Trim().ToLower()
        
        if ($response -eq "" -or $response -eq "n" -or $response -eq "no") {
            Write-Host ""
            Write-Host "Installation cancelled by user." -ForegroundColor Yellow
            exit 0
        }
    } while ($response -ne "y" -and $response -ne "yes")
    Write-Host ""
}

# Copy the script to user profile
Write-Host "Copying threewaydiff.ps1 to user profile..." -ForegroundColor Yellow

try {
    Copy-Item $sourceScript $destinationScript -Force
    Write-Host "✓ Script copied successfully to: $destinationScript" -ForegroundColor Green
} catch {
    Write-Host ""
    Write-Host "ERROR: Failed to copy script to user profile" -ForegroundColor Red
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Installation aborted." -ForegroundColor Red
    exit 1
}

# Generate the git alias command with dynamic path
$gitAliasPath = $destinationScript -replace '\\', '/'  # Convert to forward slashes for git
$aliasValue = "!powershell -NoProfile -File `"$gitAliasPath`""

# Register the git alias
Write-Host "Registering git alias..." -ForegroundColor Yellow

try {
    & git config --global alias.threewaydiff $aliasValue
    Write-Host "✓ Git alias registered successfully" -ForegroundColor Green
} catch {
    Write-Host ""
    Write-Host "ERROR: Failed to register git alias" -ForegroundColor Red
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "You can manually register the alias with this command:" -ForegroundColor Yellow
    Write-Host "  git config --global alias.threewaydiff '$aliasValue'" -ForegroundColor White
    Write-Host ""
    Write-Host "Installation completed with warnings." -ForegroundColor Yellow
    exit 1
}

# Installation complete
Write-Host ""
Write-Host "Installation completed successfully!" -ForegroundColor Cyan