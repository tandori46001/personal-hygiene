#!/usr/bin/env bash
# scripts/lint.sh — run SwiftLint + swift-format check
# bash 3.2 compatible

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

EXIT=0

if ! command -v swiftlint >/dev/null 2>&1; then
  echo "ERROR: swiftlint not found. Run ./scripts/bootstrap.sh first." >&2
  exit 1
fi

if ! command -v swift-format >/dev/null 2>&1; then
  echo "ERROR: swift-format not found. Run ./scripts/bootstrap.sh first." >&2
  exit 1
fi

# Find Swift sources (skip if no .swift files exist yet)
SWIFT_FILES_COUNT=$(find App Tests -name '*.swift' 2>/dev/null | wc -l | tr -d ' ')

if [ "$SWIFT_FILES_COUNT" = "0" ]; then
  echo "==> no Swift files yet — skipping lint"
  exit 0
fi

echo "==> SwiftLint"
if ! swiftlint --strict --quiet; then
  EXIT=1
fi

echo
echo "==> swift-format check"
if ! swift-format lint --recursive --configuration .swift-format App Tests 2>&1; then
  EXIT=1
fi

if [ "$EXIT" = "0" ]; then
  echo
  echo "==> lint clean"
fi

exit "$EXIT"
