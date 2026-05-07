$script:WorkPromptGitChecked = $false
$script:WorkPromptGitCommand = $null
$script:WorkPromptHomePath = if ($HOME) {
    [System.IO.Path]::GetFullPath($HOME)
}
else {
    $null
}

function Test-WorkPromptIsSameOrChildPath {
    param(
        [string]$Path,
        [string]$BasePath
    )

    if ([string]::IsNullOrEmpty($BasePath)) {
        return $false
    }

    if (-not $Path.StartsWith($BasePath, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $false
    }

    if ($Path.Length -eq $BasePath.Length) {
        return $true
    }

    $nextChar = $Path[$BasePath.Length]
    return $nextChar -eq '\' -or $nextChar -eq '/'
}

function Get-WorkPromptSegments {
    param(
        [string]$Path
    )

    $segments = [System.Collections.Generic.List[string]]::new()
    foreach ($segment in ($Path -split '[\\/]')) {
        if ($segment) {
            [void]$segments.Add($segment)
        }
    }

    return $segments.ToArray()
}

function Get-WorkPromptLastSegments {
    param(
        [string[]]$Segments,
        [int]$Count
    )

    if ($Segments.Count -le $Count) {
        return ($Segments -join '/')
    }

    return ($Segments[($Segments.Count - $Count)..($Segments.Count - 1)] -join '/')
}

function Get-WorkPromptPathDisplay {
    param(
        [string]$Path
    )

    $fullPath = [System.IO.Path]::GetFullPath($Path)

    if (Test-WorkPromptIsSameOrChildPath -Path $fullPath -BasePath $script:WorkPromptHomePath) {
        if ($fullPath.Length -eq $script:WorkPromptHomePath.Length) {
            return '~'
        }

        $relativePath = $fullPath.Substring($script:WorkPromptHomePath.Length).TrimStart('\', '/')
        $segments = Get-WorkPromptSegments -Path $relativePath

        if ($segments.Count -le 2) {
            return "~/$($segments -join '/')"
        }

        return Get-WorkPromptLastSegments -Segments $segments -Count 3
    }

    $root = [System.IO.Path]::GetPathRoot($fullPath)
    $rootDisplay = "$($root.TrimEnd('\', '/'))/"
    $relativePath = $fullPath.Substring($root.Length)

    if ([string]::IsNullOrEmpty($relativePath)) {
        return $rootDisplay
    }

    $segments = Get-WorkPromptSegments -Path $relativePath
    if ($segments.Count -le 2) {
        return "$rootDisplay$($segments -join '/')"
    }

    return Get-WorkPromptLastSegments -Segments $segments -Count 3
}

function Get-WorkPromptGitCommand {
    if (-not $script:WorkPromptGitChecked) {
        $command = Get-Command git -CommandType Application -ErrorAction Ignore | Select-Object -First 1
        if ($command) {
            $script:WorkPromptGitCommand = $command.Source
        }

        $script:WorkPromptGitChecked = $true
    }

    return $script:WorkPromptGitCommand
}

function Get-WorkPromptRepositoryRoot {
    param(
        [string]$Path
    )

    $directory = [System.IO.DirectoryInfo]::new([System.IO.Path]::GetFullPath($Path))
    while ($directory) {
        if (Test-Path -LiteralPath (Join-Path $directory.FullName '.git')) {
            return $directory.FullName
        }

        $directory = $directory.Parent
    }

    return $null
}

function Get-WorkPromptGitDisplay {
    param(
        [string]$Path
    )

    $gitCommand = Get-WorkPromptGitCommand
    if (-not $gitCommand) {
        return $null
    }

    $repositoryRoot = Get-WorkPromptRepositoryRoot -Path $Path
    if (-not $repositoryRoot) {
        return $null
    }

    $statusLines = & $gitCommand -C $repositoryRoot status --porcelain=v2 --branch 2>$null
    if ($LASTEXITCODE -ne 0) {
        return $null
    }

    $branch = 'HEAD'
    $isDirty = $false

    foreach ($line in $statusLines) {
        if ($line.StartsWith('# branch.head ')) {
            $branch = $line.Substring(14)
            if ($branch -eq '(detached)') {
                $branch = 'HEAD'
            }

            continue
        }

        if (-not $line.StartsWith('#')) {
            $isDirty = $true
            break
        }
    }

    $dirtyMarker = if ($isDirty) { '*' } else { '' }
    $repositoryName = Split-Path -Leaf $repositoryRoot
    return "$repositoryName $branch$dirtyMarker"
}

function prompt {
    # https://learn.microsoft.com/en-us/windows/terminal/tutorials/new-tab-same-directory
    $loc = $executionContext.SessionState.Path.CurrentLocation
    $out = ""

    if ($loc.Provider.Name -eq 'FileSystem') {
        $out += "$([char]27)]9;9;`"$($loc.ProviderPath)`"$([char]27)\"

        $display = Get-WorkPromptGitDisplay -Path $loc.ProviderPath
        if (-not $display) {
            $display = Get-WorkPromptPathDisplay -Path $loc.ProviderPath
        }
    }
    else {
        $display = $loc.Path
    }

    $out += "`r`n$display`r`n❯ "
    return $out
}
