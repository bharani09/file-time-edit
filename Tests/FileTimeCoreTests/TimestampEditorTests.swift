import Foundation
import XCTest
@testable import FileTimeCore

final class TimestampEditorTests: XCTestCase {
    func testUpdatesCreationAndModificationDates() throws {
        let fixture = try TemporaryFixture()
        let targetDate = Date(timeIntervalSince1970: 1_421_314_200)

        let results = TimestampEditor().update(urls: [fixture.fileURL], to: targetDate)

        XCTAssertEqual(results.count, 1)
        XCTAssertTrue(results.allSatisfy { $0.succeeded })
        let attributes = try FileManager.default.attributesOfItem(
            atPath: fixture.fileURL.path
        )
        XCTAssertEqual(attributes[.creationDate] as? Date, targetDate)
        XCTAssertEqual(attributes[.modificationDate] as? Date, targetDate)
    }

    func testRecursivelyUpdatesFolderContentsWithoutDuplicates() throws {
        let fixture = try TemporaryFixture()
        let targetDate = Date(timeIntervalSince1970: 1_600_000_000)

        let results = TimestampEditor().update(
            urls: [fixture.directoryURL, fixture.fileURL],
            to: targetDate
        )

        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(Set(results.map(\.url)).count, 2)
        XCTAssertTrue(results.allSatisfy { $0.succeeded })
        let folderAttributes = try FileManager.default.attributesOfItem(
            atPath: fixture.directoryURL.path
        )
        XCTAssertEqual(folderAttributes[.modificationDate] as? Date, targetDate)
    }
}

private final class TemporaryFixture {
    let directoryURL: URL
    let fileURL: URL

    init() throws {
        directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        fileURL = directoryURL.appendingPathComponent("sample.txt")
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
        try Data("sample".utf8).write(to: fileURL)
    }

    deinit {
        try? FileManager.default.removeItem(at: directoryURL)
    }
}