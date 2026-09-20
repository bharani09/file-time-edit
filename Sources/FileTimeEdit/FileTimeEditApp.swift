import SwiftUI

@main
struct FileTimeEditApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 760, minHeight: 540)
        }
        .windowResizability(.contentMinSize)

        Settings {
            Text("File Time Edit has no configurable settings.")
                .padding(32)
        }
    }
}