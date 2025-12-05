import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {

    private var windowControllers: [StickyWindowController] = []
    private var hotKeyManager: HotKeyManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // create first sticky on launch
        openNewSticky()

        // register global ⌥⌘N to create more
        hotKeyManager = HotKeyManager { [weak self] in
            self?.openNewSticky()
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
    }
}
