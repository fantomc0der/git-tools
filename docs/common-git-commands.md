# Common Git Commands

This reference highlights the Git commands developers use most often, along with brief explanations and typical usage patterns.

## Repository Setup and Inspection
- `git init`: Create a new Git repository in the current directory.
- `git clone <repo-url>`: Copy an existing repository (includes its history) to your machine.
- `git status`: Show the working tree state, including staged/unstaged changes and untracked files.
- `git diff` / `git diff --staged`: View unstaged or staged changes, respectively.
- `git log --oneline --graph --decorate`: Review commit history in a concise, visual format.

## Working with Changes
- `git add <file>` / `git add .`: Stage specific files or all tracked/untracked changes in the current directory.
- `git restore <file>`: Discard unstaged changes in a file and reset it to the last committed version.
- `git restore --staged <file>`: Unstage a file while keeping working tree changes.
- `git commit -m "<message>"`: Record staged changes with a descriptive message.
- `git commit --amend`: Update the most recent commit with new changes and/or a new message.
- `git checkout -- <file>`: Legacy command to discard unstaged changes; use `git restore` for new workflows.

## Branching and Merging
- `git branch`: List local branches; with `-a`, also show remote branches.
- `git branch <name>`: Create a new branch at the current commit.
- `git switch <name>` / `git checkout <name>`: Move between branches.
- `git merge <branch>`: Merge the specified branch into the current one, creating a merge commit by default.
- `git rebase <branch>`: Replay commits from the current branch on top of `<branch>` for a linear history.
- `git cherry-pick <commit>`: Apply a specific commit onto the current branch.

## Synchronizing with Remotes
- `git fetch`: Download commits, branches, and tags from the remote without merging them.
- `git pull` (`git fetch` + `git merge`): Update the current branch with remote changes using a merge strategy.
- `git pull --rebase`: Update the current branch while rebasing your local commits on top of the fetched commits.
- `git push`: Upload local commits to the remote branch.
- `git push -u origin <branch>`: Push a new branch and set it as the upstream for future pulls/pushes.

## Stashing and Cleanup
- `git stash push -m "<message>"`: Save uncommitted changes (both staged and unstaged) to a stash with a label.
- `git stash list`: Show saved stashes.
- `git stash pop`: Reapply the most recent stash and remove it from the list.
- `git stash apply <stash>`: Apply a specific stash without deleting it.
- `git clean -fd`: Remove untracked files (`-f`) and directories (`-d`); use cautiously.

## Inspection and Recovery
- `git show <ref>`: Display details for a commit, tag, or other reference.
- `git blame <file>`: Show line-by-line authorship for a file.
- `git reflog`: List the history of `HEAD` movements to recover lost commits or branches.
- `git bisect`: Perform a binary search through history to find a commit that introduced a bug.
- `git tag <name>`: Create a lightweight tag at the current commit (use `-a` for annotated tags).

## Configuration and Help
- `git config --global user.name "<name>"` / `git config --global user.email "<email>"`: Set author identity for all repositories.
- `git config --global core.editor "<editor>"`: Choose the editor Git uses for commit messages and other prompts.
- `git help <command>` or `<command> --help`: Show documentation and options for a specific Git command.

## Useful Shortcuts
- `git stash save --keep-index`: Stash only unstaged changes, keeping staged changes intact.
- `git commit -am "<message>"`: Stage and commit tracked file changes in one step.
- `git pull --rebase --autostash`: Automatically stash local changes before rebasing and reapply them afterward.
