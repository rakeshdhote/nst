#!/bin/bash

echo "🧹 Cleaning up the project..."

# Clean Next.js build artifacts
echo "📦 Cleaning Next.js build artifacts..."
rm -rf .next
rm -rf out
rm -rf node_modules
rm -f pnpm-lock.yaml
rm -f package-lock.json
rm -f yarn.lock

# Clean Rust build artifacts
echo "🦀 Cleaning Rust build artifacts..."
(
    cd src-tauri || exit 1
    cargo clean
)

# Clean any OS-specific files
echo "🗑️  Cleaning system files..."
find . -type f -name ".DS_Store" -delete
find . -type f -name "Thumbs.db" -delete
find . -type d -name "__pycache__" -exec rm -rf {} +

# Clean environment files if they exist
echo "🔒 Cleaning environment files..."
rm -f .env.local
rm -f .env.development.local
rm -f .env.test.local
rm -f .env.production.local

echo "✨ Cleanup complete!"
echo "To rebuild the project:"
echo "1. Run 'pnpm install' to reinstall Node.js dependencies"
pnpm install
echo "2. Run 'pnpm tauri dev' to start the development environment"
pnpm tauri dev