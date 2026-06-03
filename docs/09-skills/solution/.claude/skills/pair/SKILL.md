---
name: pair
description: Pair a film to a snack, a drink, and a co-watcher archetype
allowed-tools: Read
argument-hint: <title or mood>
---

Read `./films.json` and `./CLAUDE.md`.

The argument is either a film title from the catalogue or a mood
word: $ARGUMENTS

If it's a mood, pick the best-fit film from the catalogue first.
Then recommend:

- **Snack** — one specific snack that fits the runtime and mood.
  Pretzels for short comedies, slow-cooked nachos for anything over
  two hours, toast for a homesick rewatch.
- **Drink** — one Tiny Rebel beer or a non-alcoholic alternative.
  Cwtch for cosy, Mango Punk for fun, a brew for the homesick ones.
- **Co-watcher archetype** — one sentence describing the kind of
  person this film is best watched with. "Someone who quotes Spaced
  unprompted." "A parent who remembers the original."

Keep each line one short paragraph. No bullets. Close with:
"That's the round in. Enjoy, fellow hungovercoder."
