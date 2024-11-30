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

# Stage version.txt
git add "$VERSION_FILE"

# Commit changes
git commit -m "$commit_message"

# Create and push tag
git tag -a "$new_tag" -m "Version $new_version"
git push origin main --tags

echo "Successfully created and pushed version $new_tag"
echo "GitHub Actions workflow will start automatically"
