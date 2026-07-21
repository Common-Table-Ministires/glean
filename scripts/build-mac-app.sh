#!/bin/bash
# Packages the ScripturePreview SPM executable as a real, launchable .app bundle.
# swift run alone produces a bare executable with no Dock icon or Finder presence;
# this wraps it in the minimal structure macOS needs to treat it as a normal app.
set -euo pipefail

cd "$(dirname "$0")/.."

swift build

BUILD_DIR=".build/out/Products/Debug"
APP_NAME="ScripturePreview"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# SPM resource bundles (selection pack + scripture DB / font)
if [[ -d "$BUILD_DIR/ScriptureApp_ScripturePreview.bundle" ]]; then
  cp -R "$BUILD_DIR/ScriptureApp_ScripturePreview.bundle" "$APP_BUNDLE/Contents/Resources/"
fi
# GleanSelection may land under the products dir or a nested path depending on SPM layout
for bundle in \
  "$BUILD_DIR/GleanSelection_GleanSelection.bundle" \
  "$BUILD_DIR/biblealgo_GleanSelection.bundle" \
  $(find .build -name 'GleanSelection_GleanSelection.bundle' -type d 2>/dev/null | head -3)
do
  if [[ -d "$bundle" ]]; then
    cp -R "$bundle" "$APP_BUNDLE/Contents/Resources/"
    break
  fi
done

# Flatten critical assets into Contents/Resources so Bundle.main can find them
# even if Bundle.module resolution fails inside a packaged .app (Jul 18 crash).
SCRIPTURE_SRC=$(find .build -name 'scripture.sqlite' -type f 2>/dev/null | head -1 || true)
FONT_SRC=$(find .build -name 'OpenDyslexic-Regular.otf' -type f 2>/dev/null | head -1 || true)
if [[ -n "${SCRIPTURE_SRC}" ]]; then
  cp "$SCRIPTURE_SRC" "$APP_BUNDLE/Contents/Resources/scripture.sqlite"
fi
if [[ -n "${FONT_SRC}" ]]; then
  cp "$FONT_SRC" "$APP_BUNDLE/Contents/Resources/OpenDyslexic-Regular.otf"
fi

cat > "$APP_BUNDLE/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>org.commontableministries.scripturepreview</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>CFBundleVersion</key>
    <string>10</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

codesign --force --deep --sign - "$APP_BUNDLE"

echo "Built: $APP_BUNDLE"
