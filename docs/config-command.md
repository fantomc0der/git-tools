# Git Config 

## Settings 

Allows `git push` (with no arguments) to push current branch to configured upstream branch, even if the local and remote branch names differ:  
```
git config --global push.default upstream
```

## Aliases

Safely force push branch:  
```
git config --global alias.pushfwl "push --force-with-lease"
```

Delete all local branches whose upstreams are gone (e.g. merged branch):  
```
PowerShell (doubled '' escapes the inner single quotes):
git config --global alias.gone '!git fetch -p && git branch -vv | awk ''$1=="*"{next} /: gone]/{print $1}'' | xargs -r git branch -D'

Bash / Git Bash:
git config --global alias.gone '!git fetch -p && git branch -vv | awk '\''$1=="*"{next} /: gone]/{print $1}'\'' | xargs -r git branch -D'
```
