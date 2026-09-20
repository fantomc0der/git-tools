#Requires -Version 5.1
<#
.SYNOPSIS
    Installs (or updates) the enhance-git helpers in your PowerShell profile.

.DESCRIPTION
    Copies the contents of enhance-git.ps1 into your PowerShell profile, wrapped in a
    marked block:

        ####### BEGIN git-tools:enhance-git #######
        ...
        ####### END git-tools:enhance-git #######

    Re-running the installer replaces everything between those markers, so updates to
    enhance-git.ps1 can be applied without touching the rest of your profile.

.PARAMETER ProfilePath
    Profile to modify. Defaults to $PROFILE (current user, current host).

.PARAMETER Uninstall
    Remove the managed block instead of installing it.

.PARAMETER NoBackup
    Skip the timestamped backup copy of the profile.

.EXAMPLE
    .\install.ps1

.EXAMPLE
    .\install.ps1 -ProfilePath $PROFILE.CurrentUserAllHosts

.EXAMPLE
    .\install.ps1 -Uninstall
#>
[CmdletBinding()]
param(
    [string]$ProfilePath = $PROFILE,
    [switch]$Uninstall,
    [switch]$NoBackup
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$BeginMarker = '####### BEGIN git-tools:enhance-git #######'
$EndMarker   = '####### END git-tools:enhance-git #######'

function Write-Step { param([string]$Message) Write-Host $Message -ForegroundColor Yellow }
function Write-Ok   { param([string]$Message) Write-Host "[OK] $Message" -ForegroundColor Green }
function Write-Info { param([string]$Message) Write-Host $Message -ForegroundColor Cyan }

Write-Info '====================================='
Write-Info 'enhance-git Profile Installer'
Write-Info '====================================='
Write-Host ''

if ([string]::IsNullOrWhiteSpace($ProfilePath)) {
    throw 'No profile path available. Pass -ProfilePath explicitly.'
}

$sourcePath = Join-Path $PSScriptRoot 'enhance-git.ps1'
if (-not $Uninstall -and -not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
    throw "Could not find enhance-git.ps1 next to this installer. Expected path: $sourcePath"
}

Write-Step "Profile: $ProfilePath"

$profileExists = Test-Path -LiteralPath $ProfilePath -PathType Leaf
$lines = @()
if ($profileExists) { $lines = @(Get-Content -LiteralPath $ProfilePath) }

# Locate an existing managed block, if any
$beginIndex = -1
$endIndex = -1
for ($i = 0; $i -lt $lines.Count; $i++) {
    $trimmed = $lines[$i].Trim()
    if ($beginIndex -lt 0) {
        if ($trimmed -eq $BeginMarker) { $beginIndex = $i }
    }
    elseif ($trimmed -eq $EndMarker) {
        $endIndex = $i
        break
    }
}

if ($beginIndex -ge 0 -and $endIndex -lt 0) {
    throw "Found the BEGIN marker at line $($beginIndex + 1) but no matching END marker in $ProfilePath. Fix the profile by hand, then re-run."
}

$before = @()
$after = @()
if ($beginIndex -ge 0) {
    if ($beginIndex -gt 0) { $before = @($lines[0..($beginIndex - 1)]) }
    if ($endIndex -lt ($lines.Count - 1)) { $after = @($lines[($endIndex + 1)..($lines.Count - 1)]) }
}
else {
    $before = $lines
}

# Drop trailing blank lines so repeated installs do not accumulate empty lines
while ($before.Count -gt 0 -and [string]::IsNullOrWhiteSpace($before[-1])) {
    if ($before.Count -eq 1) { $before = @() }
    else { $before = @($before[0..($before.Count - 2)]) }
}

if ($Uninstall) {
    if ($beginIndex -lt 0) {
        Write-Host ''
        Write-Ok 'Nothing to do: no enhance-git block found in the profile.'
        return
    }
    $newLines = @($before) + @($after)
}
else {
    $block = @(
        $BeginMarker
        '# Managed by git-tools scripts/enhance-git/install.ps1. Edits inside this block are'
        '# overwritten on the next install; change enhance-git.ps1 in the repo instead.'
        ''
    ) + @(Get-Content -LiteralPath $sourcePath) + @(
        $EndMarker
    )

    $newLines = @($before)
    if ($newLines.Count -gt 0) { $newLines += '' }
    $newLines += $block
    if ($after.Count -gt 0) { $newLines += @($after) }
}

if ($profileExists -and -not $NoBackup) {
    $backupPath = "$ProfilePath.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item -LiteralPath $ProfilePath -Destination $backupPath
    Write-Ok "Backed up existing profile to: $backupPath"
}

$profileDir = Split-Path -Parent $ProfilePath
if ($profileDir -and -not (Test-Path -LiteralPath $profileDir -PathType Container)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    Write-Ok "Created profile directory: $profileDir"
}

Set-Content -LiteralPath $ProfilePath -Value $newLines -Encoding UTF8

Write-Host ''
if ($Uninstall) {
    Write-Ok 'Removed the enhance-git block from your profile.'
}
elseif ($beginIndex -ge 0) {
    Write-Ok 'Updated the existing enhance-git block in your profile.'
}
else {
    Write-Ok 'Added the enhance-git block to your profile.'
}

Write-Host ''
Write-Info 'Reload your profile to apply the change:'
Write-Host "  . `$PROFILE"
Write-Host '(or just open a new PowerShell window)'
