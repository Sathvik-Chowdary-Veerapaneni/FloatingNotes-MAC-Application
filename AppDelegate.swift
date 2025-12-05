import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {

    private var windowControllers: [StickyWindowController] = []
    private var hotKeyManager: HotKeyManager?

    // Track the previously active app to allow linking notes to it
    var lastActiveAppBundleID: String?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // create first sticky on launch
        openNewSticky()

        // register global ⌥⌘N to create more
        hotKeyManager = HotKeyManager { [weak self] in
            self?.openNewSticky()
        }
        
        // Observe app activation to hide/show context-aware notes
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appDidActivate(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }
    
    @objc func appDidActivate(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              let bundleID = app.bundleIdentifier else { return }
        
        // If the new app is US (FloatingNotes), don't update lastActiveAppBundleID (preserve the one we want to link to)
        if bundleID != Bundle.main.bundleIdentifier {
            lastActiveAppBundleID = bundleID
        }
        
        // Update visibility of all stickies
        for controller in windowControllers {
            controller.checkVisibility(activeAppID: bundleID)
        }
    }

    func openNewSticky() {
        let baseFrame: NSRect

        if let lastWindow = windowControllers.last?.window {
            let lastFrame = lastWindow.frame
            baseFrame = NSRect(
                x: lastFrame.origin.x + 30,
                y: lastFrame.origin.y - 30,
                width: lastFrame.size.width,
                height: lastFrame.size.height
            )
        } else {
            baseFrame = NSRect(x: 300, y: 300, width: 300, height: 200)
        }

        let controller = StickyWindowController(frame: baseFrame)
        controller.showWindow(nil)
        windowControllers.append(controller)
        
        // Immediately check visibility (usually ensures it's shown as we are active)
        if let currentApp = NSWorkspace.shared.frontmostApplication?.bundleIdentifier {
             controller.checkVisibility(activeAppID: currentApp)
        }
    }
}
