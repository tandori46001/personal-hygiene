#!/usr/bin/env bash
# scripts/deploy-watch.sh — build + install + launch on a paired Apple Watch
# bash 3.2 compatible
#
# Defaults assume the personal-hygiene developer setup documented in
# memory/session_handoff.md (round 5–7). Override either via env vars:
#   WATCH_UDID=… ./scripts/deploy-watch.sh
#   TEAM_ID=…   ./scripts/deploy-watch.sh
#
# Pre-requisites (one-time):
#   - watchOS SDK installed: Xcode → Settings → Components → "watchOS NN"
#   - Apple Watch paired with the iPhone signed into Xcode → Accounts
#   - Watch on wrist + paired iPhone awake → device shows `connected` in
#     `xcrun devicectl list devices`
#
# Flags:
#   --no-launch   skip the final launch
#   --clean       wipe build/watch-build first
#   --no-install  build only (skip install + launch)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

# --- Defaults ---------------------------------------------------------------
DEFAULT_WATCH_UDID="2A2D6AEE-7F08-5F04-84AF-FF5B232B1EA1"  # Apple Watch Series 8 (devicectl UDID)
DEFAULT_WATCH_NAME="TAWA3795Wch8"                          # Bonjour name (used by xcodebuild)
DEFAULT_TEAM="XC79TD476V"                                  # Personal team
DEFAULT_BUNDLE="com.tandori46001.personalhygiene.watchkitapp"
DEFAULT_SCHEME="PersonalHygieneWatch"

# `xcrun devicectl` and `xcodebuild` use different identifier schemes for
# Apple Watches. devicectl uses the UDID; xcodebuild needs the device's ECID
# or its Bonjour name. We pass `name:` to xcodebuild because it survives across
# different watch hardware models for the same paired device.
WATCH_UDID="${WATCH_UDID:-$DEFAULT_WATCH_UDID}"
WATCH_NAME="${WATCH_NAME:-$DEFAULT_WATCH_NAME}"
TEAM_ID="${TEAM_ID:-$DEFAULT_TEAM}"
BUNDLE_ID="${BUNDLE_ID:-$DEFAULT_BUNDLE}"
SCHEME="${SCHEME:-$DEFAULT_SCHEME}"

NO_LAUNCH=0
CLEAN=0
NO_INSTALL=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --no-launch) NO_LAUNCH=1; shift ;;
    --clean) CLEAN=1; shift ;;
    --no-install) NO_INSTALL=1; shift ;;
    -h|--help)
      sed -n '2,20p' "$0" | sed 's/^# //;s/^#//'
      exit 0
      ;;
    *) echo "Unknown flag: $1" >&2; exit 1 ;;
  esac
done

# --- Pre-flight -------------------------------------------------------------
for cmd in xcodegen xcodebuild xcrun; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "ERROR: $cmd not found. Run ./scripts/bootstrap.sh first." >&2
    exit 1
  fi
done

PROJECT="App/PersonalHygiene.xcodeproj"
PROJECT_YML="App/project.yml"
BUILD_DIR="build/watch-build"
APP_PATH="$BUILD_DIR/Build/Products/Debug-watchos/PersonalHygieneWatch.app"

# --- 1. Check Watch is reachable -------------------------------------------
WATCH_STATE="$(xcrun devicectl list devices 2>/dev/null | awk -v udid="$WATCH_UDID" '$0 ~ udid {print $4; exit}')"
if [ "$WATCH_STATE" != "connected" ] && [ "$WATCH_STATE" != "available" ]; then
  echo "ERROR: Watch $WATCH_UDID is '$WATCH_STATE' (need 'connected' or 'available')." >&2
  echo "       Put it on your wrist, ensure the paired iPhone is awake, retry." >&2
  exit 1
fi

# --- 2. Check watchOS SDK is installed --------------------------------------
DESTINATIONS="$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -showdestinations 2>&1)"
if echo "$DESTINATIONS" | grep -q "watchOS.*is not installed"; then
  echo "ERROR: watchOS SDK not installed." >&2
  echo "       Open Xcode → Settings (⌘,) → Components → install the latest" >&2
  echo "       watchOS platform (~3 GB). After install, restart Xcode + retry." >&2
  exit 1
fi
if ! echo "$DESTINATIONS" | grep -qE "platform:watchOS, .*name:${WATCH_NAME}"; then
  echo "WARNING: did not find a destination matching name:${WATCH_NAME}." >&2
  echo "         Available destinations:" >&2
  echo "$DESTINATIONS" | grep -E "platform:watchOS" >&2
fi

# --- 3. Inject team into project.yml if missing -----------------------------
if ! grep -q "DEVELOPMENT_TEAM: \"${TEAM_ID}\"" "$PROJECT_YML"; then
  echo "==> injecting DEVELOPMENT_TEAM=${TEAM_ID} into project.yml"
  sed -i '' "s|DEVELOPMENT_TEAM: \"\"|DEVELOPMENT_TEAM: \"${TEAM_ID}\"|g" "$PROJECT_YML"
  ( cd App && xcodegen generate >/dev/null )
fi

# --- 4. Clean if requested --------------------------------------------------
if [ "$CLEAN" = "1" ]; then
  echo "==> cleaning $BUILD_DIR"
  rm -rf "$BUILD_DIR"
fi

# --- 5. Stamp CommitSHA.txt resource ---------------------------------------
SHA_FILE="App/PersonalHygiene/Resources/CommitSHA.txt"
GIT_SHA="${GIT_COMMIT_SHA:-$(git rev-parse --short HEAD 2>/dev/null || echo dev)}"
echo "$GIT_SHA" > "$SHA_FILE"
echo "==> stamped CommitSHA.txt with $GIT_SHA (shared with watch via Shared/)"

# --- 6. Build ---------------------------------------------------------------
echo "==> building for watch name:${WATCH_NAME}"
xcodebuild build \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "platform=watchOS,name=${WATCH_NAME}" \
  -derivedDataPath "$BUILD_DIR" \
  -allowProvisioningUpdates \
  | grep -E "^\*\*|error:|warning: All|Build description signature|BUILD SUCCEEDED|BUILD FAILED" || true

if [ ! -d "$APP_PATH" ]; then
  echo "ERROR: build did not produce $APP_PATH" >&2
  exit 1
fi

# --- 7. Strip macOS dot-underscore metadata (USB drive artifact) ------------
echo "==> stripping ._* metadata files"
find "$APP_PATH" -name '._*' -delete 2>/dev/null || true

if [ "$NO_INSTALL" = "1" ]; then
  echo "==> done (skipped install + launch)"
  exit 0
fi

# --- 8. Install -------------------------------------------------------------
echo "==> installing on watch"
xcrun devicectl device install app \
  --device "$WATCH_UDID" \
  "$APP_PATH" \
  | grep -E "App installed|bundleID:|installationURL:|ERROR" || true

if [ "$NO_LAUNCH" = "1" ]; then
  echo "==> done (skipped launch)"
  exit 0
fi

# --- 9. Launch --------------------------------------------------------------
echo "==> launching $BUNDLE_ID"
xcrun devicectl device process launch \
  --device "$WATCH_UDID" \
  "$BUNDLE_ID" \
  | grep -E "Launched|process identifier|ERROR" || true

echo
echo "==> deploy complete — personal team free expires after ~7 days"
