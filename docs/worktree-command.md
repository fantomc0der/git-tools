# Git Worktrees

Git worktrees allow you to check out multiple branches simultaneously by creating additional working directories, all linked to the same repository.

## Key Concepts

A **worktree** refers to the physical directory itself. Each worktree maintains its own checked-out branch, but they all share the same Git history and objects. The initial branch you specify when creating a worktree can later be changed to any other branch—as long as that branch isn't already checked out in another worktree.

## Working with Worktrees

Navigate into any worktree directory and use Git commands as usual. Each worktree operates independently, so you can stage, commit, and manage changes without affecting other worktrees.

### Understanding `git branch` Output

When you run `git branch`, the output distinguishes between branches based on their worktree status:

| Color | Symbol | Meaning |
|-------|--------|---------|
| Green | `*` | Checked out in current worktree |
| Blue | `+` | Checked out in another worktree |
| White | — | Not checked out anywhere |

Attempting to check out a branch marked with `+` will fail because Git prevents the same branch from being checked out in multiple worktrees simultaneously.

## Common Commands

### List all worktrees

```bash
git worktree list
```

Displays each worktree's directory path, current commit hash, and checked-out branch.

### Create a worktree for an existing branch

```bash
git worktree add ../mpd-com_develop develop
```

This creates a new directory at `../mpd-com_develop` with the `develop` branch checked out.

**Note:** You must have a different branch checked out in your current worktree before running this command.

### Remove a worktree

```bash
git worktree remove ../mpd-com_develop
```

Removes the worktree when you're finished working with it. This deletes the directory and updates Git's internal worktree tracking.

## Naming Convention Tip

Consider naming your worktree directories to reflect both the project and branch, such as `project_branch`. This makes it easy to identify which branch each directory contains when you have multiple worktrees.
