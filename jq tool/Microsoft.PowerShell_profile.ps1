# Ensure winget jq is on PATH (terminals started before install may miss it)
$script:JqDir = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages\jqlang.jq_Microsoft.Winget.Source_8wekyb3d8bbwe'
if ((Test-Path (Join-Path $script:JqDir 'jq.exe')) -and ($env:PATH -notlike "*$($script:JqDir)*")) {
    $env:PATH = "$script:JqDir;$env:PATH"
}

function Get-JqExe {
    $cmd = Get-Command jq.exe -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    $fallback = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages\jqlang.jq_Microsoft.Winget.Source_8wekyb3d8bbwe\jq.exe'
    if (Test-Path -LiteralPath $fallback) { return $fallback }

    $packages = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages'
    if (Test-Path -LiteralPath $packages) {
        $found = Get-ChildItem -LiteralPath $packages -Filter 'jq.exe' -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) { return $found.FullName }
    }
    return $null
}

function jsontidy {
    <#
    .SYNOPSIS
    Format JSON on the OS clipboard with jq.
    If the clipboard is not valid JSON, leave it unchanged (do not overwrite with empty text).
    #>
    $jqExe = Get-JqExe
    if (-not $jqExe) {
        Write-Error 'jq.exe not found. Confirm jqlang.jq is installed and PATH includes its folder.'
        return
    }

    $original = Get-Clipboard -Raw -ErrorAction SilentlyContinue
    if ([string]::IsNullOrWhiteSpace($original)) {
        Write-Host 'Clipboard is empty.'
        return
    }

    $utf8 = New-Object System.Text.UTF8Encoding $false
    $tmpIn = [System.IO.Path]::GetTempFileName()
    $tmpOut = [System.IO.Path]::GetTempFileName()
    $tmpErr = [System.IO.Path]::GetTempFileName()
    try {
        [System.IO.File]::WriteAllText($tmpIn, $original, $utf8)
        $p = Start-Process -FilePath $jqExe -ArgumentList @('.', $tmpIn) -Wait -PassThru -NoNewWindow -RedirectStandardOutput $tmpOut -RedirectStandardError $tmpErr
        if ($p.ExitCode -eq 0) {
            $formatted = [System.IO.File]::ReadAllText($tmpOut, $utf8)
            Set-Clipboard -Value $formatted
            Write-Host 'Clipboard JSON formatted.'
        } else {
            $err = [System.IO.File]::ReadAllText($tmpErr, $utf8).Trim()
            if ($err) { Write-Warning $err }
            Write-Host 'Clipboard is not valid JSON; left unchanged.'
        }
    } finally {
        Remove-Item -LiteralPath $tmpIn, $tmpOut, $tmpErr -Force -ErrorAction SilentlyContinue
    }
}