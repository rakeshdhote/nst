$ErrorActionPreference = "Stop"

Write-Host "Installing Python dependencies..."
pip install -r backend/python/requirements.txt
pip install pyinstaller

Write-Host "Building Python executable..."
if ($IsMacOS) {
    pyinstaller --onefile --name fastapi_server backend/python/main.py
    $executableName = "fastapi_server"
} elseif ($IsWindows) {
    pyinstaller --onefile --name fastapi_server backend/python/main.py
    $executableName = "fastapi_server.exe"
} else {
    pyinstaller --onefile --name fastapi_server backend/python/main.py
    $executableName = "fastapi_server"
}

Write-Host "Creating resources directory..."
New-Item -Path "src-tauri/resources" -ItemType Directory -Force

Write-Host "Copying Python executable to resources..."
$sourcePath = Join-Path "dist" $executableName
if (Test-Path $sourcePath) {
    Copy-Item $sourcePath -Destination "src-tauri/resources/" -Force
    Write-Host "Python executable copied successfully!"
} else {
    Write-Error "Could not find Python executable at path: $sourcePath"
    exit 1
}

Write-Host "Python build completed successfully!"
