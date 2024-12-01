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
if [ ! -d "venv" ]; then
    python3 -m venv venv 2>&1 | grep -i "error"
fi

# Activate virtual environment
# shellcheck source=/dev/null
source venv/bin/activate

# Install requirements quietly, only show errors
echo -e "${GREEN}Installing dependencies...${NC}"
pip install -r requirements.txt -q 2>&1 | grep -i "error"

# Define paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TAURI_DIR="$SCRIPT_DIR/../../src-tauri"
RESOURCES_DIR="$TAURI_DIR/resources"
DIST_DIR="$SCRIPT_DIR/dist"
TARGET_DEBUG_DIR="$TAURI_DIR/target/debug"
BINARIES_DIR="$TAURI_DIR/binaries"

# Create necessary directories
mkdir -p "$TARGET_DEBUG_DIR"
mkdir -p "$BINARIES_DIR"
mkdir -p "$RESOURCES_DIR"

# Build binary with PyInstaller, only show errors
echo -e "${GREEN}Building binary...${NC}"
pyinstaller --clean --onefile server.py > /dev/null 2>&1 || {
    echo -e "${RED}Error: PyInstaller failed${NC}"
    exit 1
}

# Copy the binary to Tauri resources directory with platform-specific name
if [ -f "$DIST_DIR/server" ]; then
    # Copy to target/debug directory
    cp "$DIST_DIR/server" "$TARGET_DEBUG_DIR/python_backend"
    chmod +x "$TARGET_DEBUG_DIR/python_backend"
    echo -e "${GREEN}Binary copied to: $TARGET_DEBUG_DIR/python_backend${NC}"
    
    # Copy to binaries directory with platform-specific name
    cp "$DIST_DIR/server" "$BINARIES_DIR/python_backend-${PLATFORM_NAME}"
    chmod +x "$BINARIES_DIR/python_backend-${PLATFORM_NAME}"
    echo -e "${GREEN}Binary copied to: $BINARIES_DIR/python_backend-${PLATFORM_NAME}${NC}"
    
    # Copy to resources directory
    cp "$DIST_DIR/server" "$RESOURCES_DIR/python_backend"
    chmod +x "$RESOURCES_DIR/python_backend"
    echo -e "${GREEN}Binary copied to: $RESOURCES_DIR/python_backend${NC}"
elif [ -f "$DIST_DIR/server.exe" ]; then
    # Copy to target/debug directory
    cp "$DIST_DIR/server.exe" "$TARGET_DEBUG_DIR/python_backend.exe"
    echo -e "${GREEN}Binary copied to: $TARGET_DEBUG_DIR/python_backend.exe${NC}"
    
    # Copy to binaries directory with platform-specific name
    cp "$DIST_DIR/server.exe" "$BINARIES_DIR/python_backend-${PLATFORM_NAME}.exe"
    echo -e "${GREEN}Binary copied to: $BINARIES_DIR/python_backend-${PLATFORM_NAME}.exe${NC}"
    
    # Copy to resources directory
    cp "$DIST_DIR/server.exe" "$RESOURCES_DIR/python_backend.exe"
    echo -e "${GREEN}Binary copied to: $RESOURCES_DIR/python_backend.exe${NC}"
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
