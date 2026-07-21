# Content review tool

A single self-contained HTML file for walking through a content pack and
approving, rejecting, editing, or flagging each item. No build step, no
dependencies, no network; it runs from `file://` and nothing leaves the machine.

## Use it

Open `index.html` in a browser, then drag in a pack:

- `gleancommentary/Sources/GleanCommentary/Resources/notes.json`
- `biblealgo/Sources/GleanSelection/Resources/chunks.json`
- or any JSON with a top-level array of objects

Work through the items, then **Export reviewed JSON**. The export writes
`<name>.reviewed.json` next to your downloads; diff it against the original
before committing.

## Keyboard

Review throughput is the whole point, so it's keyboard-first:

| Key | Action |
|-----|--------|
| `A` | Approve and advance |
| `R` | Reject and advance |
| `F` | Flag and advance (keeps your question) |
| `E` | Edit the text in place |
| `←` `→` | Move without deciding |
| `Esc` | Close the editor / unfocus |

## What it writes

Each item gains only these fields; nothing existing is modified:

```json
"reviewDecision": "approved" | "rejected" | "flagged",
"reviewedAt": "2026-07-21",
"reviewNote": "your question, if you left one",
"reviewedText": "only present if you edited the text"
```

Progress is saved to `localStorage` as you go, so closing the tab does not lose
a session.

## The "no locator" warning

Any item that names a `sourceId` (attributing words to Matthew Henry, Calvin,
Chrysostom, and so on) but carries no `locator`, `citation`, or `verbatim: true`
gets a loud **NO LOCATOR** chip.

That combination means the pack is attributing words to a real historical author
without anything tying them to a findable place in that author's actual work. It
is the one error a ministry app cannot take back, so the tool surfaces it rather
than letting it pass quietly. Flag those and re-source them against a real
public-domain text before approving.

## Flagged items

Flagging is for "I need to talk about this," not "this is wrong." Export the
pack, and the flagged items plus their questions are the agenda for a working
session.
