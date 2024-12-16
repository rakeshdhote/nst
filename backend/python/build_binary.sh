#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

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
    echo -e "${GREEN}Creating virtual environment...${NC}"
    uv venv .venv 2>&1 | grep -i "error"
fi

# Activate virtual environment
# shellcheck source=/dev/null
source .venv/bin/activate

# Install requirements quietly, only show errors
echo -e "${GREEN}Installing dependencies...${NC}"
uv pip install -r requirements.txt --no-cache 2>&1 | grep -i "error"

# Define paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TAURI_DIR="$SCRIPT_DIR/../../src-tauri"
RESOURCES_DIR="$TAURI_DIR/resources"
DIST_DIR="$SCRIPT_DIR/dist"

# Create necessary directories
mkdir -p "$RESOURCES_DIR"

# Build binary with PyInstaller, only show errors
echo -e "${GREEN}Building binary...${NC}"
pyinstaller --clean --onefile --name fastapi_server server.py > /dev/null 2>&1 || {
    echo -e "${RED}Error: PyInstaller failed${NC}"
    exit 1
}

# Copy the binary to Tauri resources directory with platform-specific name
if [ -f "$DIST_DIR/fastapi_server" ]; then
    # Copy to resources directory with platform-specific name
    cp "$DIST_DIR/fastapi_server" "$RESOURCES_DIR/fastapi_server"
    chmod +x "$RESOURCES_DIR/fastapi_server"
    echo -e "${GREEN}Binary copied to: $(realpath "$RESOURCES_DIR/fastapi_server")${NC}"
elif [ -f "$DIST_DIR/fastapi_server.exe" ]; then
    # Copy to resources directory with platform-specific name
    cp "$DIST_DIR/fastapi_server.exe" "$RESOURCES_DIR/fastapi_server.exe"
    echo -e "${GREEN}Binary copied to: $(realpath "$RESOURCES_DIR/fastapi_server.exe")${NC}"
else
    echo -e "${RED}Error: Binary not found in dist directory${NC}"
    exit 1
fi

echo -e "${GREEN}Build completed successfully!${NC}"

# Create a .gitkeep file in resources to ensure the directory is not empty
touch "$RESOURCES_DIR/.gitkeep"

# Cleanup old binaries in resources
rm -rf "$RESOURCES_DIR/python_backend" "$RESOURCES_DIR/python_backend.exe" 2>/dev/null

# Cleanup
rm -rf build "$DIST_DIR" server.spec 2>/dev/null

# Deactivate virtual environment
deactivate

echo -e "${GREEN}✓ Build complete${NC}"
