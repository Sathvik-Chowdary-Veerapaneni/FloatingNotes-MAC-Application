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

    // Text content - Tabs (with names)
    struct TabItem: Identifiable, Equatable {
        let id: UUID
        var name: String
        var content: String
        init(id: UUID = UUID(), name: String, content: String = "") {
            self.id = id
            self.name = name
            self.content = content
        }
    }

    @State private var tabs: [TabItem] = [TabItem(name: "Tab 1", content: "")]
    @State private var currentTabIndex: Int = 0
    @State private var title: String = ""
    @State private var isViewReady: Bool = false

    // Visual state (shared with controller)
    @ObservedObject var appearance: NoteAppearance
    @State private var opacity: Double

    // Callback to let the window controller update NSWindow.alphaValue
    let onOpacityChange: (Double) -> Void
    // Callback to toggle app linking
    let onLinkAction: () -> String? // Returns app name if linked, nil if not

    @State private var linkedAppName: String? = nil

    init(
        appearance: NoteAppearance,
        initialOpacity: Double = 1.0,
        onOpacityChange: @escaping (Double) -> Void = { _ in },
        onLinkAction: @escaping () -> String? = { nil }
    ) {
        self.appearance = appearance
        _opacity = State(initialValue: initialOpacity)
        self.onOpacityChange = onOpacityChange
        self.onLinkAction = onLinkAction
    }

    var body: some View {
        ZStack {
            // FULL-WINDOW background = note color
            appearance.color
                .ignoresSafeArea()

            VStack(spacing: 0) {

                // Top control bar (same color, slightly darkened)
                ZStack {
                    // Center: Editable Title
                    TextField("Title", text: $title)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.black.opacity(0.6))
                        .frame(maxWidth: 150)
                        .multilineTextAlignment(.center)

                    // Left: Controls
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
                            .frame(width: 60) // Limit slider width to prevent overlap
                            
                            // Link Button
                            Button(action: {
                                linkedAppName = onLinkAction()
                            }) {
                                HStack(spacing: 2) {
                                    Image(systemName: linkedAppName != nil ? "link" : "link.badge.plus")
                                        .font(.system(size: 11))
                                    
                                    if let name = linkedAppName {
                                        Text(name)
                                            .font(.system(size: 9, weight: .bold))
                                            .lineLimit(1)
                                            .fixedSize()
                                    }
                                }
                                .foregroundColor(linkedAppName != nil ? .black : .black.opacity(0.4))
                                .padding(4)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .help(linkedAppName != nil ? "Unlink from \(linkedAppName!)" : "Link to Active App")
                        }

                        Spacer()
                    }
                }
                .padding(.horizontal, 10)
                .padding(.top, 8)
                .padding(.bottom, 6)
                .background(appearance.color.opacity(0.7))
                
                // Tab Bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(0..<tabs.count, id: \.self) { index in
                            Button(action: {
                                currentTabIndex = index
                            }) {
                                Text("Tab \(index + 1)")
                                    .font(.system(size: 10, weight: .medium))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        currentTabIndex == index
                                        ? Color.black.opacity(0.2)
                                        : Color.clear
                                    )
                                    .cornerRadius(6)
                                    .foregroundColor(.black.opacity(0.8))
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // Add Tab Button
                        Button(action: {
                            tabs.append("")
                            currentTabIndex = tabs.count - 1
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 10, weight: .bold))
                                .padding(4)
                                .background(Color.white.opacity(0.3))
                                .clipShape(Circle())
                                .foregroundColor(.black.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                }
                .background(appearance.color.opacity(0.5))

                // Text area – transparent, sits directly on note color
                MacEditorView(text: $tabs[currentTabIndex], isTransparent: true)
                    .padding(4) // Minimal padding as NSTextView container handles some
            }
        }
        .frame(minWidth: 260, minHeight: 160)
    }
}
