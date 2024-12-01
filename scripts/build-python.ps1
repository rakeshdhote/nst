$ErrorActionPreference = "Stop"

Write-Host "Installing Python dependencies..."
pip install -r backend/python/requirements.txt
pip install pyinstaller

Write-Host "Building Python executable..."
pyinstaller --onefile --name fastapi_server backend/python/main.py

Write-Host "Creating resources directory..."
New-Item -Path "src-tauri/resources" -ItemType Directory -Force

Write-Host "Copying Python executable to resources..."
Copy-Item "dist/fastapi_server.exe" -Destination "src-tauri/resources/" -Force

Write-Host "Python build completed successfully!"
