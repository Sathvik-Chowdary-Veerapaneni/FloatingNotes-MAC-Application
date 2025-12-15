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
        
        // 1. Check for Numbered List
        // Support styles: "1. text", "1) text", and "1 text" (number + space)
        do {
            let ns = currentLine as NSString
            let fullRange = NSRange(location: 0, length: currentLine.utf16.count)
            // (a) n. text  OR  n . text (spaces allowed around dot)
            if let dotRegex = try? NSRegularExpression(pattern: "^(\\d+)\\s*\\.\\s*(.*)"),
               let m = dotRegex.firstMatch(in: currentLine, options: [], range: fullRange) {
                let numStr = ns.substring(with: m.range(at: 1))
                let content = ns.substring(with: m.range(at: 2))
                if content.trimmingCharacters(in: .whitespaces).isEmpty {
                    replaceCurrentLine(with: "")
                    return true
                }
                if let number = Int(numStr) {
                    let next = number + 1
                    insertText("\n\(next). ", replacementRange: selectedRange)
                    return true
                }
            }
            // (b) n) text  OR  n ) text (spaces allowed before/after paren)
            if let parenRegex = try? NSRegularExpression(pattern: "^(\\d+)\\s*\\)\\s*(.*)"),
               let m = parenRegex.firstMatch(in: currentLine, options: [], range: fullRange) {
                let numStr = ns.substring(with: m.range(at: 1))
                let content = ns.substring(with: m.range(at: 2))
                if content.trimmingCharacters(in: .whitespaces).isEmpty {
                    replaceCurrentLine(with: "")
                    return true
                }
                if let number = Int(numStr) {
                    let next = number + 1
                    insertText("\n\(next)) ", replacementRange: selectedRange)
                    return true
                }
            }
            // (c) n␠text  (number followed by at least one space)
            if let spaceRegex = try? NSRegularExpression(pattern: "^(\\d+)\\s+(.*)"),
               let m = spaceRegex.firstMatch(in: currentLine, options: [], range: fullRange) {
                let numStr = ns.substring(with: m.range(at: 1))
                let content = ns.substring(with: m.range(at: 2))
                if content.trimmingCharacters(in: .whitespaces).isEmpty {
                    replaceCurrentLine(with: "")
                    return true
                }
                if let number = Int(numStr) {
                    let next = number + 1
                    insertText("\n\(next) ", replacementRange: selectedRange)
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
