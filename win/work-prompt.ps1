#region Native prompt

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

function Get-WorkPromptGitPathDisplay {
    param(
        [string]$Path,
        [string]$RepositoryRoot
    )

    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $fullRepositoryRoot = [System.IO.Path]::GetFullPath($RepositoryRoot)
    $segments = [System.Collections.Generic.List[string]]::new()

    [void]$segments.Add((Split-Path -Leaf $fullRepositoryRoot))

    if ($fullPath.Length -gt $fullRepositoryRoot.Length) {
        $relativePath = $fullPath.Substring($fullRepositoryRoot.Length).TrimStart('\', '/')

        foreach ($segment in (Get-WorkPromptSegments -Path $relativePath)) {
            [void]$segments.Add($segment)
        }
    }

    if ($segments.Count -le 3) {
        return ($segments -join '/')
    }

    return Get-WorkPromptLastSegments -Segments $segments.ToArray() -Count 3
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

function Test-WorkPromptGitHasUntrackedChanges {
    param(
        [string]$GitCommand,
        [string]$RepositoryRoot
    )

    $firstUntrackedPath = & $GitCommand -C $RepositoryRoot ls-files --others --exclude-standard --directory --no-empty-directory 2>$null |
    Select-Object -First 1

    if ($LASTEXITCODE -ne 0) {
        return $null
    }

    return -not [string]::IsNullOrEmpty([string]$firstUntrackedPath)
}

function Get-WorkPromptGitBranch {
    param(
        [string]$GitCommand,
        [string]$RepositoryRoot
    )

    $branch = & $GitCommand -C $RepositoryRoot symbolic-ref --quiet --short HEAD 2>$null
    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrEmpty([string]$branch)) {
        return [string]$branch
    }

    if ($LASTEXITCODE -eq 1) {
        return 'HEAD'
    }

    return $null
}

function Get-WorkPromptGitInfo {
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

    $branch = Get-WorkPromptGitBranch -GitCommand $gitCommand -RepositoryRoot $repositoryRoot
    if (-not $branch) {
        return $null
    }

    $statusLines = & $gitCommand -C $repositoryRoot status --porcelain=v2 --untracked-files=no 2>$null
    if ($LASTEXITCODE -ne 0) {
        return $null
    }

    $isDirty = $false

    foreach ($line in $statusLines) {
        if (-not [string]::IsNullOrEmpty([string]$line)) {
            $isDirty = $true
            break
        }
    }

    if (-not $isDirty) {
        $hasUntrackedChanges = Test-WorkPromptGitHasUntrackedChanges -GitCommand $gitCommand -RepositoryRoot $repositoryRoot
        if ($null -eq $hasUntrackedChanges) {
            return $null
        }

        $isDirty = $hasUntrackedChanges
    }

    $dirtyMarker = if ($isDirty) { '*' } else { '' }
    $displayPath = Get-WorkPromptGitPathDisplay -Path $Path -RepositoryRoot $repositoryRoot

    return [pscustomobject]@{
        DisplayPath = $displayPath
        Branch      = $branch
        DirtyMarker = $dirtyMarker
    }
}

function prompt {
    $lastCommandSucceeded = $?
    
    # https://learn.microsoft.com/en-us/windows/terminal/tutorials/new-tab-same-directory
    $loc = $executionContext.SessionState.Path.CurrentLocation
    $out = ""

    if ($loc.Provider.Name -eq 'FileSystem') {
        $out += "$([char]27)]9;9;`"$($loc.ProviderPath)`"$([char]27)\"

        $gitInfo = Get-WorkPromptGitInfo -Path $loc.ProviderPath

        if ($gitInfo) {
            $display = @(
                "$($PSStyle.Foreground.Blue)$($gitInfo.DisplayPath)$($PSStyle.Reset)"
                "$($PSStyle.Foreground.BrightBlack) $($gitInfo.Branch)$($PSStyle.Reset)"
                if ($gitInfo.DirtyMarker) {
                    "$($PSStyle.Foreground.Yellow)$($gitInfo.DirtyMarker)$($PSStyle.Reset)"
                }
            ) -join ''
        }
        else {
            $display = "$($PSStyle.Foreground.Blue)$(Get-WorkPromptPathDisplay -Path $loc.ProviderPath)$($PSStyle.Reset)"
        }
    }
    else {
        $display = "$($PSStyle.Foreground.Blue)$($loc.Path)$($PSStyle.Reset)"
    }

    $promptColor = if ($lastCommandSucceeded) {
        $PSStyle.Foreground.Magenta
    }
    else {
        $PSStyle.Foreground.Red
    }

    $out += "`r`n$display`r`n$promptColor❯$($PSStyle.Reset) "
    return $out
}

#endregion Native prompt
