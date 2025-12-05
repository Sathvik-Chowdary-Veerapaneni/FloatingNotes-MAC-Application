import SwiftUI
import AppKit

struct StickyNoteView: View {

    // Text content
    @State private var text: String = ""

    // Visual state
    @State private var selectedColor: Color
    @State private var opacity: Double

    // Callback to let the window controller update NSWindow.alphaValue
    let onOpacityChange: (Double) -> Void

    // Custom init so the window controller can inject defaults
    init(
        initialColor: Color = Color.yellow,
        initialOpacity: Double = 1.0,
        onOpacityChange: @escaping (Double) -> Void = { _ in }
    ) {
        _selectedColor = State(initialValue: initialColor)
        _opacity = State(initialValue: initialOpacity)
        self.onOpacityChange = onOpacityChange
    }

    var body: some View {
        ZStack(alignment: .leading) {

            // Base background – clean, neutral
            Color(NSColor.windowBackgroundColor)
                .ignoresSafeArea()

            // Thin color accent bar on the left
            selectedColor
                .frame(width: 3)
                .opacity(0.9)

            VStack(spacing: 0) {

                // Top control bar
                HStack(spacing: 10) {

                    // Small "grab" indicator
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.secondary.opacity(0.4))
                        .frame(width: 36, height: 3)
                        .padding(.leading, 2)

                    // Opacity slider
                    HStack(spacing: 4) {
                        Image(systemName: "circle.lefthalf.filled")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)

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

                    // Color choices inside a subtle pill
                    HStack(spacing: 6) {
                        ForEach(colorOptions, id: \.self) { color in
                            Button(action: {
                                selectedColor = color
                            }) {
                                Circle()
                                    .fill(color)
                                    .frame(width: 13, height: 13)
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                Color.primary.opacity(
                                                    selectedColor == color ? 0.7 : 0.15
                                                ),
                                                lineWidth: selectedColor == color ? 1.2 : 1
                                            )
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.secondary.opacity(0.08))
                    )

                    Spacer(minLength: 4)
                }
                .padding(.horizontal, 10)
                .padding(.top, 8)
                .padding(.bottom, 6)
                .background(
                    Color(NSColor.windowBackgroundColor)
                        .opacity(0.98)
                )

                // Text area – clean, minimal
                TextEditor(text: $text)
                    .font(.system(size: 14))
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
                    .background(
                        Color(NSColor.textBackgroundColor)
                            .opacity(0.9)
                    )
            }
        }
        .frame(minWidth: 260, minHeight: 160)
    }

    private var colorOptions: [Color] {
        [
            Color.yellow,
            Color.orange,
            Color.green,
            Color.blue
        ]
    }
}
