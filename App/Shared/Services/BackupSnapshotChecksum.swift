import CryptoKit
import Foundation

/// Round-25 slice T4.30: computes a SHA-256 digest over the canonical JSON
/// of a `BackupSnapshot` so the import flow can warn on tampered or
/// truncated files. Pure helper; not security-grade — just integrity.
public enum BackupSnapshotChecksum {

    @MainActor
    public static func sha256(of snapshot: BackupSnapshot) throws -> String {
        let data = try BackupService.encode(snapshot)
        return sha256(of: data)
    }

    public static func sha256(of data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    public static func verify(
        _ data: Data,
        matches expected: String
    ) -> Bool {
        sha256(of: data) == expected
    }
}
