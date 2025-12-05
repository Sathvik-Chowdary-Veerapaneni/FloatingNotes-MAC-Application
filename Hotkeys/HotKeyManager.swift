import AppKit
import Carbon.HIToolbox

final class HotKeyManager {

    private var hotKeyRef: EventHotKeyRef?
    let handler: () -> Void

    init(handler: @escaping () -> Void) {
        self.handler = handler
        registerHotKey()
    }

    deinit {
        unregisterHotKey()
    }

    private func registerHotKey() {
        // ⌥ + ⌘ + N
        let keyCode: UInt32 = 45            // N key
        let modifiers: UInt32 = UInt32(optionKey) | UInt32(cmdKey)

        let hotKeyID = EventHotKeyID(
            signature: OSType(UInt32(bitPattern: 0x464E484B)), // 'FNHK'
            id: 1
        )

        let eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        // Install handler
        InstallEventHandler(
            GetApplicationEventTarget(),
            hotKeyCallback,
            1,
            [eventType],
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            nil
        )

        // Register global hotkey
        RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    private func unregisterHotKey() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        hotKeyRef = nil
    }
}

// Global callback for the hotkey
private func hotKeyCallback(
    handlerCallRef: EventHandlerCallRef?,
    eventRef: EventRef?,
    userData: UnsafeMutableRawPointer?
) -> OSStatus {

    guard let userData = userData else { return noErr }

    let manager = Unmanaged<HotKeyManager>
        .fromOpaque(userData)
        .takeUnretainedValue()

    manager.handler()
    return noErr
}
