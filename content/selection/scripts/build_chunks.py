#!/usr/bin/env python3
"""
Build Glean chunks.json from:
  - data/seed_passages.json  (boundaries + themes)
  - scripture.sqlite         (BSB/KJV verse text from ScripturePreview)

Usage:
  python3 scripts/build_chunks.py
  python3 scripts/build_chunks.py --db /path/to/scripture.sqlite --seed data/seed_passages.json --out data/chunks.json
"""

from __future__ import annotations

import argparse
import json
import sqlite3
import sys
from pathlib import Path

# Glean formation genres (not the coarser DB genres)
BOOK_META: dict[str, dict] = {
    "Genesis": {"order": 1, "genre": "torah", "testament": "OT"},
    "Exodus": {"order": 2, "genre": "torah", "testament": "OT"},
    "Leviticus": {"order": 3, "genre": "torah", "testament": "OT"},
    "Numbers": {"order": 4, "genre": "torah", "testament": "OT"},
    "Deuteronomy": {"order": 5, "genre": "torah", "testament": "OT"},
    "Joshua": {"order": 6, "genre": "historical", "testament": "OT"},
    "Judges": {"order": 7, "genre": "historical", "testament": "OT"},
    "Ruth": {"order": 8, "genre": "historical", "testament": "OT"},
    "I Samuel": {"order": 9, "genre": "historical", "testament": "OT"},
    "II Samuel": {"order": 10, "genre": "historical", "testament": "OT"},
    "I Kings": {"order": 11, "genre": "historical", "testament": "OT"},
    "II Kings": {"order": 12, "genre": "historical", "testament": "OT"},
    "I Chronicles": {"order": 13, "genre": "historical", "testament": "OT"},
    "II Chronicles": {"order": 14, "genre": "historical", "testament": "OT"},
    "Ezra": {"order": 15, "genre": "historical", "testament": "OT"},
    "Nehemiah": {"order": 16, "genre": "historical", "testament": "OT"},
    "Esther": {"order": 17, "genre": "historical", "testament": "OT"},
    "Job": {"order": 18, "genre": "wisdom", "testament": "OT"},
    "Psalms": {"order": 19, "genre": "wisdom", "testament": "OT"},
    "Proverbs": {"order": 20, "genre": "wisdom", "testament": "OT"},
    "Ecclesiastes": {"order": 21, "genre": "wisdom", "testament": "OT"},
    "Song of Solomon": {"order": 22, "genre": "wisdom", "testament": "OT"},
    "Isaiah": {"order": 23, "genre": "prophets", "testament": "OT"},
    "Jeremiah": {"order": 24, "genre": "prophets", "testament": "OT"},
    "Lamentations": {"order": 25, "genre": "prophets", "testament": "OT"},
    "Ezekiel": {"order": 26, "genre": "prophets", "testament": "OT"},
    "Daniel": {"order": 27, "genre": "prophets", "testament": "OT"},
    "Hosea": {"order": 28, "genre": "prophets", "testament": "OT"},
    "Joel": {"order": 29, "genre": "prophets", "testament": "OT"},
    "Amos": {"order": 30, "genre": "prophets", "testament": "OT"},
    "Obadiah": {"order": 31, "genre": "prophets", "testament": "OT"},
    "Jonah": {"order": 32, "genre": "prophets", "testament": "OT"},
    "Micah": {"order": 33, "genre": "prophets", "testament": "OT"},
    "Nahum": {"order": 34, "genre": "prophets", "testament": "OT"},
    "Habakkuk": {"order": 35, "genre": "prophets", "testament": "OT"},
    "Zephaniah": {"order": 36, "genre": "prophets", "testament": "OT"},
    "Haggai": {"order": 37, "genre": "prophets", "testament": "OT"},
    "Zechariah": {"order": 38, "genre": "prophets", "testament": "OT"},
    "Malachi": {"order": 39, "genre": "prophets", "testament": "OT"},
    "Matthew": {"order": 40, "genre": "gospels", "testament": "NT"},
    "Mark": {"order": 41, "genre": "gospels", "testament": "NT"},
    "Luke": {"order": 42, "genre": "gospels", "testament": "NT"},
    "John": {"order": 43, "genre": "gospels", "testament": "NT"},
    "Acts": {"order": 44, "genre": "acts", "testament": "NT"},
    "Romans": {"order": 45, "genre": "epistles", "testament": "NT"},
    "I Corinthians": {"order": 46, "genre": "epistles", "testament": "NT"},
    "II Corinthians": {"order": 47, "genre": "epistles", "testament": "NT"},
    "Galatians": {"order": 48, "genre": "epistles", "testament": "NT"},
    "Ephesians": {"order": 49, "genre": "epistles", "testament": "NT"},
    "Philippians": {"order": 50, "genre": "epistles", "testament": "NT"},
    "Colossians": {"order": 51, "genre": "epistles", "testament": "NT"},
    "I Thessalonians": {"order": 52, "genre": "epistles", "testament": "NT"},
    "II Thessalonians": {"order": 53, "genre": "epistles", "testament": "NT"},
    "I Timothy": {"order": 54, "genre": "epistles", "testament": "NT"},
    "II Timothy": {"order": 55, "genre": "epistles", "testament": "NT"},
    "Titus": {"order": 56, "genre": "epistles", "testament": "NT"},
    "Philemon": {"order": 57, "genre": "epistles", "testament": "NT"},
    "Hebrews": {"order": 58, "genre": "epistles", "testament": "NT"},
    "James": {"order": 59, "genre": "epistles", "testament": "NT"},
    "I Peter": {"order": 60, "genre": "epistles", "testament": "NT"},
    "II Peter": {"order": 61, "genre": "epistles", "testament": "NT"},
    "I John": {"order": 62, "genre": "epistles", "testament": "NT"},
    "II John": {"order": 63, "genre": "epistles", "testament": "NT"},
    "III John": {"order": 64, "genre": "epistles", "testament": "NT"},
    "Jude": {"order": 65, "genre": "epistles", "testament": "NT"},
    "Revelation of John": {"order": 66, "genre": "apocalyptic", "testament": "NT"},
}

DISPLAY_NAMES = {
    "I Samuel": "1 Samuel",
    "II Samuel": "2 Samuel",
    "I Kings": "1 Kings",
    "II Kings": "2 Kings",
    "I Chronicles": "1 Chronicles",
    "II Chronicles": "2 Chronicles",
    "I Corinthians": "1 Corinthians",
    "II Corinthians": "2 Corinthians",
    "I Thessalonians": "1 Thessalonians",
    "II Thessalonians": "2 Thessalonians",
    "I Timothy": "1 Timothy",
    "II Timothy": "2 Timothy",
    "I Peter": "1 Peter",
    "II Peter": "2 Peter",
    "I John": "1 John",
    "II John": "2 John",
    "III John": "3 John",
    "Revelation of John": "Revelation",
    "Song of Solomon": "Song of Songs",
}

# Canonical Glean theme vocabulary
VALID_THEMES = {
    "hope",
    "faith",
    "love",
    "wisdom",
    "prayer",
    "repentance",
    "suffering",
    "joy",
    "justice",
    "creation",
    "kingdom",
    "identity",
    "peace",
}


def default_db_path() -> Path:
    # Repo layout: content/selection/scripts/build_chunks.py -> parents[3] is the repo root.
    repo_root = Path(__file__).resolve().parents[3]
    candidates = [
        repo_root / "Sources/ScripturePreview/Resources/scripture.sqlite",
        repo_root / "ios/Glean/Resources/scripture.sqlite",
        Path(__file__).resolve().parents[1] / "vendor/scripture.sqlite",
    ]
    for path in candidates:
        if path.exists():
            return path
    return candidates[0]


def format_reference(book: str, chapter: int, start: int, end: int) -> str:
    display = DISPLAY_NAMES.get(book, book)
    if start == end:
        return f"{display} {chapter}:{start}"
    return f"{display} {chapter}:{start}-{end}"


def fetch_verses(
    conn: sqlite3.Connection,
    translation: str,
    book: str,
    chapter: int,
    start: int,
    end: int,
) -> list[tuple[int, str]]:
    rows = conn.execute(
        """
        SELECT verse, text FROM verses
        WHERE translation = ?
          AND book = ?
          AND chapter = ?
          AND verse BETWEEN ? AND ?
        ORDER BY verse
        """,
        (translation, book, chapter, start, end),
    ).fetchall()
    return [(int(v), t) for v, t in rows]


def join_text(verses: list[tuple[int, str]]) -> str:
    # Space-joined continuous reading text (no verse numbers in body)
    return " ".join(text.strip() for _, text in verses)


def canonical_order(book: str, chapter: int, start: int) -> int:
    meta = BOOK_META[book]
    # Compact global order: book*1_000_000 + chapter*1_000 + verse
    return meta["order"] * 1_000_000 + chapter * 1_000 + start


def build_chunks(db_path: Path, seed_path: Path, translation: str) -> list[dict]:
    seed = json.loads(seed_path.read_text(encoding="utf-8"))
    passages = seed["passages"]
    conn = sqlite3.connect(str(db_path))
    chunks: list[dict] = []
    errors: list[str] = []

    for p in passages:
        book = p["book"]
        chapter = int(p["chapter"])
        start = int(p["startVerse"])
        end = int(p["endVerse"])
        themes = [t for t in p.get("themes", []) if t in VALID_THEMES]
        unknown = set(p.get("themes", [])) - VALID_THEMES
        if unknown:
            errors.append(f"{p['id']}: dropped unknown themes {sorted(unknown)}")

        if book not in BOOK_META:
            errors.append(f"{p['id']}: unknown book '{book}'")
            continue

        verses = fetch_verses(conn, translation, book, chapter, start, end)
        expected = end - start + 1
        if len(verses) != expected:
            errors.append(
                f"{p['id']}: expected {expected} verses, got {len(verses)} "
                f"({book} {chapter}:{start}-{end}, {translation})"
            )
            if not verses:
                continue

        meta = BOOK_META[book]
        chunk = {
            "id": p["id"],
            "reference": format_reference(book, chapter, start, end),
            "text": join_text(verses),
            "book": book,
            "displayBook": DISPLAY_NAMES.get(book, book),
            "chapter": chapter,
            "startVerse": start,
            "endVerse": end,
            "genre": meta["genre"],
            "testament": meta["testament"],
            "themes": themes,
            "canonicalOrder": canonical_order(book, chapter, start),
            "isPopular": bool(p.get("isPopular", False)),
            "translation": translation,
        }
        chunks.append(chunk)

    conn.close()
    chunks.sort(key=lambda c: c["canonicalOrder"])

    if errors:
        print("Warnings / errors:", file=sys.stderr)
        for e in errors:
            print(f"  - {e}", file=sys.stderr)

    return chunks


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(description="Build Glean chunks.json from seed + sqlite")
    parser.add_argument("--db", type=Path, default=default_db_path())
    parser.add_argument("--seed", type=Path, default=root / "data" / "seed_passages.json")
    parser.add_argument("--out", type=Path, default=root / "data" / "chunks.json")
    parser.add_argument("--translation", default="BSB")
    args = parser.parse_args()

    if not args.db.exists():
        print(f"ERROR: scripture database not found: {args.db}", file=sys.stderr)
        print("Point --db at ScripturePreview's scripture.sqlite", file=sys.stderr)
        return 1
    if not args.seed.exists():
        print(f"ERROR: seed file not found: {args.seed}", file=sys.stderr)
        return 1

    chunks = build_chunks(args.db, args.seed, args.translation)
    payload = {
        "version": 1,
        "translation": args.translation,
        "count": len(chunks),
        "chunks": chunks,
    }
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"Wrote {len(chunks)} chunks → {args.out}")

    # Theme coverage summary
    theme_counts: dict[str, int] = {t: 0 for t in sorted(VALID_THEMES)}
    for c in chunks:
        for t in c["themes"]:
            theme_counts[t] = theme_counts.get(t, 0) + 1
    print("Theme coverage:")
    for t, n in theme_counts.items():
        print(f"  {t:12} {n}")
    return 0 if chunks else 1


if __name__ == "__main__":
    raise SystemExit(main())
