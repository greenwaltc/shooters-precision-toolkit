#!/bin/sh
set -eu

case "${FIREBASE_ENV:-}" in
  dev)
    expected_project=bramwellsprecisiontestkitdev
    expected_bundle=com.bramwell.bramwellsPrecisionTestKit.dev
    ;;
  prod)
    expected_project=bramwells-precision-test-kit
    expected_bundle=com.bramwell.bramwellsPrecisionTestKit
    ;;
  *) echo 'Select the dev or prod Xcode scheme.' >&2; exit 1 ;;
esac

firebase_plist="$SRCROOT/Firebase/$FIREBASE_ENV/GoogleService-Info.plist"
actual_project=$(/usr/libexec/PlistBuddy -c 'Print :PROJECT_ID' "$firebase_plist")
actual_bundle=$(/usr/libexec/PlistBuddy -c 'Print :BUNDLE_ID' "$firebase_plist")
if [ "$actual_project" != "$expected_project" ] ||
   [ "$actual_bundle" != "$expected_bundle" ] ||
   [ "$PRODUCT_BUNDLE_IDENTIFIER" != "$expected_bundle" ]; then
  echo 'Firebase plist, native bundle ID, and selected environment disagree.' >&2
  exit 1
fi

firebase_resources="$TARGET_BUILD_DIR/$UNLOCALIZED_RESOURCES_FOLDER_PATH"
mkdir -p "$firebase_resources"
cp "$firebase_plist" "$firebase_resources/GoogleService-Info.plist"
