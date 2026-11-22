#!/usr/bin/env bash
# Archive DH Launcher and upload it to App Store Connect, using the Apple ID
# signed in to Xcode (Settings > Accounts). No API key needed.
#
#   scripts/upload-app-store.sh            # build number from project.yml
#   BUILD=2 scripts/upload-app-store.sh    # a new build number for a re-upload
#
# The app record (org.digitalhabits.launcher) must exist in App Store Connect.
set -euo pipefail
cd "$(dirname "$0")/.."
/opt/homebrew/bin/xcodegen generate -q
rm -rf build/DHLauncher.xcarchive build/export
xcodebuild -project DHLauncher.xcodeproj -scheme Launcher -configuration Release \
  -destination 'generic/platform=iOS' -archivePath build/DHLauncher.xcarchive \
  -allowProvisioningUpdates ${BUILD:+CURRENT_PROJECT_VERSION=$BUILD} archive
xcodebuild -exportArchive -archivePath build/DHLauncher.xcarchive \
  -exportOptionsPlist scripts/ExportOptions.plist -exportPath build/export \
  -allowProvisioningUpdates
echo "Uploaded. The build shows in App Store Connect > TestFlight after processing (about 10-30 min)."
