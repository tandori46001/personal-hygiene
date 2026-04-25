#!/usr/bin/env bash
# scripts/format.sh — auto-format Swift source with swift-format
# bash 3.2 compatible

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

if ! command -v swift-format >/dev/null 2>&1; then
  echo "ERROR: swift-format not found. Run ./scripts/bootstrap.sh first." >&2
  exit 1
fi

SWIFT_FILES_COUNT=$(find App Tests -name '*.swift' 2>/dev/null | wc -l | tr -d ' ')
if [ "$SWIFT_FILES_COUNT" = "0" ]; then
  echo "==> no Swift files yet — nothing to format"
  exit 0
fi

echo "==> formatting Swift files (in place)"
swift-format format --in-place --recursive --configuration .swift-format App Tests

echo "==> done"
