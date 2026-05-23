Import-Module ps-readline
Import-Module posh-git
Import-Module custom -Force
# Import-Module work-prompt -Force

# https://learn.microsoft.com/en-us/windows/terminal/tutorials/new-tab-same-directory
function Invoke-Starship-PreCommand {
    $loc = $executionContext.SessionState.Path.CurrentLocation;
    $prompt = "$([char]27)]9;12$([char]7)"
    if ($loc.Provider.Name -eq "FileSystem") {
        $prompt += "$([char]27)]9;9;`"$($loc.ProviderPath)`"$([char]27)\"
    }
    $host.ui.Write($prompt)
}

gh completion -s powershell | Out-String | Invoke-Expression
just --completions powershell | Out-String | Invoke-Expression
rustup completions powershell | Out-String | Invoke-Expression
task --completion powershell | Out-String | Invoke-Expression
minikube completion powershell | Out-String | Invoke-Expression
kubectl completion powershell | Out-String | Invoke-Expression
docker completion powershell | Out-String | Invoke-Expression

fnm completions --shell powershell | Out-String | Invoke-Expression
fnm env --use-on-cd | Out-String | Invoke-Expression

pnpm completion pwsh | Out-String | Invoke-Expression

Invoke-Expression (&starship init powershell)
