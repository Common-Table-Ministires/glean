# Content pipeline

Where curated content is authored, validated, and reviewed before it ships in a
pack. See `docs/07-content-engine-plan.md` for the strategy; this is the how.

## The loop

```
draft  →  build (validate)  →  review  →  ship
```

1. **Draft** a batch as `content/batches/<name>.draft.json`. Small, coherent
   units (a theme, a character, "the anchors"), not one giant file.
2. **Build** it: `python3 content/scripts/build_batch.py <draft>`. This joins
   each item against the real Scripture pack, enforces the integrity rule for
   that content kind, computes derived fields (tier, word count), and writes
   `<name>.json`. A failing build names the problem item and writes nothing.
3. **Review** the built `<name>.json` by dragging it into
   `tools/review/index.html`. Approve / reject / edit / flag, keyboard-driven.
   Export the reviewed JSON when done.
4. **Ship**: reviewed content folds into a release pack. (Remote-pack delivery
   is Phase A of the plan; not built yet.)

## Batch kinds

**`shareLine`**: a quotable clip for a Feed card or share image. The integrity
rule is verbatim: a share line must be an exact substring of its chunk's BSB
text, so it is a *selection* of public-domain Scripture, never a paraphrase of
it. `build_batch.py` fails the build if any line is not an exact substring; try
it by editing one word of a line and rebuilding. Words that read as Scripture on
a shareable image must actually be Scripture.

Later kinds (commentary excerpts, character arc beats, through-line) carry the
stricter rule from the plan: attributed words need a locator; authored words are
signed as CTM's with a confidence tag. The review tool already flags the
missing-locator case.

## Layout

```
content/
  batches/
    batch-01-anchors.draft.json   # hand-authored input
    batch-01-anchors.json         # built + validated, review-ready (regenerable)
  scripts/
    build_batch.py                # validate + derive + emit
  selection/
    data/                         # seed + built chunk pack (formation tooling)
    scripts/                      # build_chunks.py, demo_select.py
```

The built `*.json` files are regenerable from their drafts, but are checked in so
a reviewer can open one without running Python first.
