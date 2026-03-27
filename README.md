# Images to Compressed PDF — Raycast Scripts

Raycast script commands that turn selected images (JPG, PNG, WEBP) into a single compressed PDF on macOS.

## Scripts

| File | Use with |
|------|----------|
| `images-to-compressed-pdf.sh` | **Finder** |
| `images-to-compressed-pdf-pathfinder.sh` | **Path Finder** |

Both scripts share the same pipeline: ImageMagick builds a PDF from the selection, then Ghostscript recompresses it. Pick the script that matches the file manager you use.

## Requirements

- macOS
- [Homebrew](https://brew.sh) (recommended for installing CLI tools)

```bash
brew install ghostscript imagemagick
```

The scripts also use `bc` for size and savings math; it is included with macOS by default.

## Installation

1. Open (or create) your Raycast scripts folder:

   ```bash
   cd ~/Library/Application\ Support/Raycast/Scripts/
   ```

2. Copy the script you need (or both):

   ```bash
   cp /path/to/images-to-compressed-pdf.sh ~/Library/Application\ Support/Raycast/Scripts/
   cp /path/to/images-to-compressed-pdf-pathfinder.sh ~/Library/Application\ Support/Raycast/Scripts/
   ```

3. Make them executable:

   ```bash
   chmod +x ~/Library/Application\ Support/Raycast/Scripts/images-to-compressed-pdf.sh
   chmod +x ~/Library/Application\ Support/Raycast/Scripts/images-to-compressed-pdf-pathfinder.sh
   ```

4. Reload scripts in Raycast (for example **⌘R** in Script Commands settings) or restart Raycast.

## Usage

1. In **Finder** or **Path Finder**, select one or more image files (JPG, JPEG, PNG, WEBP).
2. Run the matching Raycast command (**Images to Compressed PDF** or **Images to PDF (Path Finder)**).
3. Optional: choose a compression level in the argument dropdown:
   - **Low (72 DPI)** — smallest files; good for screen and web.
   - **Medium (150 DPI)** — default; balance of quality and size.
   - **High (300 DPI)** — larger files; better for print and sharp documents.

If nothing is selected, the script exits with a short message asking you to select images first.

## Output

The PDF is written next to the first selected image, named:

`images_compressed_YYYYMMDD_HHMMSS.pdf`

A temporary PDF is removed after Ghostscript finishes. Raycast shows approximate final size and, when possible, how much smaller the file is than the pre–Ghostscript PDF.

## Features

- Merges multiple images into one PDF in selection order.
- JPEG compression inside the PDF plus Ghostscript’s PDF optimization (`/screen`, `/ebook`, or `/printer` presets aligned with DPI).
- Three quality presets.
- Supported formats: JPG, JPEG, PNG, WEBP.

## Example

**Input (selected in Finder):**

- `photo1.jpg` (3.2 MB)
- `photo2.png` (2.8 MB)
- `photo3.webp` (1.5 MB)

**Output:**

- `images_compressed_20250107_141532.pdf` (~1.8 MB, with a reported savings percentage vs. the intermediate PDF)

## Tips

- Select every image you want in the PDF; page order follows your selection order in Finder or Path Finder.
- Use **Low** or **Medium** for photos you mainly view on a screen; use **High** for scans or anything you might print.
- **Medium** is a practical default, similar in spirit to a balanced “ebook” style compression.

## How it works (briefly)

- **ImageMagick** (`convert`) assembles images into a PDF with JPEG compression and the chosen density/quality.
- **Ghostscript** (`gs`) rewrites the PDF with downsampling and PDF settings tuned to the same DPI tier.
- **AppleScript** reads the current selection from Finder or Path Finder and passes POSIX paths to the shell script.

## Author

Marcin — [raycast.com](https://raycast.com)Tymków
