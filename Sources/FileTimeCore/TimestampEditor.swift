import Foundation

public struct TimestampUpdateResult: Sendable, Identifiable {
    public let url: URL
    public let errorDescription: String?

    public var id: URL { url }
    public var succeeded: Bool { errorDescription == nil }

    public init(url: URL, errorDescription: String?) {
        self.url = url
        self.errorDescription = errorDescription
    }
}

public struct TimestampEditor: Sendable {
    public init() {}

    public func update(
        urls: [URL],
        to date: Date,
        recursively: Bool = true
    ) -> [TimestampUpdateResult] {
        let fileManager = FileManager.default
        return expandedURLs(urls, recursively: recursively).map { url in
            do {
                try fileManager.setAttributes(
                    [.creationDate: date, .modificationDate: date],
                    ofItemAtPath: url.path
                )
                return TimestampUpdateResult(url: url, errorDescription: nil)
            } catch {
                return TimestampUpdateResult(
                    url: url,
                    errorDescription: error.localizedDescription
                )
            }
        }
    }

    private func expandedURLs(_ urls: [URL], recursively: Bool) -> [URL] {
        let fileManager = FileManager.default
        var seenPaths = Set<String>()
        var result: [URL] = []

        for url in urls {
            appendIfNeeded(url, seenPaths: &seenPaths, result: &result)

                        let resourceValues = try? url.resourceValues(forKeys: [.isDirectoryKey])
                        guard recursively,
                                    resourceValues?.isDirectory == true,
                  let enumerator = fileManager.enumerator(
                    at: url,
                                        includingPropertiesForKeys: [.isDirectoryKey]
                  ) else {
                continue
            }

            for case let childURL as URL in enumerator {
                appendIfNeeded(childURL, seenPaths: &seenPaths, result: &result)
            }
        }

        return result.sorted {
            $0.pathComponents.count > $1.pathComponents.count
        }
    }

    private func appendIfNeeded(
        _ url: URL,
        seenPaths: inout Set<String>,
        result: inout [URL]
    ) {
        let standardizedURL = url.standardizedFileURL
        guard seenPaths.insert(standardizedURL.path).inserted else { return }
        result.append(standardizedURL)
    }
}