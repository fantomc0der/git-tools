#!/usr/bin/env bash
# Git Three-Way Diff Alias Installer
# Installs the `git twdiff` alias for comparing changes between branches.

set -u

cyan()   { printf '\033[36m%s\033[0m\n' "$*"; }
yellow() { printf '\033[33m%s\033[0m\n' "$*"; }
red()    { printf '\033[31m%s\033[0m\n' "$*"; }
green()  { printf '\033[32m%s\033[0m\n' "$*"; }

cyan "====================================="
cyan "Git Three-Way Diff Alias Installer"
cyan "====================================="
echo ""

# Check if Meld is installed
yellow "Checking for Meld dependency..."
if ! command -v meld >/dev/null 2>&1; then
    echo ""
    red "ERROR: Meld is not installed or not in PATH"
    echo ""
    yellow "Meld is required for this git alias to work. Please install it first:"
    echo "  Linux (Debian/Ubuntu): sudo apt install meld"
    echo "  Linux (Fedora):        sudo dnf install meld"
    echo "  macOS (Homebrew):      brew install --cask meld"
    echo "  Windows (Chocolatey):  choco install meld"
    echo "  Windows (winget):      winget install Meld.Meld"
    echo "  Or download from:      https://meldmerge.org/"
    echo ""
    red "Installation aborted."
    exit 1
fi
green "[OK] Meld found at: $(command -v meld)"

# Resolve script directory (portable across bash/sh on Linux, macOS, Git Bash)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_SCRIPT="$SCRIPT_DIR/twdiff.sh"
DEST_SCRIPT="$HOME/git-alias-twdiff.sh"

if [ ! -f "$SOURCE_SCRIPT" ]; then
    echo ""
    red "ERROR: Could not find twdiff.sh next to this installer"
    yellow "Expected path: $SOURCE_SCRIPT"
    echo ""
    red "Installation aborted."
    exit 1
fi

# Prompt before overwriting an existing install
if [ -f "$DEST_SCRIPT" ]; then
    echo ""
    yellow "Warning: git-alias-twdiff.sh already exists in your home directory:"
    echo "  $DEST_SCRIPT"
    echo ""
    while :; do
        printf 'Do you want to overwrite it? (y/N) '
        read -r response || response=""
        response="$(printf '%s' "$response" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')"
        case "$response" in
            y|yes) break ;;
            ""|n|no)
                echo ""
                yellow "Installation cancelled by user."
                exit 0
                ;;
        esac
    done
    echo ""
fi

yellow "Copying twdiff.sh to home directory..."
if ! cp "$SOURCE_SCRIPT" "$DEST_SCRIPT"; then
    echo ""
    red "ERROR: Failed to copy script to home directory"
    red "Installation aborted."
    exit 1
fi
chmod +x "$DEST_SCRIPT" 2>/dev/null || true
green "[OK] Script copied to: $DEST_SCRIPT"

# Register git alias. Git executes `!`-prefixed aliases via /bin/sh (even on
# Windows, via the sh bundled with Git for Windows), so this works uniformly
# from CMD, PowerShell, Git Bash, macOS, and Linux.
#
# We pass the path through `sh` explicitly so the file does not need to be
# marked executable on filesystems that ignore the bit (e.g. NTFS).
ALIAS_VALUE="!sh \"$DEST_SCRIPT\""

yellow "Registering git alias..."
if git config --global alias.twdiff "$ALIAS_VALUE"; then
    green "[OK] Git alias registered successfully"
else
    echo ""
    red "ERROR: Failed to register git alias"
    yellow "You can manually register it with:"
    echo "  git config --global alias.twdiff '$ALIAS_VALUE'"
    exit 1
fi

echo ""
cyan "Installation completed successfully!"
echo ""
echo "Try it with:  git twdiff <branch1> <branch2>"
