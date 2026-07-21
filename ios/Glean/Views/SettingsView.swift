import SwiftUI
import ScriptureCore

struct SettingsView: View {
    @Binding var translation: BibleTranslation
    @EnvironmentObject var readerSettings: ReaderSettings
    @Environment(\.appTheme) private var theme

    /// Points at the ministry's main site for now; swap for the actual giving
    /// page URL once Common Table Ministries has one live.
    private let donateURLString = "https://commontableministries.com"

    var body: some View {
        Form {
            Section("Translation") {
                Picker("Translation", selection: $translation) {
                    ForEach(BibleTranslation.allCases) { t in
                        Text(t.displayName).tag(t)
                    }
                }
                .pickerStyle(.inline)
            }

            Section {
                ForEach(AppThemeID.grouped, id: \.category) { group in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(group.category)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(theme.secondaryText)
                            .textCase(.uppercase)
                            .padding(.top, 4)

                        ForEach(group.themes) { themeID in
                            ThemeRow(
                                themeID: themeID,
                                isSelected: readerSettings.themeID == themeID
                            ) {
                                readerSettings.setTheme(themeID)
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
            } header: {
                Text("Look & feel")
            } footer: {
                Text("Curated themes only — no custom theme maker yet. Pick what feels right for you.")
            }

            Section("Reading") {
                HStack {
                    Text("Text size")
                    Spacer()
                    Button {
                        readerSettings.decreaseFontSize()
                    } label: {
                        Image(systemName: "textformat.size.smaller")
                    }
                    .disabled(!readerSettings.canDecreaseFont)
                    Button {
                        readerSettings.increaseFontSize()
                    } label: {
                        Image(systemName: "textformat.size.larger")
                    }
                    .disabled(!readerSettings.canIncreaseFont)
                }
                Toggle("Dyslexia-friendly font", isOn: $readerSettings.useDyslexicFont)
            }

            Section {
                if let url = URL(string: donateURLString) {
                    Link(destination: url) {
                        Label("Support Common Table Ministries", systemImage: "heart.fill")
                    }
                }
            } footer: {
                Text("Glean is free, always. Giving supports the ministry directly; nothing in the app is gated behind it.")
            }

            Section("About") {
                LabeledContent("Owned by", value: "Common Table Ministries")
                LabeledContent("License", value: "Open source")
                if let url = URL(string: "https://github.com/Common-Table-Ministires/glean") {
                    Link("View source on GitHub", destination: url)
                }
            }
        }
        .scrollContentBackground(readerSettings.themeID == .system ? .automatic : .hidden)
        .background(theme.background.ignoresSafeArea())
        .navigationTitle("Settings")
    }
}

// MARK: - Theme row

private struct ThemeRow: View {
    let themeID: AppThemeID
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                HStack(spacing: 3) {
                    ForEach(Array(themeID.previewSwatches.enumerated()), id: \.offset) { _, color in
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(color)
                            .frame(width: 14, height: 28)
                    }
                }
                .padding(4)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.08))
                )

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(themeID.displayName)
                            .font(.body.weight(.medium))
                            .foregroundStyle(.primary)
                        Text(themeID.fontDisplayName)
                            .font(themeID.typography.referenceFont(size: 11))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Text(themeID.blurb)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    // Live sample of the theme’s scripture face
                    Text("In the beginning was the Word")
                        .font(themeID.typography.bodyFont(size: 15))
                        .foregroundStyle(.primary.opacity(0.85))
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.tint)
                        .imageScale(.large)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityLabel("\(themeID.displayName), \(themeID.category)")
        .accessibilityHint(themeID.blurb)
    }
}
