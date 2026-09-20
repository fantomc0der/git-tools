# Name: enhance-git
# Description: Helper behaviors like tab completion for git with PowerShell terminals

# Local + remote branch names (short form, e.g. "main" or "origin/main") matching the given prefix
$script:EG_GetBranches = {
    param([string]$WordToComplete)
    $refs = git for-each-ref --format='%(refname)' refs/heads/ refs/remotes/ 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $refs) { return @() }
    $refs |
        Where-Object { $_ -notmatch '/HEAD$' } |
        ForEach-Object { $_ -replace '^refs/(heads|remotes)/', '' } |
        Where-Object { $_ -like "$WordToComplete*" } |
        Sort-Object -Unique
}

# Complete branch names for git commands where a branch argument is the common case
$script:EG_BranchCommands = @('switch', 'checkout', 'branch', 'rebase', 'merge')
$script:EG_GitCompleter = {
    param($wordToComplete, $commandAst, $cursorPosition)
    $tokens = $commandAst.CommandElements | ForEach-Object { $_.Extent.Text }
    if (-not ($tokens | Where-Object { $_ -in $script:EG_BranchCommands })) { return }

    & $script:EG_GetBranches $wordToComplete |
        ForEach-Object { [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_) }
}
Register-ArgumentCompleter -CommandName git -Native -ScriptBlock $script:EG_GitCompleter
