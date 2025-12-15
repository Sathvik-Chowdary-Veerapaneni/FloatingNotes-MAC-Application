import AppKit
import SwiftUI
import UniformTypeIdentifiers

protocol StickyWindowControllerDelegate: AnyObject {
    func stickyWindowDidBecomeActive(_ controller: StickyWindowController)
    func stickyWindowDidResignActive(_ controller: StickyWindowController)
}

class StickyWindowController: NSWindowController {

    private let appearance: NoteAppearance
    weak var delegate: StickyWindowControllerDelegate?
    
    // Context Awareness
    var linkedAppBundleID: String? = nil
    
    // Note content tracking
    var noteTitle: String = ""
    var noteTabs: [String] = [""]

    convenience init(frame: NSRect = NSRect(x: 300, y: 300, width: 300, height: 200)) {
        // Light pastel colors for better visual appeal
        let colors: [Color] = [
            Color(red: 1.0, green: 0.98, blue: 0.8),   // Light Yellow
            Color(red: 1.0, green: 0.92, blue: 0.8),   // Light Orange/Peach
            Color(red: 0.88, green: 0.98, blue: 0.88), // Light Green/Mint
            Color(red: 0.88, green: 0.94, blue: 1.0)   // Light Blue/Sky
        ]
        let randomColor = colors.randomElement() ?? colors[0]
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
                .miniaturizable,
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

        // Ensure the miniaturize (yellow) traffic light is visible and enabled
        if let miniButton = panel.standardWindowButton(.miniaturizeButton) {
            miniButton.isHidden = false
            miniButton.isEnabled = true
        }

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
                        _ = NSWorkspace.shared.runningApplications.filter { app in
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
            },
            onContentChange: { [weak self] title, tabs in
                self?.noteTitle = title
                self?.noteTabs = tabs
            }
        )

        panel.contentView = NSHostingController(rootView: rootView).view
        panel.delegate = self
    }


    required init?(coder: NSCoder) { nil }

    func setColor(_ color: Color) {
        appearance.color = color
    }
    
    /// Save the current note to a .txt file
    func saveNote() {
        let savePanel = NSSavePanel()
        savePanel.title = "Save Note"
        savePanel.message = "Choose a location to save your note"
        savePanel.nameFieldStringValue = noteTitle.isEmpty ? "Untitled Note.txt" : "\(noteTitle).txt"
        savePanel.allowedContentTypes = [UTType.plainText]
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        
        savePanel.begin { response in
            guard response == .OK, let url = savePanel.url else {
                print("Save cancelled")
                return
            }
            
            self.exportNoteToFile(url: url)
        }
    }
    
    /// Export note content to the specified file URL
    private func exportNoteToFile(url: URL) {
        var content = ""
        
        // Add title if present
        if !noteTitle.isEmpty {
            content += "\(noteTitle)\n"
            content += String(repeating: "=", count: noteTitle.count) + "\n\n"
        }
        
        // Add tabs content
        for (index, tabContent) in noteTabs.enumerated() {
            if noteTabs.count > 1 {
                content += "--- Tab \(index + 1) ---\n\n"
            }
            content += tabContent
            if index < noteTabs.count - 1 {
                content += "\n\n"
            }
        }
        
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            print("✅ Note saved successfully to: \(url.path)")
            
            // Show a brief notification (optional)
            showSaveConfirmation()
        } catch {
            print("❌ Error saving note: \(error.localizedDescription)")
            showErrorAlert(message: "Failed to save note: \(error.localizedDescription)")
        }
    }
    
    /// Show a brief confirmation that the file was saved
    private func showSaveConfirmation() {
        // Could add a temporary overlay or use NSUserNotification
        // For now, just console confirmation
    }
    
    /// Show an error alert dialog
    private func showErrorAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = "Save Failed"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    func checkVisibility(activeAppID: String?) {
        guard let linkedID = linkedAppBundleID else {
            // Not linked, always visible (unless we want to hide when an exclusive app is active? No, global notes act as overlays)
            // Ensure window is visible (might have been hidden)
            // But be careful not to steal focus if not needed.
            if window?.isVisible == false {
                window?.orderFront(nil)
            }
            return
        }
        
        if activeAppID == linkedID || activeAppID == Bundle.main.bundleIdentifier {
            // Show if active app is the linked one OR if we are interacting with FloatingNotes itself
            if window?.isVisible == false {
                window?.orderFront(nil)
                // Optional: animation
            }
        } else {
            // Hide
            if window?.isVisible == true {
                window?.orderOut(nil)
            }
        }
    }
}

extension StickyWindowController: NSWindowDelegate {
    func windowDidBecomeKey(_ notification: Notification) {
        delegate?.stickyWindowDidBecomeActive(self)
    }

    func windowDidResignKey(_ notification: Notification) {
        delegate?.stickyWindowDidResignActive(self)
    }
}
