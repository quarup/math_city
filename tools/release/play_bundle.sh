#!/bin/zsh
# Build the signed Android App Bundle for Google Play testing tracks.
#
#   tools/release/play_bundle.sh
#
# Needs (on the release Mac, never in this repo):
#   ~/.appsigning/math_city_upload.jks            the upload keystore
#   ~/.appsigning/math_city_key.properties        its passwords; android/key.properties
#                                                 is a git-ignored symlink to it
#
# The build number is the commit count of HEAD, the same scheme as
# testflight.sh, so Play's versionCode and TestFlight's build number agree for
# a given commit. Upload the .aab in the Play Console (Testing → the track →
# Create new release) until the Play Developer API upload is set up.
set -euo pipefail
cd "$(dirname "$0")/../.."

[[ -f android/key.properties ]] || { echo "android/key.properties missing: release would be debug-signed" >&2; exit 1; }
if [[ -n "$(git status --porcelain)" ]]; then
  echo "working tree has uncommitted changes; commit or stash them first" >&2
  exit 1
fi

build_number=$(git rev-list --count HEAD)
echo "Building $(grep '^version:' pubspec.yaml | cut -d' ' -f2 | cut -d+ -f1) ($build_number) from $(git rev-parse --short HEAD)"
flutter build appbundle --release --build-number="$build_number"
out=build/app/outputs/bundle/release/app-release.aab
jdk=$(flutter config --machine 2>/dev/null | sed -n 's/.*"jdk-dir": "\([^"]*\)".*/\1/p')
jarsigner="${jdk:+$jdk/bin/jarsigner}"; [[ -x "$jarsigner" ]] || jarsigner=jarsigner
"$jarsigner" -verify -verbose -certs "$out" | grep -q "CN=Math City upload key" \
  || { echo "bundle is NOT signed with the upload key" >&2; exit 1; }
echo "Signed bundle: $out ($build_number)"
