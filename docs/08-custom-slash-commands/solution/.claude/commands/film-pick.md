---
description: Pick a film from films.json by mood, using pick-film.sh
allowed-tools: Bash
argument-hint: <mood — e.g. "fun", "cosy", "cardiff", "wales">
---

The user wants a film for tonight. Their mood is: $ARGUMENTS

Run `bash pick-film.sh "$ARGUMENTS"` from the project root and show
the result verbatim. If the picker prints "No film for mood", suggest
the closest mood from the conventions in CLAUDE.md.

End with: "Reach for the popcorn, fellow hungovercoder."
