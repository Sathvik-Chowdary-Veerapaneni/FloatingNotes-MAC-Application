import SwiftUI

@main
struct FloatingNotesApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // no main content window; only settings, our stickies come from AppDelegate
        Settings {
            EmptyView()
        }
    }
}
