import SwiftUI
import AppKit

@main
struct FloatingNotesApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
        .commands {
            CommandMenu("Note Color") {
                Button("Light Yellow") {
                    setActiveNoteColor(Color(red: 1.0, green: 0.98, blue: 0.8))
                }
                .keyboardShortcut("1", modifiers: .command)

                Button("Light Orange") {
                    setActiveNoteColor(Color(red: 1.0, green: 0.92, blue: 0.8))
                }
                .keyboardShortcut("2", modifiers: .command)

                Button("Light Green") {
                    setActiveNoteColor(Color(red: 0.88, green: 0.98, blue: 0.88))
                }
                .keyboardShortcut("3", modifiers: .command)

                Button("Light Blue") {
                    setActiveNoteColor(Color(red: 0.88, green: 0.94, blue: 1.0))
                }
                .keyboardShortcut("4", modifiers: .command)
            }
        }
    }
}

// Helper: change color of the currently active sticky window
private func setActiveNoteColor(_ color: Color) {
    print("⌘color: requested color change")

    guard let window = NSApp.keyWindow else {
        print("⌘color: no keyWindow")
        return
    }

    print("⌘color: keyWindow = \(window)")

    guard let controller = window.windowController as? StickyWindowController else {
        print("⌘color: keyWindowController is not StickyWindowController (is \(String(describing: window.windowController)))")
        return
    }

    print("⌘color: found StickyWindowController, applying color")
    controller.setColor(color)
}
