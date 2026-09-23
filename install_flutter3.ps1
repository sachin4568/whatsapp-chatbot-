$ErrorActionPreference = 'Stop'
$flutterUrl = 'https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.22.0-stable.zip'
$zipPath = "e:/chatbot/flutter_windows.zip"
Write-Host "Downloading Flutter SDK..."
Invoke-WebRequest -Uri $flutterUrl -OutFile $zipPath -UseBasicParsing
Write-Host "Extracting..."
Expand-Archive -Path $zipPath -DestinationPath 'e:/chatbot/flutter' -Force
Write-Host "Cleaning up..."
Remove-Item $zipPath
# Add to PATH for current session
$env:Path = $env:Path + ';e:/chatbot/flutter/flutter/bin'
Write-Host "Flutter installed. Version:"
flutter --version
