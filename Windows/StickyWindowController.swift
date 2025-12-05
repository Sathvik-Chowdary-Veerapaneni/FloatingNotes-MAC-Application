import AppKit
import SwiftUI

class StickyWindowController: NSWindowController {

    private let appearance: NoteAppearance
    
    // Context Awareness
    var linkedAppBundleID: String? = nil

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

        // Initialize super first so 'self' is available for closures
        super.init(window: panel)
        
        let rootView = StickyNoteView(
            appearance: appearance,
            initialOpacity: savedOpacity,
            onOpacityChange: { newOpacity in
                panel.alphaValue = CGFloat(newOpacity)
                UserDefaults.standard.set(newOpacity, forKey: "LastStickyOpacity")
            },
            onLinkAction: { [weak self] in
                guard let self = self else { return false }
                
                if let linked = self.linkedAppBundleID {
                    // Currently linked, so Unlink
                    self.linkedAppBundleID = nil
                    print("Unlinked note from \(linked)")
                    return false
                } else {
                    // Currently unlinked, so Link to last active app
                    if let appDelegate = NSApp.delegate as? AppDelegate,
                       let lastApp = appDelegate.lastActiveAppBundleID {
                        self.linkedAppBundleID = lastApp
                        print("Linked note to \(lastApp)")
                        return true
                    } else {
                        print("No last active app found to link to")
                        return false
                    }
                }
            }
        )

        panel.contentView = NSHostingController(rootView: rootView).view
    }


    required init?(coder: NSCoder) { nil }

    func setColor(_ color: Color) {
        appearance.color = color
    }
    
    func checkVisibility(activeAppID: String?) {
        guard let linkedID = linkedAppBundleID else {
            // Not linked, always visible (unless we want to hide when an exclusive app is active? No, global notes act as overlays)
            // Ensure window is visible (might have been hidden)
            // But be careful not to steal focus if not needed.
            if !window!.isVisible {
                window?.orderFront(nil)
            }
            return
        }
        
        if activeAppID == linkedID || activeAppID == Bundle.main.bundleIdentifier {
            // Show if active app is the linked one OR if we are interacting with FloatingNotes itself
            if !window!.isVisible {
                window?.orderFront(nil)
                // Optional: animation
            }
        } else {
            // Hide
            if window!.isVisible {
                window?.orderOut(nil)
            }
        }
    }
}
