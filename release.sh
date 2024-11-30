#!/bin/bash

# Function to increment version
increment_version() {
    local version=$1
    # Extract components
    local major=0  # Keep major version as 0
    local minor=$(echo $version | cut -d. -f2)
    local patch=$(echo $version | cut -d. -f3)

    # Increment patch version
    patch=$((patch + 1))
    
    # If patch reaches 100, increment minor and reset patch
    if [ $patch -eq 100 ]; then
        minor=$((minor + 1))
        patch=0
    fi

    echo "0.$minor.$patch"
}

# Version file path
VERSION_FILE="version.txt"

# Create version file if it doesn't exist
if [ ! -f "$VERSION_FILE" ]; then
    echo "0.0.1" > "$VERSION_FILE"
fi

# Read current version from file
current_version=$(cat "$VERSION_FILE")

# Calculate new version
new_version=$(increment_version "$current_version")

# Update version file
echo "$new_version" > "$VERSION_FILE"

# Create new tag
new_tag="v$new_version"

# Check if tag already exists
if git rev-parse "$new_tag" >/dev/null 2>&1; then
    echo "Error: Tag $new_tag already exists"
    exit 1
fi

# Ask for commit message
read -p "Enter commit message (default: Release $new_tag): " commit_message
commit_message=${commit_message:-"Release $new_tag"}

# Stage all changes
git add .

# Stage version.txt
git add "$VERSION_FILE"

# Commit changes
git commit -m "$commit_message"

# Create and push tag
git tag -a "$new_tag" -m "Version $new_version"
git push origin main --tags

echo "Successfully created and pushed version $new_tag"
echo "To trigger a GitHub release build:"
echo "1. Go to GitHub Actions"
echo "2. Select 'Release' workflow"
echo "3. Click 'Run workflow'"
echo "4. Select the platform you want to build for"
echo "5. Click 'Run workflow' to start the build"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Read current version
VERSION=$(cat version.txt | tr -d '\n')

# Function to display help message
show_help() {
    echo -e "${GREEN}NST Release Script${NC}"
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -p, --platform     Platform to build for (linux, windows, macos-intel, macos-arm, all)"
    echo "  -v, --version      Version to release (current: $VERSION)"
    echo "  -t, --type         Release type (production, beta, alpha)"
    echo "  -h, --help         Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --platform linux --version 1.0.0"
    echo "  $0 -p windows -v 1.0.1 -t beta"
    echo "  $0 -p all -v 1.0.2 -t production"
}

# Function to validate version format
validate_version() {
    local version=$1
    if [[ ! $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo -e "${RED}Error: Invalid version format. Must be in format X.Y.Z${NC}"
        exit 1
    fi
}

# Function to validate platform
validate_platform() {
    local platform=$1
    case $platform in
        linux|windows|macos-intel|macos-arm|all)
            return 0
            ;;
        *)
            echo -e "${RED}Error: Invalid platform. Must be one of: linux, windows, macos-intel, macos-arm, all${NC}"
            exit 1
            ;;
    esac
}

# Function to validate release type
validate_release_type() {
    local type=$1
    case $type in
        production|beta|alpha)
            return 0
            ;;
        *)
            echo -e "${RED}Error: Invalid release type. Must be one of: production, beta, alpha${NC}"
            exit 1
            ;;
    esac
}

# Default values
PLATFORM=""
NEW_VERSION=""
RELEASE_TYPE="production"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--platform)
            PLATFORM="$2"
            shift 2
            ;;
        -v|--version)
            NEW_VERSION="$2"
            shift 2
            ;;
        -t|--type)
            RELEASE_TYPE="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}Error: Unknown option $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# Validate required arguments
if [ -z "$PLATFORM" ]; then
    echo -e "${RED}Error: Platform is required${NC}"
    show_help
    exit 1
fi

# Validate platform
validate_platform "$PLATFORM"

# Validate release type
validate_release_type "$RELEASE_TYPE"

# If version is provided, validate and update version.txt
if [ ! -z "$NEW_VERSION" ]; then
    validate_version "$NEW_VERSION"
    echo "$NEW_VERSION" > version.txt
    echo -e "${GREEN}Updated version to $NEW_VERSION${NC}"
fi

# Ensure we're in the root directory of the project
if [ ! -f "version.txt" ]; then
    echo -e "${RED}Error: Must be run from project root directory${NC}"
    exit 1
fi

# Read the current version again (in case it was updated)
VERSION=$(cat version.txt | tr -d '\n')

# Function to trigger GitHub workflow
trigger_workflow() {
    local platform=$1
    
    echo -e "${YELLOW}Triggering release workflow for platform: $platform${NC}"
    
    # Construct the workflow dispatch payload
    local payload="{\"ref\":\"main\",\"inputs\":{\"platform\":\"$platform\",\"release_type\":\"$RELEASE_TYPE\",\"create_release\":\"true\"}}"
    
    # Get the repository information from git config
    local remote_url=$(git config --get remote.origin.url)
    local repo_path=$(echo $remote_url | sed 's/.*github.com[:/]\(.*\).git/\1/')
    
    # Check if GITHUB_TOKEN is set
    if [ -z "$GITHUB_TOKEN" ]; then
        echo -e "${RED}Error: GITHUB_TOKEN environment variable is not set${NC}"
        echo "Please set it with: export GITHUB_TOKEN=your_token"
        exit 1
    fi
    
    # Trigger the workflow
    curl -X POST \
         -H "Accept: application/vnd.github.v3+json" \
         -H "Authorization: token $GITHUB_TOKEN" \
         "https://api.github.com/repos/$repo_path/actions/workflows/release.yml/dispatches" \
         -d "$payload"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Successfully triggered release workflow for $platform${NC}"
    else
        echo -e "${RED}Failed to trigger release workflow for $platform${NC}"
        exit 1
    fi
}

# Create git tag
echo -e "${YELLOW}Creating git tag v$VERSION${NC}"
git tag -a "v$VERSION" -m "Release v$VERSION"
git push origin "v$VERSION"

# Trigger workflows based on platform
if [ "$PLATFORM" = "all" ]; then
    for p in linux windows macos-intel macos-arm; do
        trigger_workflow $p
    done
else
    trigger_workflow $PLATFORM
fi

echo -e "${GREEN}Release process initiated successfully!${NC}"
echo "You can monitor the build status at: https://github.com/$repo_path/actions"
