#!/usr/bin/env bash
# Compare files between two branches and their common base.
# Supports both changed-files mode and full branch state comparison.
#
# Usage: git twdiff <branch1> <branch2> [--changed-files]

set -u

BranchLeft=""
BranchRight=""
ChangedFilesOnly=0

# Parse positional args and flags in any order
for arg in "$@"; do
    case "$arg" in
        --changed-files)
            ChangedFilesOnly=1
            ;;
        *)
            if [ -z "$BranchLeft" ]; then
                BranchLeft="$arg"
            elif [ -z "$BranchRight" ]; then
                BranchRight="$arg"
            fi
            ;;
    esac
done

if [ -z "$BranchLeft" ] || [ -z "$BranchRight" ]; then
    echo "Usage: git twdiff <branch1> <branch2> [--changed-files]"
    echo ""
    echo "  Default:         Shows complete branch state using git worktrees"
    echo "  --changed-files: Shows only changed files between branches"
    exit 1
fi

# Translate a path for Meld. On Git Bash / Cygwin / MSYS, Meld is usually a
# native Windows app, so POSIX paths need conversion. Elsewhere pass through.
to_tool_path() {
    if command -v cygpath >/dev/null 2>&1; then
        cygpath -w "$1"
    else
        printf '%s' "$1"
    fi
}

# Launch Meld and block until the user closes the window.
#
# There are two Windows-specific landmines this function handles:
#
# 1. `meld.exe` is a thin launcher that spawns the real GUI process (usually
#    Python) and exits almost immediately. If we call it directly from bash,
#    the shell sees the launcher exit, runs the EXIT trap, and deletes the
#    temp files/worktrees *before* the Meld window has even fully opened.
#    Solution: defer to PowerShell's `Start-Process -Wait`, which waits on
#    the full process tree (same mechanism the old .ps1 version used).
#
# 2. Meld ships its own GLib stack (libgmodule-2.0-0.dll, libglib-2.0-0.dll,
#    gdbus.exe, etc.) in its install directory. When we invoke PowerShell
#    *from Git Bash*, PowerShell inherits Git Bash's PATH, which typically
#    contains `C:\Program Files\Git\mingw64\bin` — and Git for Windows ships
#    its own copies of those same GLib DLLs there. Even with Meld's dir
#    prepended, Windows may end up mixing DLLs from the two stacks (e.g.
#    Meld's libgmodule + Git's libglib), leading to version-skew crashes
#    like "Entry Point Not Found: DllMain" from gdbus.exe. The old .ps1
#    version didn't hit this because it ran from a plain PowerShell prompt
#    with a cleaner PATH. Solution: inside the PowerShell child, reset PATH
#    to contain ONLY Meld's own install directory and essential Windows
#    system dirs — no Git, no mingw, no other GTK/GLib installs — so every
#    DLL in the load chain comes from Meld's bundle.
#
# Elsewhere (Linux, macOS) a plain foreground invocation already blocks
# correctly and there's no DLL-search issue, so we fall through to that.
launch_meld_blocking() {
    if ! command -v powershell >/dev/null 2>&1; then
        meld "$1" "$2" "$3"
        return
    fi

    # Write the PowerShell launcher to a temp file and invoke it with
    # `powershell -File`. This avoids the quoting/escaping nightmare of
    # passing a multiline script with regex backslashes through bash
    # double-quotes into `powershell -Command`.
    local ps_script
    ps_script="$(mktemp -t twdiff-meld.XXXXXX)"
    ps_script_ps1="${ps_script}.ps1"
    mv "$ps_script" "$ps_script_ps1"

    cat >"$ps_script_ps1" <<'PSEOF'
param(
    [Parameter(Mandatory=$true)][string]$Left,
    [Parameter(Mandatory=$true)][string]$Base,
    [Parameter(Mandatory=$true)][string]$Right
)

# Resolve meld's install directory BEFORE touching PATH, so we don't
# accidentally hide it from ourselves.
$meld = (Get-Command meld -ErrorAction SilentlyContinue).Source
if (-not $meld) {
    foreach ($p in @('C:\Program Files\Meld\Meld.exe',
                     'C:\Program Files (x86)\Meld\Meld.exe')) {
        if (Test-Path $p) { $meld = $p; break }
    }
}

# Strip Git for Windows' mingw/usr/cmd bin directories from PATH. These
# ship their own copies of libglib/libgmodule/libintl/etc., which collide
# with Meld's bundled GLib stack and cause gdbus.exe to fail with
# "Entry Point Not Found: DllMain". Leave every other PATH entry alone —
# Meld's Python launcher needs them to find its own bootstrap deps.
$filtered = $env:PATH -split ';' | Where-Object {
    $_ -and $_ -notmatch '\\Git\\(mingw\d*|usr|cmd)(\\|$)'
}

# Prepend Meld's own directory so its bundled DLLs win the Windows
# loader search for anything loaded by name.
if ($meld) {
    $filtered = ,(Split-Path $meld) + $filtered
}
$env:PATH = $filtered -join ';'

$target = if ($meld) { $meld } else { 'meld' }
Start-Process -FilePath $target -ArgumentList @($Left, $Base, $Right) -Wait
PSEOF

    powershell -NoProfile -ExecutionPolicy Bypass \
        -File "$(to_tool_path "$ps_script_ps1")" \
        -Left  "$1" \
        -Base  "$2" \
        -Right "$3"
    local rc=$?
    rm -f "$ps_script_ps1" 2>/dev/null || true
    return $rc
}

# Find merge base
BASE="$(git merge-base "$BranchLeft" "$BranchRight" 2>/dev/null || true)"
if [ -z "$BASE" ]; then
    echo "Error: Could not find merge base between $BranchLeft and $BranchRight"
    exit 1
fi

if [ "$ChangedFilesOnly" -eq 0 ]; then
    # Full branch state comparison using git worktrees
    echo "Using full branch state comparison with git worktrees..."

    WorktreeRoot="$(mktemp -d -t git-worktree-twdiff.XXXXXX)"
    BaseWorktree="$WorktreeRoot/base"
    LeftWorktree="$WorktreeRoot/left"
    RightWorktree="$WorktreeRoot/right"

    cleanup_worktrees() {
        # Always attempt removal — don't gate on `git worktree list` matching,
        # because on Git Bash the registered path may be the Windows form
        # (C:/Users/.../Temp/...) while $wt is the POSIX form (/tmp/...), which
        # would cause a string-match gate to skip removal and leave orphaned
        # registrations after the subsequent rm -rf.
        for wt in "$BaseWorktree" "$LeftWorktree" "$RightWorktree"; do
            [ -n "${wt:-}" ] || continue
            git worktree remove --force "$wt" >/dev/null 2>&1 || true
        done
        if [ -d "$WorktreeRoot" ]; then
            rm -rf "$WorktreeRoot" 2>/dev/null || true
        fi
        # Safety net: prune any registration whose folder is gone (e.g. if
        # `git worktree remove` failed because Meld still held file handles).
        git worktree prune >/dev/null 2>&1 || true
    }
    trap 'echo "Cleaning up worktrees..."; cleanup_worktrees' EXIT INT TERM

    # Prune stale registrations first
    git worktree prune 2>/dev/null || true

    # Verify commits exist
    for commit in "$BASE" "$BranchLeft" "$BranchRight"; do
        if ! git rev-parse --verify "$commit" >/dev/null 2>&1; then
            echo "Error: Invalid commit reference: $commit"
            exit 1
        fi
    done

    create_worktree() {
        local path="$1" commit="$2" label="$3"
        echo "Creating worktree for $label ($commit)..."
        if ! git worktree add --force "$path" "$commit" >/dev/null; then
            echo "Error: Failed to create worktree for $label"
            exit 1
        fi
    }

    create_worktree "$BaseWorktree"  "$BASE"        "merge base"
    create_worktree "$LeftWorktree"  "$BranchLeft"  "$BranchLeft"
    create_worktree "$RightWorktree" "$BranchRight" "$BranchRight"

    echo "Launching Meld with full branch states..."
    launch_meld_blocking \
        "$(to_tool_path "$LeftWorktree")" \
        "$(to_tool_path "$BaseWorktree")" \
        "$(to_tool_path "$RightWorktree")"

else
    # Changed-files only mode
    echo "Using changed files comparison mode..."

    ChangedFiles="$(git diff --name-only "$BranchLeft" "$BranchRight")"
    if [ -z "$ChangedFiles" ]; then
        echo "No changed files between $BranchLeft and $BranchRight"
        exit 0
    fi

    TempRoot="$(mktemp -d -t git-alias-twdiff.XXXXXX)"
    BaseDir="$TempRoot/base"
    LocalDir="$TempRoot/local"
    RemoteDir="$TempRoot/remote"
    mkdir -p "$BaseDir" "$LocalDir" "$RemoteDir"

    cleanup_tmp() {
        echo "Cleaning up temporary files..."
        if [ -d "$TempRoot" ]; then
            rm -rf "$TempRoot" 2>/dev/null || true
        fi
    }
    trap cleanup_tmp EXIT INT TERM

    # Extract each changed file at the three revisions
    while IFS= read -r file; do
        [ -z "$file" ] && continue
        mkdir -p "$(dirname "$BaseDir/$file")" \
                 "$(dirname "$LocalDir/$file")" \
                 "$(dirname "$RemoteDir/$file")"
        git show "${BASE}:$file"        >"$BaseDir/$file"   2>/dev/null || true
        git show "${BranchLeft}:$file"  >"$LocalDir/$file"  2>/dev/null || true
        git show "${BranchRight}:$file" >"$RemoteDir/$file" 2>/dev/null || true
    done <<EOF
$ChangedFiles
EOF

    launch_meld_blocking \
        "$(to_tool_path "$LocalDir")" \
        "$(to_tool_path "$BaseDir")" \
        "$(to_tool_path "$RemoteDir")"
fi
