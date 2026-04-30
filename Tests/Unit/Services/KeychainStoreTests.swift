@preconcurrency import XCTest

@testable import PersonalHygiene

@MainActor
final class KeychainStoreTests: XCTestCase {

    func test_writeAndRead_roundtripsData() throws {
        let store = InMemoryKeychainStore()
        try store.write(Data("hello".utf8), for: "k1")
        XCTAssertEqual(try store.read("k1"), Data("hello".utf8))
    }

    func test_writeOverwritesExisting() throws {
        let store = InMemoryKeychainStore()
        try store.write(Data("a".utf8), for: "k1")
        try store.write(Data("b".utf8), for: "k1")
        XCTAssertEqual(try store.read("k1"), Data("b".utf8))
    }

    func test_readMissingThrowsItemNotFound() {
        let store = InMemoryKeychainStore()
        XCTAssertThrowsError(try store.read("absent")) { error in
            XCTAssertEqual(error as? KeychainError, .itemNotFound)
        }
    }

    func test_deleteRemovesItem() throws {
        let store = InMemoryKeychainStore()
        try store.write(Data("v".utf8), for: "k1")
        try store.delete("k1")
        XCTAssertThrowsError(try store.read("k1"))
    }
}
