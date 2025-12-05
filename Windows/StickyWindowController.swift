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
                guard let self = self else { return nil }
                
                if let linked = self.linkedAppBundleID {
                    // Currently linked, so Unlink
                    self.linkedAppBundleID = nil
                    print("Unlinked note from \(linked)")
                    return nil
                } else {
                // Currently unlinked, so Link to last active app
                    
                    var targetAppID: String? = nil
                    
                    if let appDelegate = NSApp.delegate as? AppDelegate,
                       let lastApp = appDelegate.lastActiveAppBundleID {
                        targetAppID = lastApp
                    } else {
                        // Fallback: Try to find the most reasonable "other" app
                        // This handles the case where the user launches FloatingNotes and immediately clicks link
                        let candidates = NSWorkspace.shared.runningApplications.filter { app in
                            app.activationPolicy == .regular &&
                            app.bundleIdentifier != Bundle.main.bundleIdentifier
                        }
                        // Unfortunately we can't easily know Z-order, but let's pick the first one as a best guess
                        // or just fail. Failing is better than random linking.
                        // However, user said "I opened Safari". If Safari is running, let's try to grab it if it's the only other obvious one?
                        // Let's rely on the user switching apps at least once usually.
                        // But let's log it.
                        print("No tracked last active app.")
                    }
                    
                    if let appID = targetAppID {
                        self.linkedAppBundleID = appID
                        print("Linked note to \(appID)")
                        let appName = NSRunningApplication.runningApplications(withBundleIdentifier: appID).first?.localizedName ?? appID
                        return appName
                    } else {
                        return nil
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
