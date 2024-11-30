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

# Get the latest tag
latest_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
latest_version=${latest_tag#v}  # Remove 'v' prefix

# Calculate new version
new_version=$(increment_version $latest_version)
new_tag="v$new_version"

# Ask for commit message
echo "Enter commit message:"
read commit_msg

if [ -z "$commit_msg" ]; then
    echo "Commit message cannot be empty"
    exit 1
fi

# Update version in package.json
sed -i "s/\"version\": \".*\"/\"version\": \"$new_version\"/" package.json
sed -i "s/\"version\": \".*\"/\"version\": \"$new_version\"/" src-tauri/tauri.conf.json

# Stage, commit and push
git add .
git commit -m "$commit_msg"
git push origin main

# Create and push new tag
echo "Creating new tag: $new_tag"
git tag $new_tag
git push origin $new_tag

echo "Successfully created and pushed version $new_tag"
echo "GitHub Actions workflow will start automatically"
