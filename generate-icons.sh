#!/bin/bash

# Create all required icon sizes for Alouette
cd /home/hanl5/coding/alouette

# Source SVG file
SVG_FILE="alouette-glass-v2.svg"
ICONS_DIR="src-tauri/icons"

# Create a temporary high-resolution base image
rsvg-convert -w 1024 -h 1024 "$SVG_FILE" > temp-base.png

# PNG icons for various sizes
convert temp-base.png -resize 32x32 "$ICONS_DIR/32x32.png"
convert temp-base.png -resize 128x128 "$ICONS_DIR/128x128.png"
convert temp-base.png -resize 256x256 "$ICONS_DIR/128x128@2x.png"
convert temp-base.png -resize 512x512 "$ICONS_DIR/icon.png"

# Windows ICO file (multi-resolution)
convert temp-base.png \
    \( -clone 0 -resize 16x16 \) \
    \( -clone 0 -resize 32x32 \) \
    \( -clone 0 -resize 48x48 \) \
    \( -clone 0 -resize 64x64 \) \
    \( -clone 0 -resize 128x128 \) \
    \( -clone 0 -resize 256x256 \) \
    -delete 0 "$ICONS_DIR/icon.ico"

# macOS ICNS file (requires iconutil on macOS, using convert as fallback)
convert temp-base.png -resize 512x512 "$ICONS_DIR/icon.icns"

# Windows Store logos (Square format)
convert temp-base.png -resize 30x30 "$ICONS_DIR/Square30x30Logo.png"
convert temp-base.png -resize 44x44 "$ICONS_DIR/Square44x44Logo.png"
convert temp-base.png -resize 71x71 "$ICONS_DIR/Square71x71Logo.png"
convert temp-base.png -resize 89x89 "$ICONS_DIR/Square89x89Logo.png"
convert temp-base.png -resize 107x107 "$ICONS_DIR/Square107x107Logo.png"
convert temp-base.png -resize 142x142 "$ICONS_DIR/Square142x142Logo.png"
convert temp-base.png -resize 150x150 "$ICONS_DIR/Square150x150Logo.png"
convert temp-base.png -resize 284x284 "$ICONS_DIR/Square284x284Logo.png"
convert temp-base.png -resize 310x310 "$ICONS_DIR/Square310x310Logo.png"
convert temp-base.png -resize 50x50 "$ICONS_DIR/StoreLogo.png"

# Clean up temporary files
rm temp-base.png

echo "All icons generated successfully!"
