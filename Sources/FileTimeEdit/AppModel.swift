import AppKit
import FileTimeCore
import Foundation

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var selectedURLs: [URL] = []
    @Published var year: Int
    @Published var month: Int
    @Published var day: Int
    @Published var hour: Int
    @Published var minute: Int
    @Published var second: Int
    @Published var recursively = true
    @Published var isDropTargeted = false
    @Published private(set) var isApplying = false
    @Published private(set) var results: [TimestampUpdateResult] = []

    private let calendar: Calendar

    init(now: Date = Date()) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        self.calendar = calendar

        let components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: now
        )
        year = components.year ?? 1970
        month = components.month ?? 1
        day = components.day ?? 1
        hour = components.hour ?? 0
        minute = components.minute ?? 0
        second = components.second ?? 0
    }

    var selectedDate: Date? {
        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = second

        guard let date = calendar.date(from: components) else { return nil }
        let resolved = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: date
        )
        guard resolved.year == year,
              resolved.month == month,
              resolved.day == day,
              resolved.hour == hour,
              resolved.minute == minute,
              resolved.second == second else {
            return nil
        }
        return date
    }

    var folderCount: Int {
        selectedURLs.filter(\.isDirectory).count
    }

    var successfulCount: Int {
        results.filter(\.succeeded).count
    }

    var failedResults: [TimestampUpdateResult] {
        results.filter { !$0.succeeded }
    }

    func chooseItems() {
        let panel = NSOpenPanel()
        panel.title = "Choose files and folders"
        panel.prompt = "Add"
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.resolvesAliases = true

        guard panel.runModal() == .OK else { return }
        add(panel.urls)
    }

    func add(_ urls: [URL]) {
        let existingPaths = Set(selectedURLs.map(\.standardizedFileURL.path))
        let additions = urls
            .map(\.standardizedFileURL)
            .filter { !existingPaths.contains($0.path) }
        selectedURLs.append(contentsOf: additions)
        results = []
    }

    func remove(_ url: URL) {
        selectedURLs.removeAll { $0 == url }
        results = []
    }

    func clear() {
        selectedURLs.removeAll()
        results = []
    }

    func applyTimestamp() {
        guard !selectedURLs.isEmpty,
              !isApplying,
              let date = selectedDate else {
            return
        }

        isApplying = true
        results = []
        let urls = selectedURLs
        let shouldRecurse = recursively

        Task {
            let updateResults = await Task.detached(priority: .userInitiated) {
                TimestampEditor().update(
                    urls: urls,
                    to: date,
                    recursively: shouldRecurse
                )
            }.value
            results = updateResults
            isApplying = false
        }
    }
}

private extension URL {
    var isDirectory: Bool {
        (try? resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
    }
}