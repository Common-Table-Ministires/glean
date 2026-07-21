# Integrity charter — GleanSelection

This document protects the **independence** of the selection brain so reader apps cannot accidentally fork or dilute it.

## Single source of truth

| Concern | Lives only in |
|---------|----------------|
| Scoring weights, cooldowns, top‑K | `Sources/GleanSelection/GleanAlgorithm.swift` |
| Formation pack (`chunks.json`) | `Sources/GleanSelection/Resources/` (+ `data/` for tooling) |
| Seed boundaries / themes | `data/seed_passages.json` |
| Seen-history persistence API | `SeenHistoryStore.swift` |
| Feed session orchestration | `GleanFeedSession.swift` |

## Allowed consumers

- ScripturePreview (macOS) via SPM product `GleanSelection`
- Glean (iOS) via SPM product `GleanSelection`
- Future clients (same dependency rule)

## Forbidden

1. Copying `GleanAlgorithm.swift` (or scoring constants) into `sarah/glean` or any app target  
2. Embedding a second `chunks.json` that diverges from this package’s resource  
3. Adding SwiftUI, SQLite, or ScriptureCore types **into** this package  
4. Changing cooldowns only in the app “for a demo”  

## How to change selection behavior

1. Open **this** package (`Desktop/biblealgo` / future `glean-selection` repo)  
2. Add/adjust tests in `Tests/GleanSelectionTests`  
3. `swift test` here until green  
4. Bump consumers (path dependency rebuilds automatically)  

## Verification

```bash
# Brain alone
cd ~/Desktop/biblealgo && swift test

# No algorithm fork in reader repo
! grep -R "GleanAlgorithm\|normalCooldownDays" ~/sarah/glean/Sources ~/sarah/glean/ios 2>/dev/null
```
