#!/usr/bin/env bash
# Generate HoustonBBQGuide.xcodeproj with an automatic, git-derived build number.
#
# CFBundleVersion = total commit count on the current branch (`git rev-list
# --count HEAD`). This is monotonic (every commit bumps it), consistent across
# machines at the same commit, and maps a build back to an exact commit.
#
# Always generate the project with this script instead of running `xcodegen
# generate` directly, so the build number is stamped. Run it after every pull
# and before every archive.
set -euo pipefail
cd "$(dirname "$0")"

BUILD_NUMBER="$(git rev-list --count HEAD)"
echo "Build number (git commit count): $BUILD_NUMBER"

# Locate xcodegen (Homebrew PATH, or the standalone ~/bin install on MacInCloud).
XCODEGEN="$(command -v xcodegen || true)"
[ -z "$XCODEGEN" ] && XCODEGEN="$HOME/bin/xcodegen"
"$XCODEGEN" generate

# xcodegen writes HoustonBBQGuide/Info.plist from project.yml; stamp the real
# build number into it. Done here (generate time), before Xcode signs, so the
# packaged Info.plist is correct and the signature stays valid.
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" HoustonBBQGuide/Info.plist
echo "Stamped CFBundleVersion = $BUILD_NUMBER into HoustonBBQGuide/Info.plist"
