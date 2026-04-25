#!/usr/bin/env bash
# scripts/bootstrap.sh — install developer dependencies for personal-hygiene
# bash 3.2 compatible (macOS default)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

echo "==> personal-hygiene bootstrap"
echo "    repo: $REPO_ROOT"
echo

# 1. Verify macOS (required for Xcode toolchain)
if [ "$(uname -s)" != "Darwin" ]; then
  echo "ERROR: this project requires macOS for Xcode toolchain." >&2
  exit 1
fi

# 2. Verify Xcode
if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "ERROR: xcodebuild not found. Install Xcode from the App Store." >&2
  exit 1
fi
XCODE_VERSION="$(xcodebuild -version | head -n1)"
echo "==> $XCODE_VERSION"

# 3. Verify Homebrew
if ! command -v brew >/dev/null 2>&1; then
  echo "ERROR: Homebrew not found. Install from https://brew.sh" >&2
  exit 1
fi
echo "==> $(brew --version | head -n1)"

# 4. Install / update SwiftLint
if ! command -v swiftlint >/dev/null 2>&1; then
  echo "==> installing SwiftLint"
  brew install swiftlint
else
  echo "==> SwiftLint already installed: $(swiftlint --version)"
fi

# 5. Install / update swift-format
if ! command -v swift-format >/dev/null 2>&1; then
  echo "==> installing swift-format"
  brew install swift-format
else
  echo "==> swift-format already installed: $(swift-format --version 2>&1 | head -n1)"
fi

# 6. Install / update gitleaks (secret scanning, used by check-clean.sh)
if ! command -v gitleaks >/dev/null 2>&1; then
  echo "==> installing gitleaks"
  brew install gitleaks
else
  echo "==> gitleaks already installed: $(gitleaks version)"
fi

# 7. Optional: xcbeautify for nicer xcodebuild output
if ! command -v xcbeautify >/dev/null 2>&1; then
  echo "==> installing xcbeautify"
  brew install xcbeautify
fi

# 8. Make scripts executable
echo "==> making scripts executable"
chmod +x "$REPO_ROOT"/scripts/*.sh

echo
echo "==> bootstrap complete"
echo "    next steps:"
echo "      - open Xcode and create the project at App/PersonalHygiene.xcodeproj (Phase 0)"
echo "      - run ./scripts/lint.sh to verify lint setup"
echo "      - run ./scripts/check-tests.sh once tests exist"
