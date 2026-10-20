#!/bin/zsh
# Build Math City for the App Store and upload it to TestFlight.
#
#   tools/release/testflight.sh
#
# Needs (on the release Mac, never in this repo):
#   ~/.appstoreconnect/math_city.env              ASC_KEY_ID=…, ASC_ISSUER_ID=…
#   ~/.appstoreconnect/private_keys/AuthKey_<ASC_KEY_ID>.p8
#
# The build number is the commit count of HEAD, so every upload from a newer
# main is higher than the last (App Store Connect rejects a repeat). The
# version name comes from pubspec.yaml. Apple then processes the build for
# 5-30 minutes before testers can install it.
set -euo pipefail
cd "$(dirname "$0")/../.."

env_file="$HOME/.appstoreconnect/math_city.env"
[[ -f "$env_file" ]] || { echo "missing $env_file" >&2; exit 1; }
source "$env_file"
key="$HOME/.appstoreconnect/private_keys/AuthKey_${ASC_KEY_ID}.p8"
[[ -f "$key" ]] || { echo "missing $key" >&2; exit 1; }

if [[ -n "$(git status --porcelain)" ]]; then
  echo "working tree has uncommitted changes; commit or stash them first" >&2
  exit 1
fi

build_number=$(git rev-list --count HEAD)
echo "Building $(grep '^version:' pubspec.yaml | cut -d' ' -f2 | cut -d+ -f1) ($build_number) from $(git rev-parse --short HEAD)"
flutter build ipa --release --build-number="$build_number"

xcrun altool --upload-app --type ios -f build/ios/ipa/*.ipa \
  --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID"
echo "Uploaded build $build_number. Apple emails when processing is done."
