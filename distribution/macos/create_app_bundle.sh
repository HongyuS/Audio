#!/bin/bash

# Based on:
# https://github.com/Ryujinx/Ryujinx/blob/master/distribution/macos/create_app_bundle.sh
# License: https://github.com/Ryujinx/Ryujinx/blob/master/LICENSE.txt

set -e

PUBLISH_DIRECTORY=$1
OUTPUT_DIRECTORY=$2

APP_BUNDLE_DIRECTORY="$OUTPUT_DIRECTORY/Audio.app"

rm -rf "$APP_BUNDLE_DIRECTORY"
mkdir -p "$APP_BUNDLE_DIRECTORY/Contents"
mkdir "$APP_BUNDLE_DIRECTORY/Contents/Frameworks"
mkdir "$APP_BUNDLE_DIRECTORY/Contents/MacOS"
mkdir "$APP_BUNDLE_DIRECTORY/Contents/Resources"

# Copy executables first
cp "$PUBLISH_DIRECTORY/Audio.Desktop" "$APP_BUNDLE_DIRECTORY/Contents/MacOS/Audio"
chmod u+x "$APP_BUNDLE_DIRECTORY/Contents/MacOS/Audio"

# Then all libraries
cp "$PUBLISH_DIRECTORY"/*.dylib "$APP_BUNDLE_DIRECTORY/Contents/Frameworks"

# Then resources
cp Info.plist "$APP_BUNDLE_DIRECTORY/Contents"
cp Icon.icns "$APP_BUNDLE_DIRECTORY/Contents/Resources/Icon.icns"

echo -n "APPL????" > "$APP_BUNDLE_DIRECTORY/Contents/PkgInfo"

# Fixup libraries and executable
python3 bundle_fix_up.py "$APP_BUNDLE_DIRECTORY" MacOS/Audio

# Now sign it
if [ -x "$(command -v codesign)" ];
then
    echo "Usign codesign for ad-hoc signing"
    codesign -f --deep -s - "$APP_BUNDLE_DIRECTORY"
fi
