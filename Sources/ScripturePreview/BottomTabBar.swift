import SwiftUI

/// Floating bottom tab bar, matching current Apple design language (Music, Maps)
/// rather than a flush edge-to-edge bar. This is the primary navigation for the
/// app; it deliberately does not live in the top toolbar, which is reserved for
/// secondary, screen-specific controls (translation, text size, the passage picker).
struct BottomTabBar: View {
    @Binding var mode: Mode

    private let tabs: [(Mode, String, String)] = [
        (.feed, "square.stack", "Feed"),
        (.stories, "books.vertical", "Stories"),
        (.study, "highlighter", "Study"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.0) { target, icon, label in
                tabButton(target, icon: icon, label: label)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            Capsule().fill(.regularMaterial)
        )
        .overlay(
            Capsule().strokeBorder(Color.primary.opacity(0.08))
        )
        .shadow(color: .black.opacity(0.18), radius: 12, y: 6)
        .padding(.horizontal, 28)
        .padding(.bottom, 14)
    }

    @ViewBuilder
    private func tabButton(_ target: Mode, icon: String, label: String) -> some View {
        Button {
            mode = target
        } label: {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(mode == target ? Color.accentColor : Color.secondary)
        }
        .buttonStyle(.plain)
    }
}
