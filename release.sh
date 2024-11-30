#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to show help
show_help() {
    echo "Usage: $0 -p <platform>"
    echo "Options:"
    echo "  -p <platform>     Platform to build for (linux, windows, macos-intel, macos-arm, all)"
    echo "  -t <type>         Release type (production, beta, alpha) [default: production]"
    echo "  -h                Show this help message"
}

# Function to validate platform
validate_platform() {
    local platform=$1
    case $platform in
        linux|windows|macos-intel|macos-arm|all)
            return 0
            ;;
        *)
            echo -e "${RED}Error: Invalid platform '$platform'${NC}"
            echo "Valid platforms are: linux, windows, macos-intel, macos-arm, all"
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
            echo -e "${RED}Error: Invalid release type '$type'${NC}"
            echo "Valid types are: production, beta, alpha"
            exit 1
            ;;
    esac
}

# Function to get current version from version.txt
get_current_version() {
    if [ ! -f "version.txt" ]; then
        echo "0.0.1"
    else
        cat version.txt | tr -d '\n'
    fi
}

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

# Default values
PLATFORM=""
RELEASE_TYPE="production"

# Parse command line arguments
while getopts "p:t:h" opt; do
    case $opt in
        p)
            PLATFORM=$OPTARG
            validate_platform "$PLATFORM"
            ;;
        t)
            RELEASE_TYPE=$OPTARG
            validate_release_type "$RELEASE_TYPE"
            ;;
        h)
            show_help
            exit 0
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            show_help
            exit 1
            ;;
    esac
done

# Check if platform is provided
if [ -z "$PLATFORM" ]; then
    echo -e "${RED}Error: Platform is required${NC}"
    show_help
    exit 1
fi

# Get current version and calculate new version
CURRENT_VERSION=$(get_current_version)
NEW_VERSION=$(increment_version "$CURRENT_VERSION")

# Update version.txt
echo "$NEW_VERSION" > version.txt
echo -e "${GREEN}Updated version to $NEW_VERSION${NC}"

# Stage and commit version changes
git add version.txt
git commit -m "Release v$NEW_VERSION"
git push origin main

# Create and push tag
echo -e "${YELLOW}Creating git tag v$NEW_VERSION${NC}"
if ! git rev-parse "v$NEW_VERSION" >/dev/null 2>&1; then
    git tag -a "v$NEW_VERSION" -m "Release v$NEW_VERSION
platform: $PLATFORM"
    git push origin "v$NEW_VERSION"
    echo -e "${GREEN}Successfully created and pushed version v$NEW_VERSION${NC}"
else
    echo -e "${YELLOW}Tag v$NEW_VERSION already exists, skipping tag creation${NC}"
fi

echo -e "${GREEN}GitHub Actions workflow will automatically build for platform: $PLATFORM${NC}"

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

# Trigger workflow for the specified platform
trigger_workflow "$PLATFORM"

echo -e "${GREEN}Release process initiated successfully!${NC}"
echo "You can monitor the build status at: https://github.com/$repo_path/actions"
