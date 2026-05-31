---
name: add-film
description: Add a film to films.json in the current directory
allowed-tools: Read, Edit
argument-hint: "<title>" <year> <mood> <runtime>
disable-model-invocation: true
---

The arguments are: $ARGUMENTS

Parse them as: a quoted title (multi-word), then a year (4-digit
integer), then a mood (single lowercase word), then a runtime in
minutes (integer).

Read `./films.json`. Append a new object `{ "title", "year", "mood",
"runtime" }` to the end of the array, preserving the order and
formatting of existing entries. Don't reformat the rest of the
file — only add the new entry on its own line just before the
closing `]`.

If `films.json` does not exist in the current directory, stop and
say so. Don't create it.

The `films-validate.sh` PostToolUse hook will re-check the schema
on the Edit — if you broke the structure, the hook will block the
write and tell you why.
