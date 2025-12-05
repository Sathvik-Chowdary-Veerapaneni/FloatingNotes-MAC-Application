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
                Button("Yellow") {
                    setActiveNoteColor(.yellow)
                }
                .keyboardShortcut("1", modifiers: .command)

                Button("Orange") {
                    setActiveNoteColor(.orange)
                }
                .keyboardShortcut("2", modifiers: .command)

                Button("Green") {
                    setActiveNoteColor(.green)
                }
                .keyboardShortcut("3", modifiers: .command)

                Button("Blue") {
                    setActiveNoteColor(.blue)
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
