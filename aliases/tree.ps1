function tree {
    $dir = (Get-Location).Path
    $ignore = $null
    while ($dir -and $dir -ne [System.IO.Path]::GetPathRoot($dir)) {
        $candidate = Join-Path $dir ".treeignore"
        if (Test-Path $candidate) {
            $ignore = $candidate
            break
        }
        $dir = Split-Path $dir -Parent
    }
    $realTree = (Get-Command tree -CommandType Application | Select-Object -First 1).Source
    if ($ignore) {
        & $realTree --gitfile $ignore @args
    } else {
        & $realTree @args
    }
}
