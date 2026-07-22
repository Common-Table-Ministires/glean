#!/usr/bin/env python3
"""
Build a review-ready content batch from a draft.

A share-line draft names a chunk and a clip. This script joins the clip against
the real chunk text in the shipped pack, enforces the one integrity rule that
matters for share lines, and emits a pack the review tool can open.

The rule: a share line must be a VERBATIM substring of its chunk's Scripture
text. Not a paraphrase, not a "close enough." If it is not an exact substring,
the build fails loudly and names the item. That makes the safe kind of authored
content (selecting words already in the public-domain text) safe by
construction, and blocks the unsafe kind (quietly rewording Scripture).

Usage:
  python3 content/scripts/build_batch.py content/batches/batch-01-anchors.draft.json

Writes <name>.json next to the draft, with tier, provenance, and the resolved
reference for each item, ready to drag into tools/review/index.html.
"""

import json
import sys
import unicodedata
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
PACK = REPO / "Sources/GleanSelection/Resources/chunks.json"

# Tier boundaries from docs/07-content-engine-plan.md, on share-line word count.
def tier_for(words: int) -> str:
    if words <= 12:
        return "hero"
    if words <= 30:
        return "standard"
    if words <= 60:
        return "passage"
    return "notImage"  # too long for a graphic; reference + read-in-Glean instead


def normalize(s: str) -> str:
    # The pack uses curly quotes and an em dash in places; normalize both sides
    # the same way so a correct clip is not rejected over a quote-character
    # mismatch. This normalizes punctuation only, never words.
    s = unicodedata.normalize("NFC", s)
    for a, b in [("“", '"'), ("”", '"'), ("‘", "'"), ("’", "'"), ("—", "-")]:
        s = s.replace(a, b)
    return s


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: build_batch.py <draft.json>", file=sys.stderr)
        return 2
    draft_path = Path(sys.argv[1])
    draft = json.loads(draft_path.read_text())
    pack = json.loads(PACK.read_text())
    by_id = {c["id"]: c for c in pack["chunks"]}

    errors = []
    out_items = []

    for i, item in enumerate(draft["items"]):
        cid = item["chunkId"]
        line = item["shareLine"]
        chunk = by_id.get(cid)
        if chunk is None:
            errors.append(f"[{i}] chunkId '{cid}' not found in pack")
            continue

        if normalize(line) not in normalize(chunk["text"]):
            errors.append(
                f"[{i}] {cid}: share line is NOT a verbatim substring of the chunk text.\n"
                f"       line:  {line}\n"
                f"       chunk: {chunk['text'][:120]}..."
            )
            continue

        words = len(line.split())
        out_items.append({
            "id": f"{cid}#share",
            "chunkId": cid,
            "reference": chunk["reference"],
            "shareLineReference": item.get("shareLineReference", chunk["reference"]),
            "shareLine": line,
            "wordCount": words,
            "tier": tier_for(words),
            "standsAlone": bool(item.get("standsAlone", False)),
            "translation": chunk.get("translation", "BSB"),
            # Provenance: the words are verbatim Scripture; the editorial act is
            # the SELECTION, which is what review signs off on.
            "source": "scripture-verbatim",
            "confidence": "widelyHeld",
            "reviewDecision": None
        })

    if errors:
        print(f"BUILD FAILED: {len(errors)} problem(s)\n", file=sys.stderr)
        for e in errors:
            print("  " + e, file=sys.stderr)
        return 1

    out = {
        "batch": draft["batch"],
        "kind": draft["kind"],
        "builtFrom": draft_path.name,
        "count": len(out_items),
        "items": out_items,
    }
    out_path = draft_path.resolve().with_name(draft_path.name.replace(".draft", ""))
    out_path.write_text(json.dumps(out, indent=2, ensure_ascii=False) + "\n")

    tiers = {}
    for it in out_items:
        tiers[it["tier"]] = tiers.get(it["tier"], 0) + 1
    try:
        shown = out_path.relative_to(REPO)
    except ValueError:
        shown = out_path
    print(f"OK  {len(out_items)} items -> {shown}")
    print(f"    tiers: {tiers}")
    over = [it["shareLineReference"] for it in out_items if it["tier"] == "notImage"]
    if over:
        print(f"    note: {len(over)} over 60 words, not image material: {over}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
