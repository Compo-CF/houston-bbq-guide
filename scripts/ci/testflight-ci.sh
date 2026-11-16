#!/usr/bin/env bash
# TestFlight from a GitHub macOS runner (.github/workflows/ios-release.yml), manual signing:
# the shared Apple Distribution cert (temp keychain, set up by the workflow) + the API-made
# App Store profile "Houston BBQ AppStore CI" (~/appstoreconnect/ci_signing.py on Windows).
# The Mac keeps using ./gen.sh + Xcode (automatic signing). Same build-number rule as gen.sh:
# CFBundleVersion = git commit count, stamped by ./gen.sh; version = CFBundleShortVersionString.
# Env: ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_PATH. Pass --no-upload to stop after a signed export.
set -euo pipefail
cd "$(dirname "$0")/../.."
UPLOAD=1; [ "${1:-}" = "--no-upload" ] && UPLOAD=0
TEAM_ID="7H5T5AR2X5"
BUNDLE_ID="com.compofelice.HoustonBBQGuide"
APP_PROFILE="Houston BBQ AppStore CI"
PROJECT="HoustonBBQGuide.xcodeproj"; SCHEME="HoustonBBQGuide"
BUILD_DIR="build"; ARCHIVE="$BUILD_DIR/$SCHEME.xcarchive"; EXPORT_DIR="$BUILD_DIR/export"
mkdir -p "$BUILD_DIR"

command -v xcodegen >/dev/null || brew install xcodegen
./gen.sh
BUILD_NUMBER="$(git rev-list --count HEAD)"
VERSION="$(grep -E '^[[:space:]]*CFBundleShortVersionString:' project.yml | head -1 | sed -E 's/.*"(.*)".*/\1/')"
echo "Houston BBQ Guide $VERSION ($BUILD_NUMBER) from $(git rev-parse --short HEAD)"

AUTH=(-authenticationKeyPath "$ASC_KEY_PATH" -authenticationKeyID "$ASC_KEY_ID" -authenticationKeyIssuerID "$ASC_ISSUER_ID")

xcodebuild archive \
  -project "$PROJECT" -scheme "$SCHEME" -configuration Release \
  -destination "generic/platform=iOS" -archivePath "$ARCHIVE" \
  -skipPackagePluginValidation -skipMacroValidation \
  CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY="Apple Distribution" DEVELOPMENT_TEAM="$TEAM_ID" \
  HOUBBQ_APP_PROFILE="$APP_PROFILE" \
  > "$BUILD_DIR/archive.log" 2>&1 || true
[ -d "$ARCHIVE" ] || { echo "archive failed"; grep -E "error:" "$BUILD_DIR/archive.log" | sort -u | head -40; tail -30 "$BUILD_DIR/archive.log"; exit 1; }
BUILT="$(/usr/libexec/PlistBuddy -c 'Print :ApplicationProperties:CFBundleVersion' "$ARCHIVE/Info.plist")"
[ "$BUILT" = "$BUILD_NUMBER" ] || { echo "archive has build $BUILT, expected $BUILD_NUMBER"; exit 1; }

DEST=export; [ "$UPLOAD" -eq 1 ] && DEST=upload
cat > "$BUILD_DIR/ExportOptions.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key><string>app-store-connect</string>
    <key>destination</key><string>$DEST</string>
    <key>teamID</key><string>$TEAM_ID</string>
    <key>signingStyle</key><string>manual</string>
    <key>signingCertificate</key><string>Apple Distribution</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>$BUNDLE_ID</key><string>$APP_PROFILE</string>
    </dict>
    <key>uploadSymbols</key><true/>
    <key>manageAppVersionAndBuildNumber</key><false/>
</dict>
</plist>
PLIST
set +e
xcodebuild -exportArchive -archivePath "$ARCHIVE" -exportOptionsPlist "$BUILD_DIR/ExportOptions.plist" \
  -exportPath "$EXPORT_DIR" "${AUTH[@]}" > "$BUILD_DIR/upload.log" 2>&1
RC=$?
set -e
tail -25 "$BUILD_DIR/upload.log"
[ "$RC" -eq 0 ] || { echo "export/upload failed (rc $RC)"; grep -E "error" "$BUILD_DIR/upload.log" | head -20; exit 1; }
echo "Done: Houston BBQ Guide $VERSION ($BUILD_NUMBER) $( [ "$UPLOAD" -eq 1 ] && echo 'uploaded to TestFlight' || echo 'signed export only' )."
