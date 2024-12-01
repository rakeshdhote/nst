#!/bin/bash

# Check if an image file is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <path-to-image>"
    echo "Example: $0 my-icon.png"
    exit 1
fi

# Check if the input file exists
if [ ! -f "$1" ]; then
    echo "Error: Image file '$1' not found"
    exit 1
fi

# Check if ImageMagick is installed
if ! command -v convert &> /dev/null; then
    echo "Error: ImageMagick is not installed. Please install it first:"
    echo "sudo apt-get update && sudo apt-get install imagemagick"
    exit 1
fi

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ICONS_DIR="$PROJECT_ROOT/src-tauri/icons"
TEMP_DIR="$ICONS_DIR/temp"

# Create icons directory if it doesn't exist
mkdir -p "$ICONS_DIR"
mkdir -p "$TEMP_DIR"

# Copy original image to temp directory
cp "$1" "$TEMP_DIR/app-icon.png"
echo "Copied original image as app-icon.png"

# Function to get image dimensions
get_image_dimensions() {
    local file="$1"
    identify -format "%wx%h" "$file" 2>/dev/null || echo "unknown"
}

# Function to get image format
get_image_format() {
    local file="$1"
    identify -format "%m" "$file" 2>/dev/null || echo "unknown"
}

# Function to update PNG icons
update_png_icons() {
    local input_file="$1"
    local output_dir="$2"
    
    echo "Updating PNG icons..."
    
    # Array of required sizes
    local sizes=(32 128)
    
    for size in "${sizes[@]}"; do
        local output_file="$output_dir/${size}x${size}.png"
        # Force RGBA format with transparency
        if convert "$input_file" \
            -resize "${size}x${size}" \
            -background none \
            -alpha set \
            -channel RGBA \
            -depth 8 \
            PNG32:"$output_file"; then
            # Verify the format
            format=$(identify -format "%[channels]" "$output_file")
            if [[ "$format" == *"rgba"* ]]; then
                echo "✓ Generated ${size}x${size}.png (RGBA verified)"
            else
                echo "❌ Failed: ${size}x${size}.png is not in RGBA format"
                exit 1
            fi
        else
            echo "❌ Failed to generate ${size}x${size}.png"
            exit 1
        fi
    done
}

# Function to update ICO file
update_ico() {
    local input_file="$1"
    local output_dir="$2"
    local ico_file="$output_dir/icon.ico"
    
    echo "Updating ICO file..."
    
    # Create ICO with multiple sizes, ensuring RGBA format for each size
    convert "$input_file" \
        \( -clone 0 -resize 16x16 -background none -alpha set -channel RGBA -depth 8 \) \
        \( -clone 0 -resize 32x32 -background none -alpha set -channel RGBA -depth 8 \) \
        \( -clone 0 -resize 48x48 -background none -alpha set -channel RGBA -depth 8 \) \
        \( -clone 0 -resize 256x256 -background none -alpha set -channel RGBA -depth 8 \) \
        -delete 0 "$ico_file"
    
    if [ $? -eq 0 ]; then
        echo "✓ Generated icon.ico"
    else
        echo "❌ Failed to generate icon.ico"
        exit 1
    fi
}

# Function to clean up temporary files
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
        echo "Cleaned up temporary files"
    fi
}

# Set trap to clean up on script exit
trap cleanup EXIT

# Generate icons
echo "Updating icons..."
update_png_icons "$TEMP_DIR/app-icon.png" "$ICONS_DIR"
update_ico "$TEMP_DIR/app-icon.png" "$ICONS_DIR"

# # Update tauri.conf.json
# TAURI_CONF="$PROJECT_ROOT/src-tauri/tauri.conf.json"
# if [ -f "$TAURI_CONF" ]; then
#     # Create a temporary file
#     TEMP_FILE=$(mktemp)
    
#     # Use jq to update the icon configuration if jq is available
#     if command -v jq &> /dev/null; then
#         # Get list of PNG files
#         PNG_FILES=$(find "$ICONS_DIR" -maxdepth 1 -type f -name "*.png" -exec basename {} \; | sort | sed 's/^/      "icons\//' | sed 's/$/",/' | tr '\n' ' ' | sed 's/, $//')
        
#         # Create JSON array with actual files
#         jq --arg png_files "$PNG_FILES" '
#         .bundle.icon = [
#           ($png_files | split(" ")),
#           "icons/icon.ico"
#         ] | flatten
#         ' "$TAURI_CONF" > "$TEMP_FILE"
#     else
#         # Fallback to sed if jq is not available
#         PNG_FILES=$(find "$ICONS_DIR" -maxdepth 1 -type f -name "*.png" -exec basename {} \; | sort | sed 's/^/      "icons\//' | sed 's/$/",/' | tr '\n' ' ')
#         sed -e '/"icon":/,/]/c\
#     "icon": [\
# '"$PNG_FILES"'\
#       "icons/icon.ico"\
#     ]' "$TAURI_CONF" > "$TEMP_FILE"
#     fi
    
#     # Replace the original file
#     mv "$TEMP_FILE" "$TAURI_CONF"
#     echo "Updated tauri.conf.json with icon paths"
# fi

echo -e "\nIcon update completed successfully!"
echo "Icons have been saved to: $ICONS_DIR"
echo -e "\nUpdated files:"
ls -l "$ICONS_DIR"
