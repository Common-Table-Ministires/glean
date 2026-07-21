# Glean

An open-source Scripture reading app owned by [Common Table Ministries](https://commontableministries.com). Free, forever, asks nothing. If people want to give, it links out to the ministry, tax-deductible, but nothing in the app is gated behind it.

## Why

Bible software nickel-and-dimes people: paywalled study notes, subscription tiers, ads inside the text. Glean is the opposite on every axis. It's also not verse-of-the-day (too thin, no context) and not a reading plan (carries an obligation, most people fall behind and quit). It's a scrollable feed of digestible Scripture passages, each with just enough context to stand on its own, read one or read twenty, no streaks, no completion state, no guilt.

Full reasoning in [docs/00-vision.md](docs/00-vision.md).

## Status

Early. What exists right now is a macOS desktop app used as a fast iteration testbed while the content model and interaction design get worked out, not the shipped product. The real iOS app hasn't been started yet. Nothing here has been through an App Store review or a real user beyond the person building it.

## What's in this repo

```
docs/         vision, design principles, translation licensing research, moderation design
spec/         the content model (how Scripture gets chunked for the feed)
decisions/    ADRs for load-bearing technical calls
Sources/
  ScriptureCore/     data layer, chunking logic, models (translation-agnostic, meant to be reused by the iOS app)
  ScripturePreview/  the macOS desktop prototype UI (thin client of GleanSelection for Feed)
Tests/        unit + integration tests for ScriptureCore
scripts/      build-mac-app.sh packages the prototype as a real .app bundle
```

## Integrity: selection and commentary are separate projects

The formation **selection algorithm** (cooldowns, themes, top‑K, curated pack) lives in a **standalone package**:

- Path (this machine): `~/Desktop/biblealgo` (SPM product **`GleanSelection`**)
- Apps depend on it via SPM path dependency — **do not copy** `GleanAlgorithm` or packs into this repo
- ScriptureCore stays SQLite + Stories/Study; it does not absorb scoring logic

Open / public-domain **commentary** is also standalone:

- Path: `~/sarah/gleancommentary` (SPM product **`GleanCommentary`**)
- Short signed excerpts only; never interleave into Scripture or the flip card
- See that package’s `INTEGRITY.md`

```bash
# Selection package tests (canonical brain)
cd ~/Desktop/biblealgo && xattr -cr . && swift test

# Commentary pack tests
cd ~/sarah/gleancommentary && xattr -cr . && swift test
```

## Running the desktop prototype

Requires Xcode 15+ and macOS 14+.

```
swift run ScripturePreview
```

`swift run` alone produces a bare executable with no Dock icon. For something that behaves like a real Mac app:

```
./scripts/build-mac-app.sh
open .build/out/Products/Debug/ScripturePreview.app
```

## Testing

```
swift test
```

## Translations

Bundled locally, no network dependency: [Berean Standard Bible](https://berean.bible) (public domain, CC0) and the King James Version (public domain). See [docs/03-translation-research.md](docs/03-translation-research.md) for why these and not something like NIV or ESV.

## License

Not finalized yet. The intent, stated in [docs/00-vision.md](docs/00-vision.md), is a license that keeps this free and open while preventing someone from forking it, adding ads, and shipping a paid version. Don't assume MIT/Apache-style permissiveness until `docs/06-license-choice.md` lands with a real recommendation.

## Security

See [SECURITY.md](SECURITY.md).

## Contributing

Not yet formally open to outside contributors; the core direction is still being worked out in `/docs` and `/decisions`. Issues and discussion are welcome.
