#!/bin/bash
# SessionStart hook for Claude Code on the web.
#
# Installs the Flutter SDK pinned to the same version CI uses, then runs
# `flutter pub get` so the project is ready for `flutter analyze` /
# `flutter test` / `dart format`. Idempotent — re-running re-uses the
# cached SDK directory and skips the download.
#
# Runs in async mode: the session starts immediately while this script
# completes in the background. Trade-off: if I try to run `flutter test`
# before the install finishes, the command will fail and I'll need to
# wait/retry. Set CLAUDE_HOOK_SYNC=true to force synchronous behaviour.
#
# Quiet on success; only emits output if something needs attention.

set -euo pipefail

# Skip on local sessions — the developer's machine already has Flutter.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

# Switch to async mode unless explicitly overridden. The JSON must be
# emitted on stdout before any other output. asyncTimeout is generous
# enough to cover a cold Flutter SDK download (~700 MB) plus extraction
# plus `flutter pub get`.
if [ "${CLAUDE_HOOK_SYNC:-}" != "true" ]; then
  echo '{"async": true, "asyncTimeout": 600000}'
fi

FLUTTER_VERSION="3.41.7"
FLUTTER_HOME="${FLUTTER_HOME:-$HOME/flutter}"
FLUTTER_TARBALL="flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/${FLUTTER_TARBALL}"

# Install Flutter SDK if not already present (or if the marker binary is
# missing, which would indicate a partial install).
if [ ! -x "$FLUTTER_HOME/bin/flutter" ]; then
  echo "Installing Flutter $FLUTTER_VERSION to $FLUTTER_HOME..." >&2
  TMP_TARBALL="$(mktemp --suffix=.tar.xz)"
  trap 'rm -f "$TMP_TARBALL"' EXIT
  curl -fsSL "$FLUTTER_URL" -o "$TMP_TARBALL"
  # The tarball extracts to a top-level "flutter" directory.
  mkdir -p "$(dirname "$FLUTTER_HOME")"
  tar -xJf "$TMP_TARBALL" -C "$(dirname "$FLUTTER_HOME")"
  # Mark the SDK directory safe for git (Flutter calls git internally).
  git config --global --add safe.directory "$FLUTTER_HOME" || true
fi

# Persist PATH for the rest of the session.
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export PATH=\"$FLUTTER_HOME/bin:\$PATH\"" >> "$CLAUDE_ENV_FILE"
fi
export PATH="$FLUTTER_HOME/bin:$PATH"

# Disable analytics + telemetry so Flutter doesn't print first-run banners.
flutter --disable-analytics >/dev/null 2>&1 || true
dart --disable-analytics >/dev/null 2>&1 || true

# Resolve project deps (idempotent; uses the pub cache when warm).
cd "${CLAUDE_PROJECT_DIR:-$(pwd)}"
flutter pub get >/dev/null
