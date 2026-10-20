#!/bin/bash
# Builds, signs, notarizes, and publishes a release.
#
#   Scripts/release.sh 1.0.0
#
# Needs, one time:
#   - Developer ID signing: either Xcode signed in to the team (cloud signing), or
#     ASC_KEY_PATH + ASC_KEY_ID + ASC_ISSUER_ID for an App Store Connect API key (CI)
#   - notarytool credentials: either `xcrun notarytool store-credentials midnightoil-notary`
#     or APPLE_ID + APPLE_APP_PASSWORD (+ TEAM_ID) in the environment (CI)
#   - the Sparkle EdDSA private key in the keychain under the "fuelgauge" account, or
#     SPARKLE_KEY_FILE pointing at it (CI)
#   - gh authenticated with push access to coreyhaines31/fuelgauge
set -euo pipefail

VERSION="${1:?usage: Scripts/release.sh <version>}"
if [ "$(git branch --show-current)" != "main" ]; then
  echo "✗ Release from main (in a separate worktree: git worktree add ../fuelgauge-release main)" >&2
  exit 1
fi
TEAM_ID="${TEAM_ID:-KPQU8X839X}"
NOTARY_PROFILE="${NOTARY_PROFILE:-midnightoil-notary}"
REPO="coreyhaines31/fuelgauge"
APP_NAME="Fuel Gauge"
CASK="fuelgauge"
SITE="https://fuelgauge.app"
SPARKLE_ACCOUNT="fuelgauge"

cd "$(dirname "$0")/.."
# Needs the full Xcode, even if the shell points DEVELOPER_DIR at the Command Line Tools.
case "${DEVELOPER_DIR:-}" in
  ""|*CommandLineTools*) export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ;;
esac
BUILD=build/release
[ -d "$BUILD" ] && rm -r "$BUILD"
mkdir -p "$BUILD"
BUILD_NUMBER=$(git rev-list --count HEAD)

quiet() { grep -E "error:|warning: |\*\* " || true; }

if [ -n "${APPLE_ID:-}" ]; then
  NOTARY_ARGS=(--apple-id "$APPLE_ID" --team-id "$TEAM_ID" --password "$APPLE_APP_PASSWORD")
else
  NOTARY_ARGS=(--keychain-profile "$NOTARY_PROFILE")
fi
# macOS ships bash 3.2, where expanding an empty array trips `set -u`; hence the ${arr[@]+...} form below.
# The keychain holds more than one app's key, so name this app's account explicitly.
SPARKLE_KEY_ARGS=(--account "$SPARKLE_ACCOUNT")
[ -n "${SPARKLE_KEY_FILE:-}" ] && SPARKLE_KEY_ARGS=(--ed-key-file "$SPARKLE_KEY_FILE")
# Cloud-managed Developer ID signing needs an account: Xcode's signed-in one, or an API key.
AUTH_ARGS=(-allowProvisioningUpdates)
if [ -n "${ASC_KEY_PATH:-}" ]; then
  AUTH_ARGS+=(-authenticationKeyPath "$ASC_KEY_PATH" -authenticationKeyID "$ASC_KEY_ID" -authenticationKeyIssuerID "$ASC_ISSUER_ID")
fi

echo "▶ Generating project"
xcodegen generate -q

echo "▶ Archiving $APP_NAME $VERSION ($BUILD_NUMBER)"
xcodebuild -project FuelGauge.xcodeproj -scheme FuelGauge -configuration Release \
  -archivePath "$BUILD/FuelGauge.xcarchive" \
  "${AUTH_ARGS[@]}" \
  MARKETING_VERSION="$VERSION" CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  archive | quiet

echo "▶ Exporting with Developer ID"
cat > "$BUILD/export.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>method</key><string>developer-id</string>
  <key>teamID</key><string>$TEAM_ID</string>
  <key>signingStyle</key><string>automatic</string>
</dict></plist>
PLIST
xcodebuild -exportArchive -archivePath "$BUILD/FuelGauge.xcarchive" \
  -exportOptionsPlist "$BUILD/export.plist" -exportPath "$BUILD/export" \
  "${AUTH_ARGS[@]}" | quiet
APP="$BUILD/export/$APP_NAME.app"
codesign --verify --deep --strict --verbose=1 "$APP"
# The Homebrew cask links this onto the PATH.
if ! "$APP/Contents/MacOS/fuelgauge" --version | grep -qx "$VERSION"; then
  echo "✗ The exported app is missing the fuelgauge command, or it reports the wrong version" >&2
  exit 1
fi

echo "▶ Notarizing the app"
ditto -c -k --keepParent "$APP" "$BUILD/app.zip"
xcrun notarytool submit "$BUILD/app.zip" "${NOTARY_ARGS[@]}" --wait
xcrun stapler staple "$APP"

echo "▶ Building the DMG"
DMG="$BUILD/FuelGauge-$VERSION.dmg"
STAGE="$BUILD/dmg"
mkdir -p "$STAGE" && cp -R "$APP" "$STAGE/" && ln -s /Applications "$STAGE/Applications"
hdiutil create -volname "$APP_NAME" -srcfolder "$STAGE" -ov -format UDZO -quiet "$DMG"
# The DMG is signed when a local Developer ID identity exists; with cloud-managed
# signing there is none, and notarization accepts an unsigned DMG of a signed app.
if security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
  codesign --sign "Developer ID Application" --timestamp "$DMG"
fi
xcrun notarytool submit "$DMG" "${NOTARY_ARGS[@]}" --wait
xcrun stapler staple "$DMG"
# Gatekeeper judges the app inside the image, so that's what we assess.
MOUNT=$(mktemp -d)
hdiutil attach -nobrowse -quiet "$DMG" -mountpoint "$MOUNT"
spctl --assess --type exec -v "$MOUNT/$APP_NAME.app"
hdiutil detach -quiet "$MOUNT"

echo "▶ Signing the update and writing the appcast"
SPARKLE_BIN=$(find build/DerivedData/SourcePackages/artifacts -type d -path "*Sparkle/bin" | head -1)
if [ -z "$SPARKLE_BIN" ]; then
  xcodebuild -project FuelGauge.xcodeproj -scheme FuelGauge -derivedDataPath build/DerivedData \
    -resolvePackageDependencies -quiet
  SPARKLE_BIN=$(find build/DerivedData/SourcePackages/artifacts -type d -path "*Sparkle/bin" | head -1)
fi
mkdir -p "$BUILD/appcast" && cp "$DMG" "$BUILD/appcast/"
"$SPARKLE_BIN/generate_appcast" ${SPARKLE_KEY_ARGS[@]+"${SPARKLE_KEY_ARGS[@]}"} \
  --download-url-prefix "https://github.com/$REPO/releases/download/v$VERSION/" \
  --link "$SITE" \
  "$BUILD/appcast"

echo "▶ Publishing GitHub release v$VERSION"
# A copy without the version in its name, so releases/latest/download/FuelGauge.dmg always works
# for the website, install scripts, and AI agents.
cp "$DMG" "$BUILD/FuelGauge.dmg"
gh release create "v$VERSION" "$DMG" "$BUILD/FuelGauge.dmg" "$BUILD/appcast/appcast.xml" \
  --repo "$REPO" --target main --title "$APP_NAME $VERSION" --generate-notes --latest

echo "▶ Updating the Homebrew cask"
TAP="$BUILD/homebrew-tap"
gh repo clone coreyhaines31/homebrew-tap "$TAP" -- --quiet --depth 1
SHA=$(shasum -a 256 "$DMG" | cut -d' ' -f1)
CASK_FILE="$TAP/Casks/$CASK.rb"
# The first release adds the cask from Scripts/homebrew.
[ -f "$CASK_FILE" ] || cp "Scripts/homebrew/$CASK.rb" "$CASK_FILE"
sed -i '' -e "s/^  version \".*\"/  version \"$VERSION\"/" -e "s/^  sha256 \".*\"/  sha256 \"$SHA\"/" "$CASK_FILE"
git -C "$TAP" add "Casks/$CASK.rb"
git -C "$TAP" commit -qm "$CASK $VERSION" && git -C "$TAP" push -q
echo "✓ Released $APP_NAME $VERSION"
