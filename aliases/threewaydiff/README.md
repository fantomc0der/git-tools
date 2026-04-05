# Git Three-Way Diff Alias

A portable shell-based git alias that provides visual three-way diff comparison between two git branches using [Meld](https://meldmerge.org/). Runs identically on Linux, macOS, and Windows (via Git Bash, or called through the git alias from CMD / PowerShell).

---

## Overview

When working with git branches, it's often useful to see not just what changed between two branches, but also how those changes relate to their common ancestor (merge base). This alias:

1. **Finds the merge base** between two specified branches
2. **Identifies changed files** (or checks out full branch states)
3. **Opens Meld** with a three-way comparison view:
   - **Left pane**: First branch
   - **Center pane**: Common base version
   - **Right pane**: Second branch

---

## Prerequisites

### 1. Bash

- **Linux / macOS**: already present.
- **Windows**: comes bundled with [Git for Windows](https://git-scm.com/download/win) as "Git Bash". Nothing else to install — the git alias invokes the bundled `sh` automatically, so the tool works from CMD and PowerShell too.

### 2. Meld

| Platform | Command |
|---|---|
| Debian / Ubuntu | `sudo apt install meld` |
| Fedora | `sudo dnf install meld` |
| macOS (Homebrew) | `brew install --cask meld` |
| Windows (Chocolatey) | `choco install meld` |
| Windows (winget) | `winget install Meld.Meld` |
| Any | Download from https://meldmerge.org/ |

Verify with:

```bash
meld --version
```

On Windows, make sure `meld` is on your `PATH` (the Chocolatey and winget installers both add it).

---

## Installation

From **Git Bash** (Windows), **Terminal** (macOS), or any shell (Linux):

```bash
cd path/to/git-tools/aliases/threewaydiff
./install.sh
```

The installer will:

- Check that Meld is on `PATH`
- Copy `twdiff.sh` to `~/git-alias-twdiff.sh`
- Prompt before overwriting an existing installation
- Register the global git alias `twdiff`

> **Windows note:** always run `install.sh` from **Git Bash**, not CMD or PowerShell. Once installed, the alias itself works from any shell — see [Usage on Windows](#usage-on-windows) below.

---

## Usage

Once installed, from any git repository on any platform:

```bash
git twdiff <branch1> <branch2>                 # Full branch state (default)
git twdiff <branch1> <branch2> --changed-files # Only changed files
```

### Usage on Windows

The git alias is registered as `!sh "$HOME/git-alias-twdiff.sh"`. Git executes `!`-prefixed aliases through the `sh` bundled with Git for Windows, regardless of which shell you ran `git` from. That means the **same `git twdiff` command works identically** from:

- Git Bash
- Command Prompt (`cmd.exe`)
- PowerShell / PowerShell 7
- Windows Terminal (any profile)
- VS Code integrated terminal

No wrapper, no `powershell -File …`, no execution-policy tweaks.

#### If `meld` is not found when run from CMD/PowerShell

Occasionally, `meld` is on your Git Bash `PATH` but not your system `PATH` (or vice-versa). Verify with:

- **Git Bash**: `command -v meld`
- **CMD**: `where meld`
- **PowerShell**: `Get-Command meld`

If any of those fail, add Meld's install directory to the **system** `PATH` environment variable (usually `C:\Program Files (x86)\Meld\`), then restart your terminal.

#### Making Git Bash your default terminal on Windows

Optional, but convenient if you want a POSIX shell everywhere:

- **Windows Terminal**: Settings → Add new profile → Command line: `"C:\Program Files\Git\bin\bash.exe" --login -i` (adjust path if needed). Set it as the default profile.
- **VS Code**: Settings → `terminal.integrated.defaultProfile.windows` → `Git Bash`.
- **Default system shell**: Windows does not support replacing `cmd.exe` as the global shell, but the two items above cover the places it matters in practice.

---

## Comparison Modes

### Full State Mode (default)

Shows complete directory structures of both branches and their merge base using git worktrees.

```bash
git twdiff main feature
```

**Benefits:**
- Complete project context — see entire directory structures
- Ideal for comparing different approaches to the same problem (e.g. LLM testing)
- Shows files added/deleted per branch
- Efficient: worktrees share the git object database

### Changed Files Mode

Shows only files that differ between the two branches, extracted to temporary directories.

```bash
git twdiff main feature --changed-files
```

**Benefits:**
- Faster on repositories with many files but few changes
- Focuses attention on actual changes
- Minimal disk usage

### Use Case: Comparing Prompt Output between LLMs

Running the same prompt against a repo with different tools and comparing results:

```bash
git twdiff ai-roo-test ai-copilot-test                  # full project state
git twdiff ai-roo-test ai-copilot-test --changed-files  # only changes
```

Meld opens with three panels: left = first branch, center = merge base, right = second branch.

---

## How It Works

1. **Finds merge base**: `git merge-base <left> <right>`
2. **Full mode**: creates three temporary worktrees (base, left, right) and hands their paths to Meld
3. **Changed-files mode**: uses `git diff --name-only` + `git show` to extract each file's three revisions into temp directories, then passes them to Meld
4. **Cleanup**: worktrees / temp files are removed on exit (via a bash `trap`), even on interrupt

On Git Bash / Cygwin / MSYS, POSIX paths are converted with `cygpath -w` before being passed to Meld (a native Windows app). On Linux and macOS, paths are passed through unchanged.

---

## Troubleshooting

### "Meld not found"

```
ERROR: Meld is not installed or not in PATH
```

Install Meld (see [Prerequisites](#2-meld)) and make sure it's on `PATH`. On Windows, restart your terminal after install so the new `PATH` is picked up.

### "Could not find merge base"

The two branches don't share any history. Check both branch names exist and come from the same repository.

### "No changed files" (changed-files mode)

The branches are identical — this is informational, not an error.

### Git alias not registered

```bash
git config --get alias.twdiff
```

Should print `!sh "…/git-alias-twdiff.sh"`. If empty, re-run `./install.sh`.

### Running `install.sh` from Windows

**Always run the installer from Git Bash**, not from CMD or PowerShell. The installer itself is a bash script. If you really need to invoke it from another shell:

- **CMD**: `"C:\Program Files\Git\bin\bash.exe" ./install.sh`
- **PowerShell**: `& "C:\Program Files\Git\bin\bash.exe" ./install.sh`

### Worktree issues (full-state mode)

```
fatal: worktree already exists
```

Left-over worktree from a previous interrupted run. Clean up with:

```bash
git worktree list
git worktree remove --force <path>
git worktree prune
```

The script already does this automatically on startup and on exit; manual cleanup is only needed if the process was killed ungracefully.

**Performance note**: full-state mode writes three checkouts to temp space. For very large repos, prefer `--changed-files`.

### Temp directories

Temp directories are created with `mktemp -d`:

- Full state mode: `<TMPDIR>/git-worktree-twdiff.XXXXXX`
- Changed files mode: `<TMPDIR>/git-alias-twdiff.XXXXXX`

`TMPDIR` resolves to `/tmp` on Linux/macOS and `C:\Users\<you>\AppData\Local\Temp` (mapped to `/tmp` inside Git Bash) on Windows. Files are cleaned up automatically when Meld closes or the script is interrupted.
