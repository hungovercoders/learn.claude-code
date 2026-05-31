---
description: Suggest a film for a mood using the cinema catalogue plus light reasoning
allowed-tools: Read
argument-hint: <mood or short description — e.g. "knackered Tuesday", "big-night", "raining">
---

Read `./films.json`. The user's mood is: $ARGUMENTS

Pick ONE film from the list that best fits the mood. Explain why in
two sentences, leaning on the runtime and the Welsh/Mandalorian house
preferences in CLAUDE.md. If none truly fit, say so and suggest what
mood to add to the catalogue next.

End with: "Reach for the popcorn, fellow hungovercoder."
