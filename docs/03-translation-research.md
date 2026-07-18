# Translation research

Status: first pass, based on publicly available licensing statements as of 2026-07-18. This is not legal advice. Before shipping, get a one-line email confirmation from the copyright holder of whichever translation is chosen; it costs nothing and a ten-year project shouldn't rest on a web search. Flagging that explicitly rather than quietly assuming it away.

## The constraint

From [01-principles.md](01-principles.md): the full text must live on the device, offline, forever, for free. That rules out anything that:

- requires a live network call to display text (most commercial-translation APIs restrict or forbid this),
- caps how much of the translation can be shown or stored (many "free quotation" permissions cap out around 500 verses or 25% of a book, which a scrolling feed will blow through quickly by design),
- charges a per-app or per-download fee (conflicts with "free, forever" directly, and creates a recurring bill a nonprofit with near-zero margin has to keep paying),
- could be revoked or renegotiated by a publisher at will (a single point of failure for a ten-year project).

That leaves two real categories: genuinely public domain, or explicitly licensed for free redistribution with terms narrow enough to actually satisfy the above.

## Public domain candidates (no restrictions, no ongoing risk)

| Translation | Era / style | Notes |
|---|---|---|
| **Berean Standard Bible (BSB)** | Modern (2020s), readable | Released CC0 (full public domain) by the translation team in April 2023, specifically so it could never be re-copyrighted or locked up commercially. Modern English, no archaic phrasing. No attribution legally required (appreciated, not required). This is the strongest candidate for the primary reading translation. |
| **King James Version (KJV)** | 1611/1769, archaic | Public domain everywhere except the UK (Crown copyright, irrelevant for a US nonprofit's US-hosted app). Culturally load-bearing for a large share of the target audience; some readers specifically want this over anything modern. |
| **World English Bible (WEB)** | Modern, literal | Public domain, explicitly dedicated to the public domain by its translators for this exact purpose. Renders the divine name as "Yahweh" rather than "LORD," which some readers find unfamiliar or jarring; worth knowing going in. |
| American Standard Version (ASV, 1901), Young's Literal Translation (YLT), Darby | Older, formal/literal | Public domain, lower priority; useful as future secondary options, not needed for v1. |

**Recommendation for v1: BSB as the default/primary translation, KJV available as a secondary option.** Both are unrestricted, so offering both costs nothing legally and nothing technically once one pipeline exists (see below). WEB can be added later the same way if there's demand for it specifically; nothing about BSB replaces it, it's just less essential now that BSB exists and solves the "modern and unrestricted" need on its own.

## Explicitly-licensed-but-restricted (evaluated and excluded for v1)

| Translation | Why it doesn't fit |
|---|---|
| **NET Bible** | Free to *quote* with attribution and a required hyperlink, but full-text redistribution or bundling into an app without a separate written agreement is explicitly restricted. Fails "full text local, no network dependency." |
| **Lexham English Bible (LEB)** | Royalty-free to give away, but with a distribution-volume reporting requirement (must report annually once distribution/sales exceed certain thresholds) and a cap on what percentage of a larger work it can comprise if sold. Not disqualifying on its face, but it's an ongoing compliance obligation for a solo maintainer where BSB has none. Revisit only if BSB turns out to have some unforeseen issue. |

## Commercial translations (excluded, hard blocker)

NIV, ESV, NLT, NASB, and similar modern translations are all owned by publishers (Biblica/Zondervan, Crossway, Tyndale, Lockman) who license them individually, case-by-case, usually with a recurring fee once an app exceeds free-quotation limits. Specifically checked for NIV via api.bible (the standard developer channel for licensed Bible text): **NIV is excluded from commercial licensing on that platform entirely**, and Biblica requires direct negotiation with royalties "determined on a case-by-case basis," i.e. no fixed, quotable number exists until you ask. NIV text also cannot be cached offline in a mobile app under Biblica's terms, streaming only, which independently disqualifies it under the offline-first principle even if the cost were free.

None of these are viable for the core reading experience. Not revisiting this unless the ownership or funding model changes fundamentally, which principle 3 (no ads, no paywall) makes unlikely.

## Technical note

A working pipeline for exactly this already exists from an earlier prototype: public-domain translation text (tested with KJV) pulled from structured, verse-level JSON sources on GitHub, normalized into a shared `book / chapter / verse / text` schema, and bundled as a local SQLite database inside the app, no runtime dependency. The same source repository that had KJV also has BSB available in the same structured format, so extending that pipeline to BSB is mechanical, not a new research problem. Full details deferred to `spec/data-model.md` when that's drafted.

## Open items this doc doesn't resolve

- Whether to ship with one translation or two at launch (BSB only, vs. BSB + KJV). Leaning toward both, since the marginal cost is near zero and it directly serves "no gatekeeping," someone who trusts KJV more shouldn't be forced into a translation they don't trust. Real decision, not defaulted here.
- Confirming BSB's CC0 status directly with the Berean Bible Translation Committee / Bible Hub before shipping, per the caveat at the top of this doc.
