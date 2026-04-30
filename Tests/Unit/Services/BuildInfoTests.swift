@preconcurrency import XCTest

@testable import PersonalHygiene

final class BuildInfoTests: XCTestCase {

    func test_marketingVersion_isNonEmpty() {
        // Always populated from CFBundleShortVersionString in the test bundle's
        // Info.plist or the host bundle's; we don't pin a specific version
        // because xcodegen owns it.
        XCTAssertFalse(BuildInfo.marketingVersion.isEmpty)
    }

    func test_bundleVersion_isNonEmpty() {
        XCTAssertFalse(BuildInfo.bundleVersion.isEmpty)
    }

    func test_commitSHA_returnsTrimmedNonEmptyString() {
        let sha = BuildInfo.commitSHA
        XCTAssertFalse(sha.isEmpty)
        XCTAssertEqual(sha, sha.trimmingCharacters(in: .whitespacesAndNewlines))
        // The CommitSHA.txt resource may not be in the test bundle (test target
        // doesn't include the iOS app's Resources), so we accept either the
        // baked file or the "dev" fallback.
        XCTAssertFalse(sha.contains("\n"))
    }

    func test_shortDescriptor_includesAllThreeFields() {
        let descriptor = BuildInfo.shortDescriptor
        XCTAssertTrue(descriptor.contains(BuildInfo.marketingVersion))
        XCTAssertTrue(descriptor.contains(BuildInfo.bundleVersion))
        XCTAssertTrue(descriptor.contains(BuildInfo.commitSHA))
    }

    func test_shortDescriptor_format() {
        // Format: "v<marketing> (<build>) — <sha>"
        let descriptor = BuildInfo.shortDescriptor
        XCTAssertTrue(descriptor.hasPrefix("v"))
        XCTAssertTrue(descriptor.contains("("))
        XCTAssertTrue(descriptor.contains(") — "))
    }
}
