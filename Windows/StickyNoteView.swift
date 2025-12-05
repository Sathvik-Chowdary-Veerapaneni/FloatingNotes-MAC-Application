import SwiftUI
import Combine
import AppKit

final class NoteAppearance: ObservableObject {
    @Published var color: Color

    init(color: Color) {
        self.color = color
    }
}

struct StickyNoteView: View {

    // Text content
    @State private var text: String = ""

    // Visual state (shared with controller)
    @ObservedObject var appearance: NoteAppearance
    @State private var opacity: Double

    // Callback to let the window controller update NSWindow.alphaValue
    let onOpacityChange: (Double) -> Void

    init(
        appearance: NoteAppearance,
        initialOpacity: Double = 1.0,
        onOpacityChange: @escaping (Double) -> Void = { _ in }
    ) {
        self.appearance = appearance
        _opacity = State(initialValue: initialOpacity)
        self.onOpacityChange = onOpacityChange
    }

    var body: some View {
        ZStack {
            // FULL-WINDOW background = note color
            appearance.color
                .ignoresSafeArea()

            VStack(spacing: 0) {

                // Top control bar (same color, slightly darkened)
                HStack(spacing: 10) {

                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.black.opacity(0.25))
                        .frame(width: 36, height: 3)
                        .padding(.leading, 2)

                    HStack(spacing: 4) {
                        Image(systemName: "circle.lefthalf.filled")
                            .font(.system(size: 11))
                            .foregroundColor(.black.opacity(0.6))

                        Slider(
                            value: Binding(
                                get: { opacity },
                                set: { newValue in
                                    opacity = newValue
                                    onOpacityChange(newValue)
                                }
                            ),
                            in: 0.3...1.0
                        )
                    }

                    Spacer(minLength: 4)
                }
                .padding(.horizontal, 10)
                .padding(.top, 8)
                .padding(.bottom, 6)
                .background(
                    appearance.color.opacity(0.85)
                )

                // Text area – transparent, sits directly on note color
                TextEditor(text: $text)
                    .font(.system(size: 14))
                    .padding(8)
                    .background(Color.clear)
            }
        }
        .frame(minWidth: 260, minHeight: 160)
    }
}
