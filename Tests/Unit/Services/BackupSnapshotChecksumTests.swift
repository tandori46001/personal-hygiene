@testable import PersonalHygiene
import XCTest

final class BackupSnapshotChecksumTests: XCTestCase {

    func test_sha256_isStableForSameInput() {
        let data = Data("hello-personal-hygiene".utf8)
        let firstPass = BackupSnapshotChecksum.sha256(of: data)
        let secondPass = BackupSnapshotChecksum.sha256(of: data)
        XCTAssertEqual(firstPass, secondPass)
        XCTAssertEqual(firstPass.count, 64)  // 32 bytes hex-encoded
    }

    func test_sha256_changesWhenInputChanges() {
        let alpha = BackupSnapshotChecksum.sha256(of: Data("a".utf8))
        let bravo = BackupSnapshotChecksum.sha256(of: Data("b".utf8))
        XCTAssertNotEqual(alpha, bravo)
    }

    func test_verify_returnsTrueOnMatch() {
        let payload = Data("{}".utf8)
        let digest = BackupSnapshotChecksum.sha256(of: payload)
        XCTAssertTrue(BackupSnapshotChecksum.verify(payload, matches: digest))
    }

    func test_verify_returnsFalseOnMismatch() {
        XCTAssertFalse(BackupSnapshotChecksum.verify(
            Data("a".utf8),
            matches: "deadbeef"
        ))
    }
}
