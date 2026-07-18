# Content model

Status: first pass, for reaction, not a final answer. This is the actual product; the rest is plumbing, so it deserves to be argued with before any of it becomes code.

## What this doc is responsible for

Defining what a "chunk" is: the atomic unit the feed serves one of at a time. It is not responsible for what determines which chunk comes next (that's `feed-algorithm.md`) or how chunks are stored (that's `data-model.md`). But chunk design directly constrains both of those, so the tradeoffs below matter beyond this file.

## Three ways to define a chunk, and why none of them is free

**Fixed verse count** (e.g., always 3 to 5 verses). Simple to implement, uniform card size, trivial to generate for the entire text mechanically. Fails the moment verse boundaries don't line up with sentence or thought boundaries, which is often: Paul's sentences regularly run eight or more verses; narrative dialogue gets cut mid-exchange. This satisfies "digestible" and completely fails "just enough context" in exactly the passages where context matters most.

**Pericope** (a natural literary unit: a parable, a healing narrative, a psalm, a complete argument in an epistle). This is the theologically correct answer and the one closest to how Scripture was actually composed. It's also the expensive one: pericope boundaries aren't in the base translation text, they're editorial judgment. Most places you'd get them from (study Bible section headings, cross-reference systems) are themselves copyrighted editorial content, separate from the translation's copyright status. Building your own pericope boundaries for the entire canon is real theological and literary work, not an engineering task, and pericopes vary from 2 verses (a short proverb) to 40+ (a long narrative sequence), which breaks any assumption that chunks are roughly similar in reading time.

**Paragraph** (using the paragraph breaks already present in the base translation's own formatting, not a separately licensed section-heading scheme). The pragmatic middle ground: respects real sentence and thought boundaries without requiring new editorial content or a separate license. Most public domain translations (including the BSB and WEB candidates from `03-translation-research.md`) carry paragraph structure in their source formatting already, so this is extractable from data already being bundled, not a new asset. Paragraph length still varies by genre, which is what the next section is about.

**Recommendation: paragraph-based chunking as the default unit, with a soft length target rather than a hard rule.** Target roughly 40 to 120 words per chunk. A paragraph inside that range ships as-is. A paragraph under the floor gets merged with an adjacent paragraph (common in narrative, where a one-line paragraph is normal). A paragraph over the ceiling gets split at a sentence boundary nearest the midpoint, never mid-sentence. This is mechanical enough to automate for the full text, and it's a first pass specifically because the floor and ceiling numbers are guesses, not measured, and should change once real passages get tested against them.

## How the four genres actually differ

**Narrative** (Genesis, Samuel/Kings, the Gospels, Acts): closest fit for paragraph-based chunking as-is. Scenes and dialogue exchanges tend to already respect paragraph boundaries in most translations. Main risk is a scene that runs long (a full chapter of narrative can be one continuous scene); the split-at-sentence-boundary rule handles this without new logic, but a long narrative scene split into three consecutive chunks needs the feed to have some way of not serving them out of order to a new reader (a feed-algorithm concern, flagged here because it originates in this data).

**Poetry** (Psalms, Song of Songs, most prophetic oracles, chunks of Proverbs and Job): paragraph structure is often absent or meaningless in poetic text; the real unit is the line and the strophe (a small group of parallel lines building one image or thought). Chunking should follow strophe breaks where a translation marks them, or fall back to a fixed small number of poetic lines (roughly 4 to 8) when it doesn't. Many psalms are already close to ideal chunk size as a whole poem (100 to 400 words) and don't need splitting at all; the harder case is long psalms (119) and continuous prophetic oracles (long stretches of Isaiah or Jeremiah) that need real internal breaks. This genre needs its own pass in `data-model.md`, it should not inherit the paragraph rule from narrative.

**Epistle** (Paul's letters, the general epistles): the highest risk of decontextualization, because epistles are continuous argument, not scenes. A chunk that opens on "Therefore" or "But" without its antecedent is close to meaningless, and this happens constantly if paragraph boundaries are taken naively, because epistolary paragraphs are argumentative steps, not self-contained units. Concrete mitigation: when a candidate chunk's opening sentence starts with a connective (therefore, but, so then, for this reason, and similar), pull the chunk boundary back to include the sentence that connective is responding to, even if that pushes the chunk over the soft ceiling. Digestibility loses to comprehensibility here, deliberately.

**Law and genealogy** (large stretches of Leviticus, Numbers, portions of Deuteronomy and Chronicles): the genuinely hard case, and the one worth being honest about rather than engineering around. Priestly regulations and genealogical lists don't have the same "just enough context" problem narrative and epistle have, because there often isn't a self-contained "point" to a chunk of dietary law the way there is a point to a parable. Two honest options: chunk them the same mechanical way and accept that some chunks will read as dry, or give this content structurally lower selection weight in the feed rather than trying to force it into the same shape as everything else. That second option is a feed-algorithm decision, but it starts here, because it's really an admission that not all Scripture chunks the same way and pretending otherwise produces bad output quietly instead of surfacing the problem honestly.

## What "just enough context" means, concretely

Proposing a one-line setup shown above a chunk, but only the first time a reader encounters that book or major section, not every time. Something like "Paul, writing to the church in Philippi from prison" or "After the flood, God makes a promise to Noah." Once shown, it doesn't repeat for that reader on that book again, so a chunk on its twentieth appearance in someone's feed isn't carrying dead weight.

This has a real cost worth naming rather than hiding: writing an accurate, honest, non-tendentious one-line context note for every book (and likely for major internal sections of the longer books) is editorial work, roughly 66-plus short pieces of original writing that need to be theologically careful without editorializing into any one tradition's reading. That is a genuine, ongoing authorship task for a solo maintainer, not a one-time data entry job, and it should be named as a real scope item rather than assumed to be cheap.

Cheaper fallback for v1: generate the context line structurally instead of editorially, e.g. "Genesis, chapter 22" or "Philippians, chapter 2, verses 1 through 11," with no hand-written interpretive content at all. Thinner, but honest, fast to build, and it doesn't put untested theological framing in front of every reader on day one. Recommending this as the actual v1 default, with hand-written book intros as a deliberate post-v1 stretch goal once there's real usage to justify the ongoing authorship cost.

## The interface this hands to the feed algorithm

Whatever comes out of this chunking pass becomes the entire universe of things the feed can select from. Two consequences worth flagging now, to be solved in `feed-algorithm.md`, not here:

1. If chunk boundaries are too fine-grained or too context-poor, no feed algorithm can compensate; garbage in at the content-model layer is garbage out at the feed layer regardless of how clever the selection logic is.
2. A chunking model that treats all of Scripture as equally chunkable doesn't by itself solve the "whole counsel of Scripture vs. algorithmic comfort loop of the nice parts" problem raised in the original brief. That is fundamentally a selection-weighting problem, not a chunking problem, but it's worth stating here that this doc does not solve it, so it doesn't get quietly lost between the two documents.

## Open questions this doc leaves for you to react to

- Are the 40 to 120 word soft bounds even close to right? They're a guess, not a measurement against real text.
- Is genre-aware chunking (four different rule sets) worth the added engineering and editorial complexity versus one uniform rule applied everywhere, accepting that some chunks will read worse in some genres?
- Structural context lines for v1, hand-written for later: agree, or is thin context on day one worse than delaying launch to write real book intros first?
- Law and genealogy: chunk uniformly and accept some dry output, or build lower-weight handling from the start rather than retrofitting it later?
