
function Test-Port {
    param(
        [Parameter(Mandatory)]
        [int]$Port
    )

    $res = netstat -ano | Out-String
    $lines = $res -split "[\r\n]+"
    $found = $false

    foreach ($line in $lines) {
        $parts = $line.Trim() -split "\s+"

        if ([regex]::Matches($parts[1], "$Port$")) {
            Write-Output $line
            $found = $true
        }
    }

    if (!$found) {
        Write-Output "Found nothing for port $Port"
    }
}

function Invoke-RemoteScript {
    param(
        [Parameter(Mandatory)]
        [String]$Url
    )

    $content = (Invoke-WebRequest $Url.Trim()).Content

    # some scripts might have UTF-8 BOM at the start
    $content = $content.TrimStart([char]0xFEFF)
    
    Invoke-Expression $content
}

function Optimize-Path {
    Invoke-RemoteScript "https://raw.githubusercontent.com/jonasgeiler/pathix/0dfc68071f9494c6a7e8cf13eace712902eb743b/pathix.ps1"
}

function Set-EnvVar {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [string]$Value,

        [ValidateSet("User", "Machine")]
        [string]$Scope = "User"
    )
    
    $currentValue = [System.Environment]::GetEnvironmentVariable($Name, $Scope)
    Write-Host "Current value of environment variable '$Name' for $Scope scope: '$currentValue'" -ForegroundColor Yellow

    if ([string]::IsNullOrEmpty($Value)) {
        if ([string]::IsNullOrEmpty($currentValue)) {
            Write-Host "Environment variable '$Name' does not exist for $Scope scope. Nothing to delete." -ForegroundColor Yellow
            return
        }

        [System.Environment]::SetEnvironmentVariable($Name, $null, $Scope)
        [System.Environment]::SetEnvironmentVariable($Name, $null, "Process")

        Write-Host "Environment variable '$Name' deleted for $Scope scope." -ForegroundColor Green
        return
    }

    [System.Environment]::SetEnvironmentVariable($Name, $Value, $Scope)
    [System.Environment]::SetEnvironmentVariable($Name, $Value, "Process")

    Write-Host "Environment variable '$Name' set for $Scope scope." -ForegroundColor Green
}
