import AppKit
import SwiftUI

class StickyWindowController: NSWindowController {

    private let appearance: NoteAppearance

    convenience init(frame: NSRect = NSRect(x: 300, y: 300, width: 300, height: 200)) {
        let colors: [Color] = [.yellow, .orange, .green, .blue]
        let randomColor = colors.randomElement() ?? .yellow
        let appearance = NoteAppearance(color: randomColor)
        self.init(frame: frame, appearance: appearance)
    }

    init(frame: NSRect, appearance: NoteAppearance) {
        self.appearance = appearance

        let panel = NSPanel(
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

        // --- CRITICAL FOR FULLSCREEN OVERLAY ---
        panel.hidesOnDeactivate = false                 // <-- keep visible when Safari is active
        panel.isFloatingPanel = true
        panel.level = .screenSaver                       // stronger than .floating, still reasonable
        panel.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary
        ]
        // --------------------------------------

        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        panel.isReleasedWhenClosed = false

        // Restore last saved opacity (default to 1.0 if not set)
        let savedOpacity = UserDefaults.standard.object(forKey: "LastStickyOpacity") as? Double ?? 1.0
        panel.alphaValue = CGFloat(savedOpacity)

        let rootView = StickyNoteView(
            appearance: appearance,
            initialOpacity: savedOpacity
        ) { newOpacity in
            panel.alphaValue = CGFloat(newOpacity)
            UserDefaults.standard.set(newOpacity, forKey: "LastStickyOpacity")
        }

        panel.contentView = NSHostingController(rootView: rootView).view

        super.init(window: panel)
    }

    required init?(coder: NSCoder) { nil }

    func setColor(_ color: Color) {
        appearance.color = color
    }
}
