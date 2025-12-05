import SwiftUI

struct StickyNoteView: View {
    @State private var text: String = ""

    var body: some View {
        VStack(spacing: 0) {
            TextEditor(text: $text)
                .padding(8)
        }
        .frame(minWidth: 260, minHeight: 160)
    }
}
