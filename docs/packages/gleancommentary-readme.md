# GleanCommentary

Offline commentary pack for [Glean](../glean) (Common Table Ministries).

Public-domain and explicitly free voices only — short, signed excerpts for the feed **context page**, never over the focus verse.

## Layout

```
Sources/GleanCommentary/
  Models.swift           sources + notes + confidence
  CommentaryStore.swift  load pack, look up by ref / pack id
  Resources/
    sources.json         catalog of commentators + licenses
    notes.json           verse-keyed short excerpts
```

## Integrity

See [INTEGRITY.md](INTEGRITY.md). Do not vendor this into the iOS target.

## Test

```bash
cd ~/sarah/gleancommentary && xattr -cr . && swift test
```

## License of content

Each source row in `sources.json` declares its own license (usually `public-domain`).  
Code in this package is part of the Glean project (license TBD with the app).
