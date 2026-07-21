#!/usr/bin/env python3
"""Tiny offline demo of Glean-style selection against data/chunks.json."""

from __future__ import annotations

import json
import random
from collections import Counter
from datetime import date, timedelta
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CHUNKS_PATH = ROOT / "data" / "chunks.json"

NORMAL_CD = 90
POPULAR_CD = 180


def load_chunks():
    pack = json.loads(CHUNKS_PATH.read_text(encoding="utf-8"))
    return pack["chunks"] if "chunks" in pack else pack


def eligible(chunks, history, today: date):
    out = []
    for c in chunks:
        if c["id"] not in history:
            out.append(c)
            continue
        last, times = history[c["id"]]
        days = (today - last).days
        need = POPULAR_CD if c["isPopular"] else NORMAL_CD
        if days >= need:
            out.append(c)
    return out


def score(chunk, history, recent_genres, recent_themes, preferred, today: date):
    s = 0.0
    prefs = set(preferred)
    if prefs:
        s += 3.0 * len(prefs.intersection(chunk["themes"]))

    if chunk["id"] in history:
        last, times = history[chunk["id"]]
        days = (today - last).days
        s += min(days / 20.0, 6.0)
        s -= min((times - 1) * 0.25, 2.0)
    else:
        s += 4.0

    if chunk["genre"] not in recent_genres:
        s += 2.0
    novel = set(chunk["themes"]) - recent_themes
    s += 0.75 * len(novel)
    if chunk["isPopular"]:
        s -= 0.35
    return s


def select(chunks, history, preferred, today: date, recent_ids):
    cands = eligible(chunks, history, today)
    if not cands:
        return None
    recent_genres = {next(c["genre"] for c in chunks if c["id"] == i) for i in recent_ids if any(c["id"] == i for c in chunks)}
    recent_themes = set()
    for i in recent_ids:
        for c in chunks:
            if c["id"] == i:
                recent_themes.update(c["themes"])
    ranked = sorted(
        ((score(c, history, recent_genres, recent_themes, preferred, today), c) for c in cands),
        key=lambda x: (-x[0], x[1]["canonicalOrder"]),
    )
    top = ranked[:3]
    # weighted among top-3
    weights = [max(sc - top[-1][0] + 1.0, 0.1) for sc, _ in top]
    pick = random.choices([c for _, c in top], weights=weights, k=1)[0]
    return pick, top[0][0]


def main():
    if not CHUNKS_PATH.exists():
        raise SystemExit(f"Missing {CHUNKS_PATH}; run scripts/build_chunks.py first")

    chunks = load_chunks()
    history: dict[str, tuple[date, int]] = {}
    recent: list[str] = []
    themes = Counter()
    genres = Counter()
    today = date.today()

    print(f"Corpus: {len(chunks)} chunks")
    print("Simulating 30 daily selections (empty → filling history)...\n")

    for day in range(30):
        d = today + timedelta(days=day)
        result = select(chunks, history, preferred=["hope", "suffering"], today=d, recent_ids=recent[-15:])
        if not result:
            print(f"Day {day+1}: no eligible chunks")
            continue
        pick, sc = result
        cid = pick["id"]
        if cid in history:
            last, times = history[cid]
            history[cid] = (d, times + 1)
        else:
            history[cid] = (d, 1)
        recent.append(cid)
        themes.update(pick["themes"])
        genres[pick["genre"]] += 1
        print(f"Day {day+1:2d}  score={sc:5.2f}  {pick['reference']:<28}  {', '.join(pick['themes'])}")

    print("\nTheme hits:", dict(themes.most_common()))
    print("Genre hits:", dict(genres.most_common()))


if __name__ == "__main__":
    main()
