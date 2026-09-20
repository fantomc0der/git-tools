# enhance-git (PowerShell profile helpers)

Git helper behaviors for PowerShell terminals, currently tab completion of local and remote branch names for `git switch`, `git checkout`, `git branch`, `git rebase`, and `git merge`.

The helpers live in [`enhance-git.ps1`](enhance-git.ps1). [`install.ps1`](install.ps1) copies that file into your PowerShell profile inside a marked block so it can be re-applied whenever the source changes here.

---

## Prerequisites

- PowerShell 5.1 or PowerShell 7+
- `git` on `PATH`

---

## Installation

From PowerShell, in this directory:

```powershell
.\install.ps1
```

Then reload your profile:

```powershell
. $PROFILE
```

(or just open a new PowerShell window).

If your execution policy blocks the script, run it once with a bypass:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

### What the installer does

1. Backs up your existing profile to `<profile>.bak-<timestamp>` (skip with `-NoBackup`)
2. Creates the profile file and its directory if they do not exist
3. Writes the contents of `enhance-git.ps1` into the profile, wrapped in boundary markers

The installed block looks like this:

```powershell
####### BEGIN git-tools:enhance-git #######
# Managed by git-tools scripts/enhance-git/install.ps1. Edits inside this block are
# overwritten on the next install; change enhance-git.ps1 in the repo instead.

# ... contents of enhance-git.ps1 ...
####### END git-tools:enhance-git #######
```

Everything outside those markers is left untouched.

---

## Updating

Pull the latest changes and run the installer again:

```powershell
.\install.ps1
```

The installer replaces everything between the markers in place, so the block stays where it is in your profile and the rest of your profile is preserved. Because the block is regenerated on every run, do not edit it directly: change `enhance-git.ps1` in the repo instead.

---

## Uninstalling

```powershell
.\install.ps1 -Uninstall
```

This removes the marked block and leaves the rest of the profile alone.

---

## Options

| Parameter | Description |
|---|---|
| `-ProfilePath <path>` | Profile to modify. Defaults to `$PROFILE` (current user, current host). Use `$PROFILE.CurrentUserAllHosts` to install for every host, such as the console and the VS Code integrated terminal. |
| `-Uninstall` | Remove the managed block instead of installing it. |
| `-NoBackup` | Skip the timestamped backup copy of the profile. |

---

## Usage

Once installed, type a git command that takes a branch and press <kbd>Tab</kbd>:

```powershell
git switch ma<Tab>        # -> git switch main
git rebase origin/<Tab>   # -> git rebase origin/main
```

Completion is offered only when the command line contains one of the branch-taking subcommands, so other git commands keep PowerShell's default file completion.

---

## Troubleshooting

### Completion does nothing

Confirm the block is present and loaded:

```powershell
Select-String -Path $PROFILE -Pattern 'BEGIN git-tools:enhance-git' -SimpleMatch
Get-Command git
```

If the block is there but completion is inactive, your session predates the install. Run `. $PROFILE` or open a new window.

If you use multiple hosts (console, VS Code, Windows Terminal profiles) and completion works in only some of them, install into the all-hosts profile instead:

```powershell
.\install.ps1 -ProfilePath $PROFILE.CurrentUserAllHosts
```

### "Found the BEGIN marker but no matching END marker"

The block was partially deleted or edited by hand. Remove the leftover marker line from your profile, then re-run the installer.

### Restoring a profile

Every install (unless run with `-NoBackup`) leaves a `<profile>.bak-<timestamp>` file next to the profile. Copy it back over `$PROFILE` to undo a change.
