# Tauri2 Next ShadCn Python Template

A modern cross-platform desktop application template built with Tauri 2.0, Next.js 15, and ShadCn UI components. This template provides a solid foundation for building beautiful, performant, and maintainable desktop applications.

## Table of Contents

- [Tech Stack](#tech-stack)
  - [Frontend](#frontend)
  - [Backend (Python)](#backend-python)
  - [Desktop (Tauri)](#desktop-tauri)
  - [Development Tools](#development-tools)
- [Features](#features)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Development Setup](#development-setup)
- [Building for Production](#building-for-production)
  - [Windows](#windows)
  - [macOS](#macos)
  - [Linux](#linux)
- [Utility Scripts](#utility-scripts)
  - [Release Script](#release-script)
  - [Cleanup Script](#cleanup-script)
  - [Generate Icons Script](#generate-icons-script)
- [Updating Dependencies](#updating-dependencies)
- [API Endpoints](#api-endpoints)
- [Contributing](#contributing)
- [License](#license)

## Tech Stack

### Frontend
- Next.js 15.0.3
- React 19 (RC)
- TailwindCSS 3.4.1
- ShadCn UI Components
- TypeScript 5

### Backend (Python)
- FastAPI 0.109.2
- Uvicorn 0.27.1
- PyInstaller 6.3.0

### Desktop (Tauri)
- Tauri 2.1.0
- Rust (latest stable)

### Development Tools
- pnpm (package manager)
- ESLint
- PostCSS

## Features

- Modern tech stack with Tauri 2.0 and Next.js 15
- Beautiful UI components from ShadCn
- Dark/Light mode support
- Auto-updates support
- Type-safe development with TypeScript
- Efficient package management with pnpm
- Cross-platform support (Windows, macOS, Linux)

## Project Structure

```
nst/
├── app/                    # Next.js pages and routing
├── backend/               # Backend services
│   └── python/           # Python FastAPI backend
│       ├── server.py     # FastAPI server implementation
│       ├── requirements.txt  # Python dependencies
│       └── build_binary.sh   # Script to build Python executable
├── components/            # React components
├── hooks/                # Custom React hooks
├── lib/                  # Utility functions and shared code
├── public/               # Static assets
├── src-tauri/           # Tauri/Rust backend code
│   └── binaries/        # Compiled Python backend
├── scripts/             # Build and utility scripts
├── styles/              # Global styles and Tailwind config
└── [build outputs]      # Platform-specific build outputs
```

## Prerequisites

- Node.js 18 or later
- Rust (latest stable)
- pnpm
- Python 3.10 or later
- Platform-specific dependencies:
  - **Windows**: Visual Studio Build Tools, WebView2
  - **macOS**: Xcode Command Line Tools
  - **Linux**: `build-essential`, `libwebkit2gtk-4.0-dev`, `curl`, `wget`, `libssl-dev`, `libgtk-3-dev`, `libayatana-appindicator3-dev`, `librsvg2-dev`

## Development Setup

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd nst
   ```

2. Build Python backend:
   ```bash
   cd backend/python
   ./build_binary.sh
   cd ../..
   ```

3. Install dependencies:
   ```bash
   pnpm install
   ```

4. Start development server:
   ```bash
   pnpm tauri dev
   ```

## Building for Production

### Windows
```bash
pnpm tauri build
```
Outputs:
- `src-tauri/target/release/bundle/msi/` - MSI installer
- `src-tauri/target/release/bundle/nsis/` - NSIS installer
- `src-tauri/target/release/` - Executable

### macOS
```bash
pnpm tauri build
```
Outputs:
- `src-tauri/target/release/bundle/dmg/` - DMG installer
- `src-tauri/target/release/bundle/macos/` - App bundle

### Linux
```bash
pnpm tauri build
```
Outputs:
- `src-tauri/target/release/bundle/deb/` - Debian package
- `src-tauri/target/release/bundle/appimage/` - AppImage
- `src-tauri/target/release/` - Binary

## Utility Scripts

### Release Script
The `release.sh` script automates the release process for different platforms:

```bash
./release.sh -p <platform> -t <type>
```

Options:
- `-p <platform>`: Platform to build for (linux, windows, macos-intel, macos-arm, all)
- `-t <type>`: Release type (production, beta, alpha) [default: production]
- `-h`: Show help message

Features:
- Automated version management
- Platform-specific builds
- GitHub workflow integration
- Release type support (production/beta/alpha)

### Cleanup Script
The `cleanup.sh` script helps maintain a clean development environment:

```bash
./cleanup.sh
```

Actions:
- Removes Next.js build artifacts (.next, out)
- Cleans node_modules and lock files
- Removes Rust build artifacts
- Deletes system-specific files (.DS_Store, Thumbs.db)
- Cleans environment files
- Automatically reinstalls dependencies and starts dev environment

### Generate Icons Script
The `scripts/generate_icons.sh` script creates platform-specific icons from a source image:

```bash
./scripts/generate_icons.sh <path-to-image>
```

Features:
- Generates icons for all supported platforms
- Creates PNG icons in various sizes (32x32, 128x128, etc.)
- Generates Windows ICO file
- Validates input image
- Requires ImageMagick for image processing

Example:
```bash
./scripts/generate_icons.sh my-app-icon.png
```

## API Endpoints

The Python backend provides the following REST endpoints:

- `GET /health` - Health check endpoint
  ```json
  {"status": "healthy", "service": "python-backend"}
  ```

- `GET /hello` - Simple greeting endpoint
  ```json
  {"message": "Hello from Python Backend!"}
  ```

- `GET /random` - Generate random number
  ```json
  {"number": 42}  // Random number between 1 and 100
  ```

## Updating Dependencies

1. Update Node.js dependencies:
   ```bash
   pnpm update
   ```

2. Update Rust dependencies:
   ```bash
   cd src-tauri
   cargo update
   ```

3. Update Python dependencies:
   ```bash
   cd backend/python
   pip install -r requirements.txt
   ```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

Please make sure to:
- Follow the existing code style
- Add tests if applicable
- Update documentation as needed
- Reference any related issues in your PR

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
