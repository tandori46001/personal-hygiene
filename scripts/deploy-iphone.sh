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

# --- 2a. Stamp CommitSHA.txt resource --------------------------------------
SHA_FILE="App/PersonalHygiene/Resources/CommitSHA.txt"
GIT_SHA="${GIT_COMMIT_SHA:-$(git rev-parse --short HEAD 2>/dev/null || echo dev)}"
echo "$GIT_SHA" > "$SHA_FILE"
echo "==> stamped CommitSHA.txt with $GIT_SHA"

# --- 3. Build ---------------------------------------------------------------
echo "==> building for device $DEVICE_UDID"
set +e
xcodebuild build \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "platform=iOS,id=$DEVICE_UDID" \
  -derivedDataPath "$BUILD_DIR" \
  -allowProvisioningUpdates 2>&1 \
  | tee /tmp/deploy-iphone-build.log \
  | grep -E "^\*\*|error:|warning: All|Build description signature|BUILD SUCCEEDED|BUILD FAILED" || true
BUILD_EXIT=${PIPESTATUS[0]}
set -e
if [ "$BUILD_EXIT" -ne 0 ]; then
  echo "ERROR: iPhone build failed (xcodebuild exit=$BUILD_EXIT)." >&2
  echo "  Full log: /tmp/deploy-iphone-build.log" >&2
  exit 1
fi

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
INSTALL_LOG=/tmp/deploy-iphone-install.log
set +e
xcrun devicectl device install app \
  --device "$DEVICE_UDID" \
  "$APP_PATH" 2>&1 \
  | tee "$INSTALL_LOG" \
  | grep -E "App installed|bundleID:|installationURL:|ERROR" || true
INSTALL_EXIT=${PIPESTATUS[0]}
set -e
if [ "$INSTALL_EXIT" -ne 0 ] || grep -q "^ERROR:" "$INSTALL_LOG"; then
  echo "ERROR: iPhone install failed (devicectl exit=$INSTALL_EXIT)." >&2
  exit 1
fi

if [ "$NO_LAUNCH" = "1" ]; then
  echo "==> done (skipped launch)"
  exit 0
fi

# --- 6. Launch --------------------------------------------------------------
echo "==> launching $BUNDLE_ID"
LAUNCH_LOG=/tmp/deploy-iphone-launch.log
set +e
xcrun devicectl device process launch \
  --device "$DEVICE_UDID" \
  "$BUNDLE_ID" 2>&1 \
  | tee "$LAUNCH_LOG" \
  | grep -E "Launched|process identifier|ERROR" || true
LAUNCH_EXIT=${PIPESTATUS[0]}
set -e
if [ "$LAUNCH_EXIT" -ne 0 ] || grep -q "^ERROR:" "$LAUNCH_LOG"; then
  echo "ERROR: iPhone launch failed (devicectl exit=$LAUNCH_EXIT)." >&2
  echo "  Install may have succeeded — try launching the app manually on the device." >&2
  exit 1
fi

echo
echo "==> deploy complete — paid Apple Developer Program (Team $TEAM_ID)"
