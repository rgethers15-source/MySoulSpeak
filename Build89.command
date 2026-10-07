#!/bin/bash
set -euo pipefail
cd -- "$(dirname -- "$0")"
if [[ "$(uname -s)" != Darwin ]]; then
  echo 'This build requires a Mac with Xcode installed.'; exit 1
fi
if ! xcrun --find xcodebuild >/dev/null 2>&1; then
  echo 'Open Xcode once and finish its installation, then run this file again.'; exit 1
fi
archive_path="$PWD/build/MySoulSpeak-Build89.xcarchive"
mkdir -p "$PWD/build"
if [[ -e "$archive_path" ]]; then
  echo 'An archive already exists at build/MySoulSpeak-Build89.xcarchive. Move it before rebuilding.'; exit 1
fi
xcodebuild -project MySoulSpeak.xcodeproj -scheme MySoulSpeak \
  -configuration Release -destination 'generic/platform=iOS' \
  -archivePath "$archive_path" -allowProvisioningUpdates archive \
  2>&1 | tee "$PWD/build/build89.log"
app_plist="$archive_path/Products/Applications/MySoulSpeak.app/Info.plist"
bundle_id=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app_plist")
build_number=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$app_plist")
[[ "$bundle_id" == com.soulspeak.app && "$build_number" == 89 ]] || {
  echo 'Unexpected bundle identifier or build number. Do not upload this archive.'; exit 1;
}
echo 'Archive created. This has not been uploaded or submitted to Apple.'
open "$archive_path"
