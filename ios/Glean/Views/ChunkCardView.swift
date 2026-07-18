import SwiftUI
import ScriptureCore

struct ChunkCardView: View {
    let chunk: Chunk
    @EnvironmentObject var readerSettings: ReaderSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(chunk.reference.uppercased())
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(.secondary)
            Text(chunk.text)
                .font(readerSettings.bodyFont())
                .lineSpacing(readerSettings.bodyFontSize * 0.3)
                .fixedSize(horizontal: false, vertical: true)
            Text("\(chunk.verses.count) verse\(chunk.verses.count == 1 ? "" : "s"), \(chunk.text.split(separator: " ").count) words")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
