# ADR 0001: Swift native to start, one native codebase per platform going forward

## Status

Decided.

## Context

The project needs a client platform choice. Options considered: a cross-platform framework (React Native, Flutter) that ships one codebase to iOS and Android at once, versus native per-platform (Swift/SwiftUI for iOS, Kotlin for Android, and so on as more platforms get added).

An earlier prototype (VerseFlow, the personal precursor to this project) was already built native in SwiftUI, so real working infrastructure exists in that direction: a proven offline SQLite pipeline for public domain translation text, a signing and archive/export pipeline, and a working feed UI shell. None of that transfers to a cross-platform rewrite.

## Decision

Swift native for iOS to start. When other platforms get built (Android named explicitly as "all apps in future"), each one is its own native codebase rather than a shared cross-platform layer.

## Tradeoffs, named plainly

**What this buys:** no dependency on a third-party cross-platform framework's release cycle, bugs, or abandonment risk (relevant directly to the "boring and durable" principle). Full, direct access to each platform's real accessibility APIs (VoiceOver on iOS, TalkBack on Android) rather than whatever a cross-platform framework's abstraction layer exposes, which matters directly for the accessibility principle. Reuses real working code that already exists rather than discarding it.

**What this costs:** every future platform is a separate codebase to build and maintain, not a shared one. Over ten years, with a solo maintainer, "one app on N platforms" done natively means N times the ongoing maintenance surface: N sets of platform SDK updates to track, N places a bug gets fixed, N places the content model and feed logic get reimplemented and kept in sync by hand. This is in real tension with the "design for a solo maintainer over ten years" principle, not a clean win for it. The bet being made here is that avoiding cross-platform framework risk is worth more than avoiding duplicated maintenance, for a project meant to last a decade. That bet should be revisited explicitly if a second platform (Android) actually gets scheduled, rather than assumed to still be the right call by default.

**Mitigation to consider later, not decided now:** the content model, chunking logic, and translation data pipeline are the parts most worth sharing across platforms even if the UI layer stays native per-platform. If a second platform gets built, worth a real look at extracting that shared logic (data prep, chunking rules) into something platform-agnostic (a build-time pipeline producing the same SQLite file for both platforms, for instance) rather than reimplementing chunking logic twice. Not needed yet since there's only one platform.

## Revisit if

A second platform actually gets scheduled. This decision should not be assumed to still hold without checking it against actual maintenance capacity at that time.
