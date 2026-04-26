#!/usr/bin/env bash
# scripts/deploy-iphone.sh — build + install + launch on a paired iPhone
# bash 3.2 compatible
#
# Defaults assume the personal-hygiene developer setup documented in
# memory/session_handoff.md (round 5 / round 6). Override either via env vars:
#   DEVICE_UDID=… ./scripts/deploy-iphone.sh
#   TEAM_ID=… ./scripts/deploy-iphone.sh
#
# Flags:
#   --no-launch   skip the final `devicectl ... process launch`
#   --clean       wipe build/device-build first
#   --no-install  build only (skip install + launch)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

# --- Defaults ---------------------------------------------------------------
DEFAULT_UDID="CE8682C3-5F31-558D-9221-B44CEAE7FE64"  # iPhone 15 Pro Max
DEFAULT_TEAM="XC79TD476V"                            # Personal team "Batman Good"
DEFAULT_BUNDLE="com.tandori46001.personalhygiene"
DEFAULT_SCHEME="PersonalHygiene"

DEVICE_UDID="${DEVICE_UDID:-$DEFAULT_UDID}"
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
      sed -n '2,15p' "$0" | sed 's/^# //;s/^#//'
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
BUILD_DIR="build/device-build"
APP_PATH="$BUILD_DIR/Build/Products/Debug-iphoneos/PersonalHygiene.app"

# --- 1. Inject team into project.yml if missing -----------------------------
if ! grep -q "DEVELOPMENT_TEAM: \"${TEAM_ID}\"" "$PROJECT_YML"; then
  echo "==> injecting DEVELOPMENT_TEAM=${TEAM_ID} into project.yml"
  sed -i '' "s|DEVELOPMENT_TEAM: \"\"|DEVELOPMENT_TEAM: \"${TEAM_ID}\"|g" "$PROJECT_YML"
  ( cd App && xcodegen generate >/dev/null )
fi

# --- 2. Clean if requested --------------------------------------------------
if [ "$CLEAN" = "1" ]; then
  echo "==> cleaning $BUILD_DIR"
  rm -rf "$BUILD_DIR"
fi

# --- 3. Build ---------------------------------------------------------------
echo "==> building for device $DEVICE_UDID"
xcodebuild build \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "platform=iOS,id=$DEVICE_UDID" \
  -derivedDataPath "$BUILD_DIR" \
  -allowProvisioningUpdates \
  | grep -E "^\*\*|error:|warning: All|Build description signature|BUILD SUCCEEDED|BUILD FAILED" || true

if [ ! -d "$APP_PATH" ]; then
  echo "ERROR: build did not produce $APP_PATH" >&2
  exit 1
fi

# --- 4. Strip macOS dot-underscore metadata (USB drive artifact) ------------
echo "==> stripping ._* metadata files"
find "$APP_PATH" -name '._*' -delete 2>/dev/null || true

if [ "$NO_INSTALL" = "1" ]; then
  echo "==> done (skipped install + launch)"
  exit 0
fi

# --- 5. Install -------------------------------------------------------------
echo "==> installing on device"
xcrun devicectl device install app \
  --device "$DEVICE_UDID" \
  "$APP_PATH" \
  | grep -E "App installed|bundleID:|installationURL:|ERROR" || true

if [ "$NO_LAUNCH" = "1" ]; then
  echo "==> done (skipped launch)"
  exit 0
fi

# --- 6. Launch --------------------------------------------------------------
echo "==> launching $BUNDLE_ID"
xcrun devicectl device process launch \
  --device "$DEVICE_UDID" \
  "$BUNDLE_ID" \
  | grep -E "Launched|process identifier|ERROR" || true

echo
echo "==> deploy complete — personal team free expires after ~7 days"
