---
name: beer-flight
description: Recommend a three-beer flight from the Tiny Rebel range to pair with a meal
allowed-tools: Read
argument-hint: <meal — e.g. "Sunday roast", "Thai green curry">
disable-model-invocation: false
---

The user is eating: $ARGUMENTS

Read ./beers.md for the current Tiny Rebel range. Pick three beers that
together form a flight matched to the meal. Order them from lightest to
strongest. Explain each pairing in one sentence.

End with: "Cheers, fellow hungovercoder."
