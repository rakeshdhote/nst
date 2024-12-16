#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🧹 Cleaning up the project...${NC}"

# Clean Next.js build artifacts
echo -e "${YELLOW}📦 Cleaning Next.js build artifacts...${NC}"
rm -rf .next
rm -rf out
rm -rf node_modules
rm -f pnpm-lock.yaml
rm -f package-lock.json
rm -f yarn.lock

# Clean Rust/Tauri build artifacts
echo -e "${YELLOW}🦀 Cleaning Rust/Tauri build artifacts...${NC}"
rm -rf src-tauri/target
rm -rf src-tauri/resources/*
rm -rf src-tauri/binaries/*
rm -rf src-tauri/WixTools
(
    cd src-tauri || exit 1
    cargo clean
)

# Clean Python backend artifacts
echo -e "${YELLOW}🐍 Cleaning Python backend artifacts...${NC}"
(
    cd backend/python || exit 1
    rm -rf venv
    rm -rf build
    rm -rf dist
    rm -rf __pycache__
    rm -f -- *.spec
    rm -f .coverage
    rm -rf htmlcov
    rm -rf .pytest_cache
)

# Clean any OS-specific files
echo -e "${YELLOW}🗑️  Cleaning system files...${NC}"
find . -type f -name ".DS_Store" -delete
find . -type f -name "Thumbs.db" -delete
find . -type f -name "desktop.ini" -delete
find . -type d -name "__pycache__" -exec rm -rf {} +
find . -type f -name "*.pyc" -delete
find . -type f -name "*.pyo" -delete
find . -type f -name "*.pyd" -delete

# Clean IDE and editor files
echo -e "${YELLOW}💻 Cleaning IDE and editor files...${NC}"
rm -rf .idea
rm -rf .vscode
rm -f -- *.swp
rm -f -- *.swo

# Clean environment files if they exist
echo -e "${YELLOW}🔒 Cleaning environment files...${NC}"
rm -f .env
rm -f .env.local
rm -f .env.development
rm -f .env.development.local
rm -f .env.test
rm -f .env.test.local
rm -f .env.production
rm -f .env.production.local

# Clean cache directories
echo -e "${YELLOW}📁 Cleaning cache directories...${NC}"
rm -rf .cache
rm -rf .temp
rm -rf .tmp

# Clean pnpm directory
echo -e "${YELLOW}📦 Cleaning pnpm directory...${NC}"
rm -rf .pnpm

echo -e "${GREEN}✨ Cleanup complete!${NC}"
echo -e "${BLUE}To rebuild the project:${NC}"
echo -e "1. Run ${YELLOW}pnpm install${NC} to reinstall Node.js dependencies"
pnpm install
echo -e "2. Run ${YELLOW}pnpm tauri dev${NC} to start the development environment"
pnpm tauri-dev