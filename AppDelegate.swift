import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {

    private var windowControllers: [StickyWindowController] = []
    private var hotKeyManager: HotKeyManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        openNewSticky()

        hotKeyManager = HotKeyManager { [weak self] in
            self?.openNewSticky()
        }
    }

    func openNewSticky() {
        let controller = StickyWindowController()
        controller.showWindow(nil)
        windowControllers.append(controller)
    }
}
