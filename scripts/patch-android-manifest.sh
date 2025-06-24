#!/bin/bash

# Script to patch Android Manifest after Tauri generation
# This ensures TTS permissions are always included

MANIFEST_PATH="/home/hanl5/coding/alouette/src-tauri/gen/android/app/src/main/AndroidManifest.xml"

if [ -f "$MANIFEST_PATH" ]; then
    echo "🔧 Patching Android Manifest for TTS permissions..."
    
    # Check if RECORD_AUDIO permission already exists
    if ! grep -q "android.permission.RECORD_AUDIO" "$MANIFEST_PATH"; then
        echo "📱 Adding TTS permissions to AndroidManifest.xml"
        
        # Create backup
        cp "$MANIFEST_PATH" "$MANIFEST_PATH.backup"
        
        # Add permissions after the first line
        sed -i '2i\    <uses-permission android:name="android.permission.RECORD_AUDIO" />' "$MANIFEST_PATH"
        sed -i '3i\    <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />' "$MANIFEST_PATH"
        sed -i '4i\    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />' "$MANIFEST_PATH"
        sed -i '5i\    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />' "$MANIFEST_PATH"
        
        echo "✅ TTS permissions added successfully"
    else
        echo "✅ TTS permissions already present"
    fi
else
    echo "⚠️  Android Manifest not found at $MANIFEST_PATH"
    echo "   Make sure to run 'npm run tauri android init' first"
    exit 1
fi
