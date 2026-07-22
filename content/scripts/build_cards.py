#!/usr/bin/env python3
"""
Assemble composite passage cards from a share-line draft.

Joins four sources into one reviewable card per anchor:
  - the passage text + reference          (GleanSelection chunks.json)
  - context neighbors (radius 2)          (scripture.sqlite, BSB)
  - historical voices for the passage     (GleanCommentary notes.json + sources.json)
  - a first-pass CTM reflection           (content/reflections/<name>.draft.json)

Integrity, enforced or surfaced, never hidden:
  - The share line must be a VERBATIM substring of the passage; fails the build
    otherwise (same guard as build_batch.py).
  - Each historical voice gets a locator ("on <ref>") but verbatim=false, because
    the excerpt has not been checked against the real public-domain source text;
    the review tool shows "excerpt unverified" until it is.
  - The CTM reflection is marked status=draft and confidence=personal; it is a
    ministry reflection, not claimed consensus, and Tim rewrites it in review.

Usage:
  python3 content/scripts/build_cards.py \
    content/batches/batch-01-anchors.draft.json \
    content/reflections/anchors.draft.json
"""

import json
import sqlite3
import sys
import unicodedata
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
CHUNKS = REPO / "Sources/GleanSelection/Resources/chunks.json"
NOTES = REPO / "Sources/GleanCommentary/Resources/notes.json"
SOURCES = REPO / "Sources/GleanCommentary/Resources/sources.json"
DB = REPO / "Sources/ScripturePreview/Resources/scripture.sqlite"

NEIGHBOR_RADIUS = 2

BOOK_ORDER = {  # only the books our anchors touch; extend as batches grow
    "Genesis": 1, "Exodus": 2, "Deuteronomy": 5, "Ruth": 8, "Job": 18,
    "Psalms": 19, "Proverbs": 20, "Ecclesiastes": 21, "Isaiah": 23,
    "Jeremiah": 24, "Lamentations": 25, "Micah": 33, "Matthew": 40, "Mark": 41,
    "Luke": 42, "John": 43, "Acts": 44, "Romans": 45, "1 Corinthians": 46,
    "2 Corinthians": 47, "Galatians": 48, "Ephesians": 49, "Philippians": 50,
    "1 Thessalonians": 52, "Hebrews": 58, "James": 59, "1 Peter": 60,
    "1 John": 62, "Revelation of John": 66,
}


def normalize(s):
    s = unicodedata.normalize("NFC", s)
    for a, b in [("“", '"'), ("”", '"'), ("‘", "'"), ("’", "'"), ("—", "-")]:
        s = s.replace(a, b)
    return s


def context_lines(db, book, chapter, start, end):
    order = BOOK_ORDER.get(book)
    if order is None:
        return [], []
    cur = db.cursor()

    def fetch(vs):
        if not vs:
            return []
        q = ",".join("?" for _ in vs)
        cur.execute(
            f"SELECT verse, text FROM verses WHERE translation='BSB' "
            f"AND book_order=? AND chapter=? AND verse IN ({q}) ORDER BY verse",
            [order, chapter, *vs],
        )
        return [{"ref": f"{book} {chapter}:{v}", "text": t} for v, t in cur.fetchall()]

    before = fetch([v for v in range(start - NEIGHBOR_RADIUS, start) if v >= 1])
    after = fetch(list(range(end + 1, end + 1 + NEIGHBOR_RADIUS)))
    return before, after


def main():
    if len(sys.argv) != 3:
        print("usage: build_cards.py <anchors.draft.json> <reflections.draft.json>", file=sys.stderr)
        return 2

    draft = json.loads(Path(sys.argv[1]).read_text())
    reflections = json.loads(Path(sys.argv[2]).read_text())["reflections"]
    chunks = {c["id"]: c for c in json.loads(CHUNKS.read_text())["chunks"]}
    notes = json.loads(NOTES.read_text())["notes"]
    sources = {s["id"]: s for s in json.loads(SOURCES.read_text())["sources"]}
    db = sqlite3.connect(DB)

    errors, cards = [], []

    for i, item in enumerate(draft["items"]):
        cid = item["chunkId"]
        chunk = chunks.get(cid)
        if chunk is None:
            errors.append(f"[{i}] chunk {cid} not found")
            continue

        line = item["shareLine"]
        if normalize(line) not in normalize(chunk["text"]):
            errors.append(f"[{i}] {cid}: share line is not a verbatim substring")
            continue

        # historical voices: any note within this chunk's verse range
        voices = []
        for n in notes:
            if (n["book"] == chunk["book"] and n["chapter"] == chunk["chapter"]
                    and chunk["startVerse"] <= n["verse"] <= chunk["endVerse"]):
                src = sources.get(n["sourceId"], {})
                voices.append({
                    "source": src.get("author", n["sourceId"]),
                    "work": src.get("work"),
                    "locator": f"on {n['focusReference']}",
                    "verbatim": False,  # not yet checked against the PD source text
                    "confidence": n["confidence"],
                    "text": n["text"],
                })

        before, after = context_lines(
            db, chunk["book"], chunk["chapter"], chunk["startVerse"], chunk["endVerse"]
        )

        reflection = reflections.get(cid)
        ctm = None
        if reflection:
            ctm = {
                "source": "Common Table Ministries",
                "confidence": "personal",
                "status": "draft",
                "text": reflection,
            }

        cards.append({
            "id": f"{cid}#card",
            "reviewDecision": None,
            "translation": chunk.get("translation", "BSB"),
            "reference": chunk["reference"],
            "photo": {"status": "none", "note": "Birchwood farm photo goes here for the share background."},
            "focus": {
                "reference": item.get("shareLineReference", chunk["reference"]),
                "text": line,
                "standsAlone": bool(item.get("standsAlone", False)),
                "source": "scripture-verbatim",
            },
            "passage": {"reference": chunk["reference"], "text": chunk["text"]},
            "context": {"before": before, "after": after},
            "historicalVoices": voices,
            "ctmReflection": ctm,
        })

    if errors:
        print(f"BUILD FAILED: {len(errors)} problem(s)", file=sys.stderr)
        for e in errors:
            print("  " + e, file=sys.stderr)
        return 1

    out = {
        "batch": draft["batch"] + "-cards",
        "kind": "passageCard",
        "count": len(cards),
        "items": cards,
    }
    out_path = REPO / "content/batches/batch-01-anchors.cards.json"
    out_path.write_text(json.dumps(out, indent=2, ensure_ascii=False) + "\n")

    with_voices = sum(1 for c in cards if c["historicalVoices"])
    with_ctm = sum(1 for c in cards if c["ctmReflection"])
    print(f"OK  {len(cards)} cards -> {out_path.relative_to(REPO)}")
    print(f"    {with_voices}/{len(cards)} have historical voices, {with_ctm}/{len(cards)} have a CTM draft")
    missing = [c["id"] for c in cards if not c["historicalVoices"]]
    if missing:
        print(f"    no historical voice yet: {missing}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
