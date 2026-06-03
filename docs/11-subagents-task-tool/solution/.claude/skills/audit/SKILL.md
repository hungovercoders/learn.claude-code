---
name: audit
description: Audit films.json for duplicates, mood drift, and missing fields using parallel subagents
allowed-tools: Read, Agent
disable-model-invocation: true
---

Audit `./films.json` for data quality. Spawn three parallel Explore
subagents in a single message:

1. **Duplicate detection** — read films.json and report any titles
   that appear more than once, or near-duplicates (same year + first
   five words of title).
2. **Mood drift** — read films.json and CLAUDE.md, list every mood
   value that doesn't appear in the conventions block, and propose
   either renaming or adding to the conventions.
3. **Missing or malformed fields** — every entry must have a
   four-digit year, a single-lowercase-word mood, and a runtime
   integer between 60 and 240. Report rows that fail.

Wait for all three to return. Combine the findings into one short
markdown report under headings *Duplicates*, *Mood drift*, *Field
issues*. End with a single recommended next action — the first
thing you would fix if you only had ten minutes.

Don't edit films.json. This is a read-only audit.
