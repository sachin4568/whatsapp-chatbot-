$ErrorActionPreference = 'Stop'
$flutterUrl = 'https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.22.0-stable.zip'
$zipPath = "C:\src\flutter_windows.zip"
Write-Host "Downloading Flutter SDK..."
Invoke-WebRequest -Uri $flutterUrl -OutFile $zipPath -UseBasicParsing
Write-Host "Extracting..."
Expand-Archive -Path $zipPath -DestinationPath 'C:\src\flutter' -Force
Write-Host "Cleaning up..."
Remove-Item $zipPath
# Add to PATH for current session
$env:Path = $env:Path + ';C:\src\flutter\bin'
Write-Host "Flutter installed. Version:"
flutter --version
