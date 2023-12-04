#!/bin/bash

# Based on:
# https://github.com/Ryujinx/Ryujinx/blob/master/distribution/macos/create_macos_build_ava.sh
# License: https://github.com/Ryujinx/Ryujinx/blob/master/LICENSE.txt

BASE_DIR="$PWD"    # directory of Audio.sln
TEMP_DIRECTORY="$BASE_DIR/distribution/macos/temp"
OUTPUT_DIRECTORY="$BASE_DIR/distribution/macos/publish"
CONFIGURATION=Release

RELEASE_ZIP_FILE_NAME=raztools-audio-macos-universal.zip

ARM64_APP_BUNDLE="$TEMP_DIRECTORY/output_arm64/Audio.app"
X64_APP_BUNDLE="$TEMP_DIRECTORY/output_x64/Audio.app"
UNIVERSAL_APP_BUNDLE="$OUTPUT_DIRECTORY/Audio.app"
EXECUTABLE_SUB_PATH=Contents/MacOS/Audio

mkdir -p "$TEMP_DIRECTORY"

DOTNET_COMMON_ARGS=(-p:PublishSingleFile=true -p:PublishTrimmed=true -p:DebugType=embedded --self-contained true)

dotnet publish -c "$CONFIGURATION" -r osx-arm64 -t:Audio_Desktop -o "$TEMP_DIRECTORY/publish_arm64" "${DOTNET_COMMON_ARGS[@]}"
dotnet publish -c "$CONFIGURATION" -r osx-x64 -t:Audio_Desktop -o "$TEMP_DIRECTORY/publish_x64" "${DOTNET_COMMON_ARGS[@]}"

pushd "$BASE_DIR/distribution/macos"
./create_app_bundle.sh "$TEMP_DIRECTORY/publish_x64" "$TEMP_DIRECTORY/output_x64"
./create_app_bundle.sh "$TEMP_DIRECTORY/publish_arm64" "$TEMP_DIRECTORY/output_arm64"
popd

rm -rf "$UNIVERSAL_APP_BUNDLE"
mkdir -p "$OUTPUT_DIRECTORY"

# Let's copy one of the two different app bundle and remove the executable
cp -R "$ARM64_APP_BUNDLE" "$UNIVERSAL_APP_BUNDLE"
rm "$UNIVERSAL_APP_BUNDLE/$EXECUTABLE_SUB_PATH"

# Make the libraries universal
# - Currently, all libraries are already universal
#   So there's no need to modify them

if ! [ -x "$(command -v lipo)" ];
then
    if ! [ -x "$(command -v llvm-lipo-14)" ];
    then
        LIPO=llvm-lipo
    else
        LIPO=llvm-lipo-14
    fi
else
    LIPO=lipo
fi

# Make the executable universal
$LIPO "$ARM64_APP_BUNDLE/$EXECUTABLE_SUB_PATH" "$X64_APP_BUNDLE/$EXECUTABLE_SUB_PATH" -output "$UNIVERSAL_APP_BUNDLE/$EXECUTABLE_SUB_PATH" -create

# Now sign it
if [ -x "$(command -v codesign)" ];
then
    echo "Usign codesign for ad-hoc signing"
    codesign -f --deep -s - "$UNIVERSAL_APP_BUNDLE"
fi

echo "Creating archive"
pushd "$OUTPUT_DIRECTORY"
zip -yrX9 "$RELEASE_ZIP_FILE_NAME" *
popd

rm -rf "$TEMP_DIRECTORY"
echo "Done"
