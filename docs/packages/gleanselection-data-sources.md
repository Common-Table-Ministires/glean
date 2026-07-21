# Glean Data Sources — Text, Chunks, Themes

Glean needs four layers of data. **Text** you already have offline. **Chunk boundaries**, **themes**, and **popularity** are the real work.

## Architecture

```
┌─────────────────────┐     ┌──────────────────────┐     ┌─────────────────┐
│  Verse text (BSB)   │     │  Passage boundaries  │     │ Theme / tags    │
│  scripture.sqlite   │ ──► │  seed_passages.json  │ ──► │ hand + Nave's   │
│  (ScripturePreview) │     │  (+ future pericopes)│     │ + TSK clusters  │
└─────────────────────┘     └──────────────────────┘     └────────┬────────┘
                                                                   │
                                                                   ▼
                                                          chunks.json
                                                                   │
                                                                   ▼
                                                          GleanAlgorithm
```

Build command:

```bash
python3 scripts/build_chunks.py \
  --db "/path/to/scripture.sqlite" \
  --seed data/seed_passages.json \
  --out data/chunks.json
```

---

## 1. Verse text (you already have this)

| Source | License | Notes |
|--------|---------|--------|
| **ScripturePreview `scripture.sqlite`** | BSB license + KJV PD | Best path: same offline store as the app. Full BSB + KJV, 66 books. |
| [seven1m/open-bibles](https://github.com/seven1m/open-bibles) | Libre / PD | OSIS/XML public-domain and free translations (WEB, etc.). |
| [bible-api.com](https://bible-api.com) / open-bibles | Free for open texts | Good for prototyping; not for shipping closed translations. |
| [Free Use Bible API](https://bible.helloao.org/) | Open translations only | Many languages; check each translation’s license. |
| [STEPBible Data](https://github.com/STEPBible/STEPBible-Data) | CC BY 4.0 | Original-language tagged text; advanced, not required for v1. |

**Glean v1 recommendation:** keep using the local BSB in ScripturePreview’s sqlite. Do not scrape copyrighted translations (ESV, NIV, NLT, etc.) into redistributable packs without a license.

---

## 2. Chunk boundaries (pericopes)

A “chunk” is a readable unit — usually 3–15 verses, one thought/scene/psalm/paragraph — not a whole chapter dump.

| Source | How to use | Quality for Glean |
|--------|------------|-------------------|
| **Hand-curated seed** (`data/seed_passages.json`) | Formation-first list | **Gold.** Default for Glean. |
| **Translation section headings** | If USFM/OSIS has `\s` markers | High for that translation’s structure |
| [OpenBible pericope / section labs](https://www.openbible.info/labs/) | Compare how editions split books | Good research for boundaries |
| **Lectionary divisions** (RCL, etc.) | Sunday readings as chunk candidates | High pastoral usefulness; uneven coverage |
| **Chapter-as-chunk** | Fallback only | Too coarse for grace-scrolling |
| **Paragraph markers** in BSB/WEB OSIS | Auto-split long chapters | Medium; still needs theme tags |

**Do not auto-chunk the whole Bible with fixed N-verse windows.** That produces bad formation units (half a parable, mid-argument in Paul). Prefer curated + heading-aware splits.

### Practical pipeline for scale

1. Start with **~50–150 curated passages** (seed set) covering every Glean theme.
2. Expand via **section headings** from an open USFM Bible (e.g. WEB) mapped to BSB verse numbers.
3. Human-review any auto-split before it enters the product pack.
4. Later: allow *user* or *ministry* packs (CTM seasonal themes) as overlays, not replacements.

---

## 3. Themes / topical tags

Glean themes are a **small fixed vocabulary** (hope, faith, suffering, …) optimized for formation — not 20,000 topical index entries.

| Source | License | How it helps |
|--------|---------|--------------|
| **Hand tagging on seed passages** | Yours | Best fit to CTM / Glean intent |
| [Nave’s Topical Bible](https://github.com/basokant/nave) (1897) | Public domain | Map classic topics → Glean `Theme` enum |
| [ecce / Nave’s JSON projects](https://github.com/rcdilorenzo/ecce) | Varies | Topic ↔ verse tables for bulk suggestions |
| [OpenBible cross-refs / TSK](https://www.openbible.info/labs/cross-references/) (~340k) | CC-BY (check page) | Relatedness graph: once a passage is tagged, neighbors inherit soft tags |
| Keyword lexicon (your own) | Yours | e.g. “shepherd, green pastures” → hope/peace |

### Suggested mapping workflow

1. Tag seed set by hand (authoritative).
2. For each tagged chunk, pull high-vote TSK neighbors; propose same themes with confidence `< 1.0`.
3. Map Nave’s heads into Glean themes:

| Glean theme | Example Nave’s / topical heads |
|-------------|-------------------------------|
| hope | Hope, Assurance, Promise |
| faith | Faith, Trust, Believe |
| love | Love, Charity, Brotherly love |
| wisdom | Wisdom, Understanding, Instruction |
| prayer | Prayer, Supplication, Intercession |
| repentance | Repentance, Confession, Conversion |
| suffering | Affliction, Suffering, Persecution, Patience |
| joy | Joy, Rejoicing, Praise |
| justice | Justice, Judgment, Oppression, Poor |
| creation | Creation, Creator, World |
| kingdom | Kingdom of God / Heaven, Reign |
| identity | Adoption, Children of God, Image of God |
| peace | Peace, Rest, Comfort |

**Never ship unsupervised auto-tags as final.** Use them as a draft queue for review.

---

## 4. Popularity (cooldown length)

Popular passages need longer cooldowns so Glean doesn’t become “Psalm 23 every week.”

| Source | Notes |
|--------|--------|
| **Hand `isPopular` flag** on seed set | Simple, honest, enough for v1 |
| Lectionary frequency | Passages that appear often in RCL |
| Cross-ref density (TSK degree) | Rough proxy for “connected / cited” verses — imperfect |
| App analytics later | Real shown/completed rates once Glean has users |

Do **not** depend on closed popularity APIs (YouVersion, etc.) for offline open data.

---

## 5. Genre & canonical order

| Source | Notes |
|--------|--------|
| **Book catalog** in `BookCatalog.swift` / build script | Fixed 66-book map → Glean `Genre` + `canonicalOrder` |
| ScripturePreview `books` table | Has coarser genres (`narrative`, `law`, `poetry`…); map into Glean’s formation genres |

Glean genres: `torah | historical | wisdom | prophets | gospels | acts | epistles | apocalyptic`.

---

## 6. What to avoid

- Scraping Bible Gateway / YouVersion for redistributed text.
- Shipping ESV/NIV/NLT text without a commercial license.
- Treating every verse as its own chunk.
- Letting embeddings *define* theology unsupervised (embeddings can *suggest* clusters; humans own themes).
- Pulling live network data at read time — Glean stays **offline-first**.

---

## 7. Recommended near-term plan

| Phase | Deliverable | Source |
|-------|-------------|--------|
| **Now** | ~40–60 formation chunks with full BSB text | Local sqlite + seed JSON |
| **Next** | Theme draft suggestions from Nave’s + TSK | Open data downloads |
| **Then** | Heading-aware pericope expansion | Open USFM (WEB) aligned to BSB refs |
| **Product** | Ministry overlay packs (CTM seasons) | Hand-authored JSON |
| **Later** | On-device personalization weights | User history only (no cloud required) |

---

## 8. External links (bookmark)

- OpenBible cross-refs download: https://www.openbible.info/labs/cross-references/  
  Zip: https://a.openbible.info/data/cross-references.zip  
- Open Bibles (libre texts): https://github.com/seven1m/open-bibles  
- STEPBible data: https://github.com/STEPBible/STEPBible-Data  
- Awesome Bible data lists: https://github.com/jcuenod/awesome-bible-data  
- Awesome Bible developer resources: https://github.com/biblenerd/awesome-bible-developer-resources  
- Scrollmapper multi-format Bibles + cross-refs: https://github.com/scrollmapper/bible_databases  
