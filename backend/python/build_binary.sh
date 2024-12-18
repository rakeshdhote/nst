#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Copy config.json from the root folder to backend/python/config.json
echo -e "${GREEN}Copying config from root folder to backend/python/config.json${NC}"
cp -f ../../config.json ./config.json

# Change to the script's directory
cd "$(dirname "$0")" || exit 1

# Detect platform
PLATFORM="$(uname -s)"
case "${PLATFORM}" in
    Linux*)     PLATFORM_NAME=x86_64-unknown-linux-gnu;;
    Darwin*)    
        if [[ $(uname -m) == 'arm64' ]]; then
            PLATFORM_NAME=aarch64-apple-darwin
        else
            PLATFORM_NAME=x86_64-apple-darwin
        fi
        ;;
    MINGW*|MSYS*)    PLATFORM_NAME=x86_64-pc-windows-msvc;;
    *)          PLATFORM_NAME="UNKNOWN";;
esac

if [ "$PLATFORM_NAME" = "UNKNOWN" ]; then
    echo -e "${RED}Error: Unsupported platform${NC}"
    exit 1
fi

# Create virtual environment if it doesn't exist
if [ ! -d ".venv" ]; then
    echo -e "${GREEN}Creating a Python virtual environment to isolate dependencies...${NC}"
    uv venv .venv 2>&1 | grep -i "error"
fi

# Separator
echo "##############################"

# Activate virtual environment
# shellcheck source=/dev/null
source .venv/bin/activate

# Install requirements quietly, only show errors
echo -e "${GREEN}Installing required Python packages from requirements.txt...${NC}"
uv pip install -r requirements.txt --no-cache 2>&1 | grep -i "error"

# Separator
echo "##############################"

# Define paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TAURI_DIR="$SCRIPT_DIR/../../src-tauri"
RESOURCES_DIR="$TAURI_DIR/resources"
DIST_DIR="$SCRIPT_DIR/dist"

# Create necessary directories
mkdir -p "$RESOURCES_DIR"

# Build binary with PyInstaller, only show errors
echo -e "${GREEN}Building the FastAPI server binary using PyInstaller...${NC}"
pyinstaller --clean --onefile --name my_fastapi_app main.py > /dev/null 2>&1 || {
    echo -e "${RED}Error: PyInstaller failed${NC}"
    exit 1
}

# Separator
echo "##############################"

# Copy the binary to Tauri resources directory with platform-specific name
if [ -f "$DIST_DIR/my_fastapi_app" ]; then
    cp -f "$DIST_DIR/my_fastapi_app" "$RESOURCES_DIR/my_fastapi_app"
    cp -f "./config.json" "$RESOURCES_DIR/config.json"
    chmod +x "$RESOURCES_DIR/my_fastapi_app"
    echo -e "${GREEN}Successfully copied the binary to: $(realpath "$RESOURCES_DIR/my_fastapi_app")${NC}"
elif [ -f "$DIST_DIR/my_fastapi_app.exe" ]; then
    cp "$DIST_DIR/my_fastapi_app.exe" "$RESOURCES_DIR/my_fastapi_app.exe"
    echo -e "${GREEN}Successfully copied the binary to: $(realpath "$RESOURCES_DIR/my_fastapi_app.exe")${NC}"
else
    echo -e "${RED}Error: The expected binary was not found in the distribution directory. Please check the build process.${NC}"
    exit 1
fi

# Separator
echo "##############################"

# Create a .gitkeep file in resources to ensure the directory is not empty
touch "$RESOURCES_DIR/.gitkeep"

# Cleanup old binaries in resources
rm -rf "$RESOURCES_DIR/python_backend" "$RESOURCES_DIR/python_backend.exe" 2>/dev/null

# Cleanup
rm -rf build "$DIST_DIR" server.spec 2>/dev/null

# Deactivate virtual environment
deactivate

# Separator
echo "##############################"

echo -e "${GREEN}✓ Build complete${NC}"
