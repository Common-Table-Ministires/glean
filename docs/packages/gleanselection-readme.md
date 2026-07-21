# GleanSelection (`biblealgo`)

**Standalone formation-selection brain for [Glean](https://github.com/Common-Table-Ministires/glean).**  
Own package. Own tests. Own curated pack. **Not** part of ScripturePreview / ScriptureCore.

> **Integrity rule:** There is exactly one implementation of cooldowns, scoring, and top‑K selection — this package. Reader apps *depend* on `GleanSelection`; they must not copy or reimplement it.

## What this is

Open-source, offline-first thematic Scripture selection for the **Glean** app (*grace-scrolling — formation over time*).

- Picks one formation-sized **chunk** (passage) per day/session  
- Hard **cooldowns** (90 / 180 days for popular)  
- Soft scoring: preferred themes, genre diversity, theme novelty, testament balance  
- Top‑K weighted pick  
- Fully **on-device** — no network, no SQLite, no UI  

ScripturePreview / Glean iOS are **reader shells**. This package is the **selection brain**.

## Package identity

| | |
|--|--|
| SPM product | `GleanSelection` |
| Module | `GleanSelection` |
| Org alignment | `org.commontableministries.gleanselection` (library; no app ID) |
| Platforms | macOS 14+, iOS 17+ |

```
biblealgo/
├── Package.swift
├── Sources/GleanSelection/
│   ├── Models.swift           # ScriptureChunk, Theme, Genre, ChunkLoader
│   ├── GleanAlgorithm.swift   # scoring + cooldowns
│   ├── SeenHistoryStore.swift # UserDefaults history
│   ├── GleanFeedSession.swift # load → select → persist
│   ├── FeedPassage.swift      # display DTO for UI edge
│   └── Resources/chunks.json  # bundled formation pack (64 BSB)
├── data/                      # seed + built pack (tooling)
├── scripts/                   # build_chunks.py, demo_select.py
└── Tests/GleanSelectionTests/
```

## Hard boundaries (do not cross)

**In this package:** models, algorithm, pack load, seen-history store, feed session, display DTO.

**Never in this package:** SwiftUI, SQLite, story lists, notes, reader fonts, App Store IDs, donate links.

**Never in ScriptureCore / app targets:** scoring weights, cooldowns, `isPopular` policy, a second copy of `GleanAlgorithm.swift`.

## Build & test

```bash
cd ~/Desktop/biblealgo
xattr -cr .          # Desktop sometimes carries xattrs that break codesign
swift test
```

## Use from an app (dependency only)

```swift
// Package.swift of the app
dependencies: [
    .package(path: "../../Desktop/biblealgo"),  // or sibling repo later
],
// target depends on product "GleanSelection"
```

```swift
import GleanSelection

let session = try GleanFeedSession()
if let chunk = session.next() {
    let passage = FeedPassage(chunk: chunk)  // hand to UI
}
```

## Rebuild the pack (tooling)

```bash
python3 scripts/build_chunks.py
# also copy into Sources/GleanSelection/Resources/chunks.json before release
cp data/chunks.json Sources/GleanSelection/Resources/chunks.json
```

Default DB path: ScripturePreview’s bundled `scripture.sqlite`.

## Selection rules (v1)

| Stage | Rule |
|-------|------|
| Hard filter | Skip if shown within 90 days (180 if `isPopular`) |
| +3.0 × matches | Preferred themes |
| +4.0 / +days | Never-seen bonus, or recency-of-return score |
| +2.0 | Genre not in last ~15 shows |
| +0.75 × n | Themes not in last ~10 shows |
| +1.0 | OT/NT rebalance when recent history is skewed |
| −0.35 | Mild popular dampener |
| Top‑K | Weighted random among top 3 scores |

## Current corpus

- **64** formation passages with full **BSB** text  
- Themes: hope, faith, love, wisdom, prayer, repentance, suffering, joy, justice, creation, kingdom, identity, peace  
- Expand only via `data/seed_passages.json` in **this** package  

## Topology (integrity)

```
Common-Table (future)
  glean              # apps + ScriptureCore  → depends on ↓
  glean-selection    # this package (today: Desktop/biblealgo)
```

Interim: this Desktop folder is canonical. Do not vendor sources into `sarah/glean`.

## License / ministry

Built for **Common Table Ministries** formation products.  
BSB text remains under the Berean Standard Bible license terms; keep redistributed packs compliant.
