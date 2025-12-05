import SwiftUI
import AppKit

struct MacEditorView: NSViewRepresentable {
    @Binding var text: String
    var font: NSFont = .systemFont(ofSize: 14)
    var isTransparent: Bool = true
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        
        let textView = AutoBulletTextView()
        textView.autoresizingMask = [.width]
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: scrollView.contentSize.width, height: CGFloat.greatestFiniteMagnitude)
        
        textView.delegate = context.coordinator
        textView.font = font
        textView.drawsBackground = !isTransparent
        if isTransparent {
            textView.backgroundColor = .clear
        }
        
        // Allow undo/redo
        textView.allowsUndo = true
        
        scrollView.documentView = textView
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        
        // Only update text if it's different to avoid cursor jumping
        if textView.string != text {
            textView.string = text
        }
        
        if isTransparent {
            textView.backgroundColor = .clear
            textView.drawsBackground = false
        }
        
        // CRITICAL: Update coordinator's parent to point to the new struct (with new binding)
        context.coordinator.parent = self
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MacEditorView
        
        init(_ parent: MacEditorView) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }
    }
}

// Custom NSTextView to intercept key events for auto-bullets
class AutoBulletTextView: NSTextView {
    
    override func doCommand(by selector: Selector) {
        if selector == #selector(insertNewline(_:)) {
            if handleAutoBullet() {
                return
            }
        }
        super.doCommand(by: selector)
    }
    
    private func handleAutoBullet() -> Bool {
        guard let storage = textStorage else { return false }
        
        let selectedRange = self.selectedRange
        let stringStr = storage.string as NSString
        
        // Find current line range
        let lineRange = stringStr.lineRange(for: NSRange(location: selectedRange.location, length: 0))
        let currentLine = stringStr.substring(with: lineRange).trimmingCharacters(in: .newlines)
        
        // 1. Check for Numbered List "1. "
        // Regex: starts with digits, then dot, then space
        if let regex = try? NSRegularExpression(pattern: "^(\\d+)\\. (.*)") {
            if let match = regex.firstMatch(in: currentLine, options: [], range: NSRange(location: 0, length: currentLine.utf16.count)) {
                
                // Group 1: The number
                // Group 2: The content
                let numberRange = match.range(at: 1)
                let contentRange = match.range(at: 2)
                
                let currentNumberString = (currentLine as NSString).substring(with: numberRange)
                let content = (currentLine as NSString).substring(with: contentRange)
                
                if content.trimmingCharacters(in: .whitespaces).isEmpty {
                    // Empty bullet line -> Case: User hit enter on an empty "2. " -> Remove the bullet
                    // Replace the whole line (including the bullet) with empty string (or just newline handled by super if we return false... wait)
                    // We want to delete the current "2. " line and just put a newline?
                    // Usually: remove the "2. " and act as normal newline.
                    
                    // Let's just remove the bullet prefix from the current line
                    replaceCurrentLine(with: "")
                    return true // Handled
                }
                
                if let number = Int(currentNumberString) {
                    let nextNumber = number + 1
                    let nextBullet = "\n\(nextNumber). "
                    insertText(nextBullet, replacementRange: selectedRange)
                    return true
                }
            }
        }
        
        // 2. Check for Dash List "- " or Bullet List "* "
        let bullets = ["- ", "* ", "• "]
        for bullet in bullets {
            if currentLine.hasPrefix(bullet) {
                let content = String(currentLine.dropFirst(bullet.count))
                
                if content.trimmingCharacters(in: .whitespaces).isEmpty {
                    // Empty bullet -> Remove it (exit list)
                    replaceCurrentLine(with: "")
                    return true
                } else {
                    // Continue list
                    insertText("\n" + bullet, replacementRange: selectedRange)
                    return true
                }
            }
        }
        
        return false
    }
    
    private func replaceCurrentLine(with newText: String) {
        guard let storage = textStorage else { return }
        let stringStr = storage.string as NSString
        let lineRange = stringStr.lineRange(for: NSRange(location: selectedRange.location, length: 0))
        
        // We want to replace the text of the line (excluding newline char if it exists at end of range?)
        // lineRange includes the newline character at the end usually.
        // We just want to clear the line content but keep the newline logic conceptually?
        // Actually, if we are 'exiting' a list, we often want to remove the "2. " and just have a blank line.
        
        if shouldChangeText(in: lineRange, replacementString: newText) {
             storage.replaceCharacters(in: lineRange, with: newText + "\n")
             didChangeText()
        }
    }
}
