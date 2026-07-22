# Content engine plan

The features designed across the sessions of 2026-07-19 to 2026-07-22, written
down before building so the hard content decisions get argued on paper first.
This is the pattern the whole project has held: spec the content, then build the
plumbing.

## The thesis, in one line

What keeps people opening Glean is not a streak; it is that there is always
something new and good here. Fresh curated content is the retention engine, and
it is the one retention engine consistent with `01-principles.md`. Everything
below serves that.

## The four features, and how they are actually one system

They looked like four requests. They are one graph with four views:

1. **Tiered passage content** decides what shows on a share image, what shows on
   a Feed card, and what is Study-only.
2. **Characters** are curated sets of passage ranges about a person.
3. **Supporting passages** are what fills in a character or a theme; the same
   mechanism as characters, seen from the other side.
4. **The through-line** is the spine all of it hangs on.

The unifying move: define people, themes, and the spine as **sets of reference
ranges**, then let any passage in the app ask "what am I part of?" by range
intersection. Author a character once; every Feed card, Study verse, and Story
that touches its range gets the link for free. No per-chunk tagging.

## The integrity spine (applies to every feature below)

One rule governs all generated content, learned from the existing 28 commentary
notes that read like Chrysostom but cannot be sourced to Chrysostom:

> Words attributed to a historical author must be that author's words, with a
> locator anyone can check. Words that are Common Table Ministries' synthesis
> must be signed as CTM's, with a confidence tag. An LLM selects, excerpts,
> trims, and drafts CTM's own voice; it never writes in a dead author's voice.

Enforced by three schema fields on anything authored or quoted: `source`,
`locator` (or `verbatim: true`), `confidence`. The review tool
(`tools/review/`) already flags the missing-locator case loudly.

## Trust tiers (what needs how much review)

Review is the bottleneck, not drafting. An LLM can draft 500 items in an
afternoon that would take months to review, and unreviewed theology is the one
thing this app cannot ship. So content is tiered by how much scrutiny it needs,
and the pipeline is designed to make review fast, not generation fast.

| Tier | Example | Source | Review |
|------|---------|--------|--------|
| Imported | OpenBible cross-references, TSK | CC-BY / PD, labeled as a traditional apparatus | None; provenance field makes shipping honest |
| Derived | Inbound-reference anchor ranking, range intersection | Computed from imported data | Spot-check |
| Authored | Share lines, arc beats, character blurbs, the through-line | CTM voice, LLM-drafted then reviewed | Every item, in the review tool |

## Sources (all confirmed available and license-clear)

- **OpenBible.info cross-references**: ~340k references, CC-BY, 2MB zip, offline,
  no API. The raw material of the engine. Attribution only.
- **CCEL public-domain commentary**: Matthew Henry, Calvin (Beveridge 1845
  translation, PD; not the 1960 Battles), JFB, Schaff's Nicene and Post-Nicene
  Fathers (1880s translations, PD; not modern ones). Structured, with locators.
- **The through-line**: written by CTM, scaffolded on the **1689 London Baptist
  Confession** (public domain, and the actual Reformed-Baptist confession, which
  fits the ministry's own position without importing copyrighted prose or a
  dispensational framework). No good modern redemptive-historical through-line is
  usable: Vos is under copyright until 2044, and the PD alternatives are either
  dispensational (Scofield) or not narratives (confessions, Nave's).
- **Additional translations**: several public-domain, ~6MB each in the existing
  SQLite schema (ASV, YLT, Geneva 1599, Darby, Webster, NHEB, JPS, Douay-Rheims,
  Tyndale). Candidates for remote packs, not bundle weight. Pick ones with a job
  (one hyper-literal for study; Geneva for the Reformed resonance), do not bundle
  all of them just because they are free.

## Delivery: remote packs, no App Store review per batch

Offline-first means works without network, not never touches network. So:

- A **baseline pack ships in the bundle.** The app works fully on first launch,
  on a plane, forever, with no network. Principle intact.
- **Incremental packs fetch when there is network**, cache locally, are read from
  cache thereafter.
- Content updates need **no App Store review**. This is the unlock that makes
  "always something new" possible on a solo maintainer's schedule.
- **Hosting is free and already exists**: serve packs from this repo's GitHub
  Releases. No Firebase, no CDN, no bill, versioned by default, philosophically
  consistent with being open source.

Packs are versioned with compatibility gating so a v0.2 app does not choke on a
v0.5 pack. Batch by **coherence**, not raw count: ship "Abraham" or "the theme of
mercy," a unit users understand, with 32 chunks as a floor rather than the
trigger.

## Schema additions

On `ScriptureChunk` (baked into the pack at build time; zero runtime cost, keeps
cold start under two seconds):

```
shareLine: String?          // curated quotable line; nil = not share-card material
shareLineReference: String? // may be sub-verse, e.g. "John 3:16a"
standsAlone: Bool           // does tier 1/2 make sense with no prior reading?
```

New `Character` model (in GleanSelection or a new content target, never the app):

```
Character: id, name, alsoKnownAs[], testament, era, whoTheyAre, themes[], related[]
  arc: [ArcBeat]     // ordered; ranges may cross books
  echoes: [RangeRef] // where the rest of canon reflects on them
ArcBeat: title, range, role(.key|.supporting), oneLine, confidence
```

Presentation tiers, derived from word count of `shareLine ?? focusText`:

| Words | Tier | Treatment |
|-------|------|-----------|
| <= 12 | Hero | Large type, image breathes, 1:1 or 9:16 |
| 13-30 | Standard | Moderate type, the common case |
| 31-60 | Passage | Smaller type, tighter leading, 4:5 |
| 60+ | Not an image | Reference + "read it in Glean", full text in share payload |

## Known code changes this forces

- **Cross-book ranges.** `Story.swift` warns its own single-book assumption
  breaks here; character arcs are cross-book by nature (Abraham is Genesis, but
  Romans 4 and Hebrews 11 are the point). The range query and
  `ScriptureStore.chunks(for:)` need the cross-book rewrite. Contained, but real,
  and better known now than mid-authoring.
- **Feed quality gate.** `standsAlone` becomes a filter on Feed candidates
  (Study bypasses it). A chunk that opens on "Therefore" or an unresolved "he"
  earns Study but not Feed. This improves the feed whether or not share images
  ever ship. Ship it advisory-first so the counts are visible before it changes
  behavior.

## One decision still open

**Jesus is not one entry in a list next to Jonah.** For a ministry app this is
not cosmetic. Options: the through-line every arc points toward rather than a
browsable entry; a structurally different treatment (the Gospels as their own
mode); or a flat list where ordering carries the weight. Decide before the
character data model hardens; it is expensive to change after. Recommendation:
the spine, not a list entry, with the through-line doc as the artifact that makes
that concrete.

## Sequence

Plumbing is cheap now (corpus is 64 chunks) and expensive to retrofit later.
Volume is expensive always and needs signal from real use. So build the pipe
before turning up the flow, and dial the interface in between.

**Phase A: the pipe (architectural, do while content is tiny)**
- Schema fields with provenance and confidence.
- Remote-pack fetch/cache with the bundled baseline. ADR for this decision; it
  is the biggest architectural call since choosing native Swift.
- Pull OpenBible cross-references; compute inbound-reference anchor ranking over
  the existing 64 chunks. Pure data, no editorial risk, and it immediately tells
  you which of the 64 are anchors and which are filler.
- Locator + verbatim fields on commentary; re-source the existing 28 notes
  against real CCEL texts.

**Phase B: interface dial-in (needs real use)**
- Share-image export (ImageRenderer, reuse the 11 themes as styles, three aspect
  ratios, tiers driving type size, farm-photo backgrounds as a CTM-owned asset).
- Character browse for a narrow spine set: ~12 people (Abraham, Moses, David,
  Ruth, Esther, Daniel, Mary, Peter, Paul, John, plus two), proving the model
  before committing to 60.

**Phase C: cadence (the retention engine, ongoing)**
- Write the through-line (~12-20 beats, scaffolded on the 1689).
- First real content batch shipped as a remote pack, end to end, proving the
  pipe.
- Then batches by coherence, on whatever schedule six hours a week sustains.

## What is already done toward this

- **Review tool** (`tools/review/`), tested, flags the integrity gap.
- **Commentary package** with signed sources, license rows, confidence tags.
- **`FeedPassage`** already separates focus from context, which is two of the
  four tiers.
- **The 11-theme system**, which is most of a share-image style system already.
