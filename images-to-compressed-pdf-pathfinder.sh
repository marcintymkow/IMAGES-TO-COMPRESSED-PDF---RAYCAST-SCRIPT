#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Images to PDF (Path Finder)
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 🖼️
# @raycast.argument1 { "type": "dropdown", "placeholder": "Level", "optional": true, "data": [{"title": "Medium (150 DPI)", "value": "medium"}, {"title": "Low (72 DPI)", "value": "low"}, {"title": "High (300 DPI)", "value": "high"}] }
# @raycast.packageName PDF Tools

# Documentation:
# @raycast.description Convert images (JPG, PNG, WEBP) to compressed PDF (Path Finder)
# @raycast.author Marcin
# @raycast.authorURL https://raycast.com

# Compression level (default: medium)
LEVEL="${1:-medium}"

# Check if required tools are installed
if ! command -v gs &> /dev/null; then
    echo "Install Ghostscript: brew install ghostscript"
    exit 1
fi

if ! command -v convert &> /dev/null; then
    echo "Install ImageMagick: brew install imagemagick"
    exit 1
fi

# Get selected files from Path Finder
FILES=$(osascript << 'APPLESCRIPT'
tell application "Path Finder"
    set selectedItems to selection
    if (count of selectedItems) is 0 then
        return ""
    end if
    set filePaths to {}
    repeat with anItem in selectedItems
        set end of filePaths to POSIX path of anItem
    end repeat
    set oldDelimiters to AppleScript's text item delimiters
    set AppleScript's text item delimiters to linefeed
    set pathString to filePaths as text
    set AppleScript's text item delimiters to oldDelimiters
    return pathString
end tell
APPLESCRIPT
)

if [ -z "$FILES" ]; then
    echo "Select image files in Path Finder"
    exit 1
fi

# Settings based on compression level
case "$LEVEL" in
    "low")
        DPI=72
        QUALITY="/screen"
        IMG_QUALITY=70
        ;;
    "medium")
        DPI=150
        QUALITY="/ebook"
        IMG_QUALITY=85
        ;;
    "high")
        DPI=300
        QUALITY="/printer"
        IMG_QUALITY=95
        ;;
    *)
        DPI=150
        QUALITY="/ebook"
        IMG_QUALITY=85
        ;;
esac

# Collect valid image files
IMAGE_FILES=()
while IFS= read -r file; do
    [ -z "$file" ] && continue
    
    EXT="${file##*.}"
    EXT_LOWER=$(echo "$EXT" | awk '{print tolower($0)}')
    
    case "$EXT_LOWER" in
        jpg|jpeg|png|webp)
            IMAGE_FILES+=("$file")
            ;;
    esac
done <<< "$FILES"

if [ ${#IMAGE_FILES[@]} -eq 0 ]; then
    echo "No image files found (JPG, PNG, WEBP)"
    exit 1
fi

# Get output directory from first file
FIRST_FILE="${IMAGE_FILES[0]}"
OUTPUT_DIR=$(dirname "$FIRST_FILE")
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
TEMP_PDF="$OUTPUT_DIR/temp_${TIMESTAMP}.pdf"
OUTPUT_PDF="$OUTPUT_DIR/images_compressed_${TIMESTAMP}.pdf"

# Step 1: Convert images to PDF
echo "Converting ${#IMAGE_FILES[@]} image(s) to PDF..."

# Convert images to PDF using ImageMagick
convert "${IMAGE_FILES[@]}" \
    -quality "$IMG_QUALITY" \
    -density "$DPI" \
    -compress jpeg \
    "$TEMP_PDF" 2>/dev/null

if [ ! -f "$TEMP_PDF" ]; then
    echo "Failed to create PDF from images"
    exit 1
fi

SIZE_BEFORE=$(stat -f%z "$TEMP_PDF" 2>/dev/null || echo 0)

# Step 2: Compress PDF using Ghostscript
echo "Compressing PDF..."

gs -sDEVICE=pdfwrite \
   -dCompatibilityLevel=1.5 \
   -dPDFSETTINGS="$QUALITY" \
   -dNOPAUSE \
   -dQUIET \
   -dBATCH \
   -dCompressFonts=true \
   -dSubsetFonts=true \
   -dEmbedAllFonts=true \
   -dColorImageDownsampleType=/Bicubic \
   -dColorImageResolution="$DPI" \
   -dGrayImageDownsampleType=/Bicubic \
   -dGrayImageResolution="$DPI" \
   -dMonoImageDownsampleType=/Subsample \
   -dMonoImageResolution="$DPI" \
   -dDownsampleColorImages=true \
   -dDownsampleGrayImages=true \
   -dDownsampleMonoImages=true \
   -dAutoRotatePages=/None \
   -dDetectDuplicateImages=true \
   -sOutputFile="$OUTPUT_PDF" \
   "$TEMP_PDF" 2>/dev/null

# Remove temporary file
rm "$TEMP_PDF"

if [ -f "$OUTPUT_PDF" ]; then
    SIZE_AFTER=$(stat -f%z "$OUTPUT_PDF" 2>/dev/null || echo 0)
    
    # Format file sizes
    if [ $SIZE_AFTER -gt 1048576 ]; then
        SIZE_FMT="$(echo "scale=1; $SIZE_AFTER/1048576" | bc)MB"
    elif [ $SIZE_AFTER -gt 1024 ]; then
        SIZE_FMT="$(echo "scale=1; $SIZE_AFTER/1024" | bc)KB"
    else
        SIZE_FMT="${SIZE_AFTER}B"
    fi
    
    # Calculate compression ratio
    if [ $SIZE_BEFORE -gt 0 ]; then
        SAVED=$((SIZE_BEFORE - SIZE_AFTER))
        RATIO=$(echo "scale=1; ($SAVED * 100) / $SIZE_BEFORE" | bc)
        echo "Created compressed PDF: $(basename "$OUTPUT_PDF") (~$SIZE_FMT, saved ${RATIO}%)"
    else
        echo "Created PDF: $(basename "$OUTPUT_PDF") (~$SIZE_FMT)"
    fi
else
    echo "Failed to compress PDF"
    exit 1
fi
