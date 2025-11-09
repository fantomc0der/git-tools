# Git Diffing Commands and Tooling

This document provides a comprehensive guide to performing effective diffing in Git, including scenarios for comparing branches, configuring pagers and difftools, using advanced tools like **delta**, and managing Git configuration files.


## Git Diffing Scenarios

### Comparing Two Local Branches
When you need to compare two branches locally without pushing to a remote repository, Git offers several approaches:

#### Unified Diff with `git diff`
```powershell
git diff branch1..branch2
```
- Displays all changes between the two branches in a unified diff format.
- Add `--stat` for a summary of changes:
```powershell
git diff --stat branch1..branch2
```

#### Visual Comparison with `git difftool`
```powershell
git difftool --dir-diff branch1..branch2
```
- Opens both branches as directories in your configured difftool.
- Useful for file-by-file side-by-side comparison.

#### Commit-Level Comparison with `git range-diff`
```powershell
git range-diff branch1 branch2
```
- Compares commits between two branches, not just the final state.
- Ideal for understanding how changes were structured.

#### Enhanced CLI Diff with Delta
```powershell
git diff branch1..branch2 | delta --side-by-side --line-numbers
```
- Provides syntax highlighting, side-by-side view, and improved readability.


## Configuring Git Pagers and Difftools

### Pagers 
A pager displays output that doesn’t fit on one screen. Git uses `less` by default, but you can replace it with tools like **delta** for enhanced output.

#### Global Pager Setting
```powershell
git config --global core.pager delta
```
- Makes delta the default pager for all Git commands.

#### Command-Specific Pager Override
```powershell
git config --global pager.diff "delta --side-by-side --line-numbers"
```
- Overrides the pager for `git diff` only.
- `pager.diff` takes precedence over `core.pager`.

### Difftools
A diff tool (via `git difftool`) shows a **visual file-by-file comparison** of diffs using an external tool.

#### Example configurations for specific tools
Certain tools are natively supported by git and only setting `diff.tool` is sufficient to work. However, if you want to use an unsupported tool, you must configure `difftool.{tool_name}.cmd` to indicate how to execute the tool.  

**Meld**
```powershell
git config --global diff.tool meld
```

**WinMerge** 
```powershell
git config --global diff.tool winmerge
git config --global difftool.winmerge.cmd '"C:/Program Files/WinMerge/WinMergeU.exe" -e -u -dl LEFT -dr RIGHT "$LOCAL" "$REMOTE"'
```

**VS Code**
```powershell
git config --global diff.tool vscode
git config --global difftool.vscode.cmd "code --wait --diff $LOCAL $REMOTE"
```

#### Useful configuration options 

**Prompting**  
With prompting disabled, running `git difftool` will open each file one at a time in the tool; after closing the tool, it'll automatically open the next changed file. If you prefer to be prompted for each file to support being able to skip one, you'll want to enable prompting with:   
```powershell
git config --global difftool.prompt true
```

## Specific Tools for Paging/Diffing

### Delta
[Delta](https://github.com/dandavison/delta) is a syntax-highlighting pager for Git output, offering advanced diff visualization.

#### Features
- Syntax highlighting for many languages.
- Side-by-side diffs (`--side-by-side`).
- Word-level diff highlighting.
- Line numbers and better navigation.

#### Installation
- macOS: `brew install git-delta`
- Windows: `choco install delta`
- Linux: `dnf install git-delta` or `pacman -S git-delta`

#### Basic Usage
```powershell
git diff | delta
```

#### Permanent Setup for Side-by-Side Diffs
```powershell
git config --global core.pager delta
git config --global pager.diff "delta --side-by-side --line-numbers"
```
- Ensures delta is used for all commands, with custom options for diffs.

#### Ad-Hoc Comparison
```powershell
git diff branch1..branch2 | delta --side-by-side --line-numbers
```


## Managing Git Configuration

### Config Scopes and Locations on Windows
- **System-level:** `C:\Program Files\Git\etc\gitconfig`
- **Global (user):** `C:\Users\<YourUsername>\.gitconfig`
- **Local (repository):** `<repo>\.git\config`

### Checking Current Settings
```powershell
git config --list --show-origin
```
- Displays all active settings and their source file.

### Editing Global Config
```powershell
notepad %USERPROFILE%\.gitconfig
```

### Viewing All Available Keys
```powershell
git help config
```
- Shows documentation for all configuration options.

