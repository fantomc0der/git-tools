# Git Config 

## Settings 

Allows `git push` (with no arguments) to push current branch to configured upstream branch, even if the local and remote branch names differ:  
```
git config --global push.default upstream
```

## Aliases

Safely force push branch:  
```
git config --global alias.pushf "push --force-with-lease"
```

Rebase latest from origin/main to current branch:
```
git config --global alias.remain '!git fetch --prune && git rebase origin/main'
```

Delete all local branches whose upstreams are gone (e.g. merged branch):  
```
PowerShell (doubled '' escapes the inner single quotes):
git config --global alias.gone '!git fetch -p && git branch -vv | awk ''$1=="*"{next} /: gone]/{print $1}'' | xargs -r git branch -D'

Bash / Git Bash:
git config --global alias.gone '!git fetch -p && git branch -vv | awk '\''$1=="*"{next} /: gone]/{print $1}'\'' | xargs -r git branch -D'
```
