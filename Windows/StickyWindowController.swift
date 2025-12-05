import AppKit
import SwiftUI

class StickyWindowController: NSWindowController {

    convenience init(
        frame: NSRect = NSRect(x: 300, y: 300, width: 300, height: 200)
    ) {

        // Create floating panel
        let window = NSPanel(
            contentRect: frame,
            styleMask: [
                .titled,
                .closable,
                .resizable,
                .fullSizeContentView
            ],
            backing: .buffered,
            defer: false
        )

        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true

        // Float over all apps + all Spaces + fullscreen apps
        window.level = .floating
        window.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary
        ]

        window.isReleasedWhenClosed = false

        // SwiftUI content with callback to control window alpha
        let rootView = StickyNoteView(
            initialColor: .yellow,
            initialOpacity: Double(window.alphaValue)
        ) { newOpacity in
            window.alphaValue = CGFloat(newOpacity)
        }

        let hostingController = NSHostingController(rootView: rootView)
        window.contentView = hostingController.view

        self.init(window: window)
    }
}
