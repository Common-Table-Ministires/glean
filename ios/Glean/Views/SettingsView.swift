import SwiftUI
import ScriptureCore

struct SettingsView: View {
    @Binding var translation: BibleTranslation
    @EnvironmentObject var readerSettings: ReaderSettings

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

            Section("Reading") {
                HStack {
                    Text("Text size")
                    Spacer()
                    Button {
                        readerSettings.decreaseFontSize()
                    } label: {
                        Image(systemName: "textformat.size.smaller")
                    }
                    .disabled(readerSettings.fontScale <= ReaderSettings.scaleSteps.first!)
                    Button {
                        readerSettings.increaseFontSize()
                    } label: {
                        Image(systemName: "textformat.size.larger")
                    }
                    .disabled(readerSettings.fontScale >= ReaderSettings.scaleSteps.last!)
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
                Link("View source on GitHub", destination: URL(string: "https://github.com/Common-Table-Ministires/glean")!)
            }
        }
        .navigationTitle("Settings")
    }
}
