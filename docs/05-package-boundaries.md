# Package boundaries

Glean is one repo containing four Swift targets. The separation between them is
real and enforced, but it is enforced by the **module system**, not by living in
separate repositories.

## Why one repo

The selection brain and commentary pack were briefly separate repos on this
machine (`Desktop/biblealgo`, `sarah/gleancommentary`). That was an artifact of
how they got written, not a decision, and it had two concrete costs: CI could
not build the project at all, because the dependency paths escaped the repo, and
nobody who cloned the public repo could build it either.

Merging them keeps every protection that actually mattered and drops the ones
that were incidental:

| Protection | Still enforced? | How |
|---|---|---|
| One implementation of scoring and cooldowns | Yes | One target, one file, no duplicates |
| App cannot reach into selection internals | Yes | Swift module boundary; app must `import GleanSelection` |
| No SwiftUI or SQLite inside the brain | Yes | Target has no such dependency and must not gain one |
| Selection testable on its own | Yes | `swift test --filter GleanSelectionTests` |
| Separate git history and version tags | No | Traded away deliberately for one clone, one CI run, one version |

For a solo maintainer, one version to reason about beats three that have to be
kept in sync.

## What lives where

**`ScriptureCore`**: Scripture text and storage. Verses, books, chunking,
SQLite access, notes, reading progress.
Never: selection scoring, commentary, UI.

**`GleanSelection`**: the formation-selection brain. Models, scoring,
cooldowns, seen-history, feed session, the `FeedPassage` display DTO, and the
curated `chunks.json` pack.
Never: SwiftUI, SQLite, ScriptureCore types, story lists, reader fonts, donate
links, App Store IDs.

**`GleanCommentary`**: open and public-domain commentary. Source catalog with
per-source license rows, verse-keyed short excerpts, lookup store.
Never: SwiftUI, SQLite, ScriptureCore types. Excerpts stay short (1 to 4
sentences) and always carry author plus work; they are never presented as
anonymous "Glean doctrine."

**`ScripturePreview`**: the macOS iteration testbed. Depends on ScriptureCore
and GleanSelection. Not the shipping product; the iOS app in `ios/` is.

## Rules that still hold

1. Do not copy `GleanAlgorithm.swift` or its scoring constants into an app
   target. Change selection behavior in `Sources/GleanSelection`, with tests.
2. Do not add a second `chunks.json` that can drift from the packaged one.
3. Do not add SwiftUI, SQLite, or ScriptureCore imports to GleanSelection or
   GleanCommentary.
4. Do not tune cooldowns in the app "just for a demo."

Verify no algorithm fork has crept into app sources:

```bash
! grep -R "normalCooldownDays\|struct GleanAlgorithm" ios/Glean Sources/ScriptureCore
```

## Selection rules (v1)

| Stage | Rule |
|-------|------|
| Hard filter | Skip if shown within 90 days (180 if `isPopular`) |
| +3.0 × matches | Preferred themes |
| +4.0 or +days | Never-seen bonus, else recency-of-return score |
| +2.0 | Genre not in last ~15 shows |
| +0.75 × n | Themes not in last ~10 shows |
| +1.0 | OT/NT rebalance when recent history is skewed |
| −0.35 | Mild popular dampener |
| Top-K | Weighted random among the top 3 scores |

## Corpus and pack tooling

64 formation passages with full BSB text, across hope, faith, love, wisdom,
prayer, repentance, suffering, joy, justice, creation, kingdom, identity, peace.

Expand only through the seed file, then rebuild and copy into the package
resource:

```bash
python3 content/selection/scripts/build_chunks.py \
  --seed content/selection/data/seed_passages.json \
  --out content/selection/data/chunks.json

cp content/selection/data/chunks.json Sources/GleanSelection/Resources/chunks.json
```

The script finds `scripture.sqlite` in the repo automatically. The rebuild is
deterministic; regenerating from an unchanged seed reproduces the shipped pack
byte for byte, which is worth checking after any change to the builder.
