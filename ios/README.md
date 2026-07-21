# Glean — iOS app

Native iOS client for **Glean** (Common Table Ministries).

- **Bundle ID:** `org.commontableministries.glean`
- **iOS:** 17.0+
- **Tabs:** Feed · Stories · Study · Settings
- **Selection brain:** [GleanSelection](../../../Desktop/biblealgo) (separate package — not vendored)

## Open in Xcode

```bash
cd ~/sarah/glean/ios
xcodegen generate          # regenerate project from project.yml
open Glean.xcodeproj
```

Pick an **iPhone simulator** (or a device once the CTM Apple org is available), then Run (⌘R).

## Build from the command line

```bash
cd ~/sarah/glean/ios
xcodegen generate
xcodebuild \
  -project Glean.xcodeproj \
  -scheme Glean \
  -destination 'generic/platform=iOS Simulator' \
  -configuration Debug \
  build
```

## Integrity

| Package | Role |
|---------|------|
| `ScriptureCore` (`../`) | Offline BSB/KJV SQLite, stories, study |
| `GleanSelection` (`~/Desktop/biblealgo`) | Formation feed algorithm + curated pack |

Do **not** copy algorithm sources into this app target.

## What you get

1. **Feed** — formation passages via `GleanFeedSession` (cooldowns + formation themes)
2. **Stories** — curated narrative arcs, sequential reading
3. **Study** — book/chapter/verse picker + notes
4. **Settings** — translation, text size, OpenDyslexic, **curated look & feel themes**, donate link

### Curated appearance themes (no theme maker)

Pick one in **Settings → Look & feel**:

| Category | Themes | Typeface |
|----------|--------|----------|
| Default | System | System Serif |
| Natural | Parchment, Forest | Palatino, Georgia |
| Minimalist | Plain, Ink | SF Pro |
| Feminine | Blush, Lavender | Optima, Hoefler Text |
| Masculine | Slate, Navy | Futura, Baskerville |
| Kids | Sunshine, Ocean | Rounded, Noteworthy (slightly larger) |

Dyslexia-friendly font still overrides the theme face when enabled.

Offline-first: full Bible text is bundled in `Glean/Resources/scripture.sqlite`.

### Open commentary (`GleanCommentary`)

Sibling package: `~/sarah/gleancommentary`. Public-domain voices (Henry, Calvin, Chrysostom, JFB, …) ship as signed short excerpts on the feed **context** page only — never on the flip card.
