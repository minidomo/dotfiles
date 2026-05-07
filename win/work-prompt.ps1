function prompt {
    # https://learn.microsoft.com/en-us/windows/terminal/tutorials/new-tab-same-directory
    $loc = $executionContext.SessionState.Path.CurrentLocation;

    $out = ""
    if ($loc.Provider.Name -eq "FileSystem") {
        $out += "$([char]27)]9;9;`"$($loc.ProviderPath)`"$([char]27)\"
    }
    
    $out += "`r`n${display}${git}`r`n❯ ";

    return $out
}
