# Git Three-Way Diff Alias

A PowerShell-based git alias that provides visual three-way diff comparison between two git branches using Meld. This tool automatically extracts only the changed files between branches and displays them in Meld's three-way merge interface, showing the common base, left branch, and right branch side by side.


## Overview

When working with git branches, it's often useful to see not just what changed between two branches, but also how those changes relate to their common ancestor (merge base). This alias:

1. **Finds the merge base** between two specified branches
2. **Identifies changed files** between the branches
3. **Extracts file versions** from the base commit and both branches
4. **Opens Meld** with a three-way comparison view:
   - **Left pane**: First branch version
   - **Center pane**: Common base version
   - **Right pane**: Second branch version

This provides a comprehensive view of how changes evolved from the common ancestor, making it easier to understand conflicts, review changes, and make informed merge decisions.


## Prerequisites

### Meld Installation

This alias requires Meld, a visual diff and merge tool. Install it using one of these methods:

**Using Chocolatey (Recommended for Windows):**
```powershell
choco install meld
```

**Alternative Installation Methods:**
- Download directly from [https://meldmerge.org/](https://meldmerge.org/)
- Use Windows Package Manager: `winget install Meld.Meld`

**Verify Installation:**
```powershell
# This should return the path to meld.exe
Get-Command meld
```


## Installation

1. **Download or clone** this repository to your local machine

2. **Navigate** to the `aliases/threewaydiff` directory:
   ```powershell
   cd path\to\git-tools\aliases\threewaydiff
   ```

3. **Run the installation script**:
   ```powershell
   .\install.ps1
   ```

The installer will:
- ✅ Check if Meld is installed and accessible
- ✅ Copy `threewaydiff.ps1` to your user profile as `git-threewaydiff-alias.ps1`
- ✅ Prompt for confirmation if the file already exists
- ✅ Register the git alias globally using `git config`


## Usage

Once installed, use the alias from any git repository:

```bash
git threewaydiff <branch1> <branch2>                # Complete branch state comparison (default)
git threewaydiff <branch1> <branch2> --changed-files # Changed files only
```

## Comparison Modes

### **Full State Mode (Default)**
Shows complete directory structures of both branches and their merge-base using git worktrees.

**Usage:** `git threewaydiff main feature`

**Benefits:**
- Complete project context - see entire directory structures
- Ideal for comparing different approaches to the same problem (e.g., LLM testing)
- Shows files added/deleted in branches
- Efficient implementation using git worktrees (shares git database)

### **Changed Files Mode**
Shows only files that differ between the two branches, extracted to temporary directories.

**Usage:** `git threewaydiff main feature --changed-files`

**Benefits:**
- Faster for repositories with many files but few changes
- Focuses attention only on actual changes
- Minimal disk space usage

**Perfect for:**
- Testing the same prompt against different LLMs and comparing results
- Large refactoring analysis where unchanged files provide important context
- Understanding complete project state differences

### LLM Testing Example

You want to run the same LLM prompt against a repository using two different tools and compare the results from each to determine which LLM best completed the task.

**For complete project state comparison (default):**
```bash
git threewaydiff ai-roo-test ai-copilot-test
```

**For changed files only:**
```bash
git threewaydiff ai-roo-test ai-copilot-test --changed-files
```

**What you will see in Meld:**
When using either mode, Meld opens with three panels:
- **Left**: `ai-roo-test` branch files
- **Center**: Common base (merge-base) files
- **Right**: `ai-copilot-test` branch files

**Full state mode (default)** shows complete directory structures, giving you full project context.
**Changed files mode** shows only files that differ between branches.


## How It Works

1. **Finds merge base**: Uses `git merge-base` to find the common ancestor
2. **Identifies changes**: Uses `git diff --name-only` to find modified files
3. **Extracts versions**: Uses `git show` to extract each file version to temp directories
4. **Launches Meld**: Opens the three-way diff with proper directory structure
5. **Cleanup**: Removes temporary files when Meld is closed


## Troubleshooting

### "Meld not found" Error
```
ERROR: Meld is not installed or not in PATH
```
**Solution**: Install Meld using `choco install meld` or ensure it's in your PATH.

### "Could not find merge base" Error
```
Error: Could not find merge base between branch1 and branch2
```
**Solution**: This happens when branches don't share common history. Check that:
- Both branch names are correct and exist
- You're in a git repository
- The branches have a shared commit history

### "No changed files" Message
```
No changed files between branch1 and branch2
```
**Solution**: This is normal when branches are identical. The branches you're comparing have no differences.

### PowerShell Execution Policy Issues
**Error**: `execution of scripts is disabled on this system`

**Solution**: The install script automatically handles this by including `-ExecutionPolicy Bypass` in the git alias. If you're still having issues, you can manually allow script execution for the current user:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Git Alias Not Working
**Check if alias is registered:**
```bash
git config --get alias.threewaydiff
```

### Temp Directory Issues
If you encounter issues with temporary files:
- **Full state mode (default)**: Uses `$env:TEMP\git-worktree-threewaydiff`
- **Changed files mode**: Uses `$env:TEMP\git-alias-threewaydiff`
- Files are automatically cleaned up when Meld closes
- You can manually delete these folders if needed

### Git Worktree Issues (Default Mode)
**Error**: `fatal: worktree already exists`
```
git worktree remove --force "path/to/worktree"
```

**Error**: `Worktree creation failed`
- Ensure you have sufficient disk space for complete repository checkout
- Check that the specified branches/commits exist
- Run `git worktree list` to see existing worktrees

**Performance considerations:**
- Default mode requires disk space for complete project checkout (3x repository size)
- For very large repositories, consider using `--changed-files` mode for faster operation
- Worktrees share the git object database but create separate working directories
