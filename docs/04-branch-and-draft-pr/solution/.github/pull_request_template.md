## Summary

<one or two sentences on what this PR changes>

## Cage layers ticked

Each lesson of learn.claude-code adds one safety layer that makes
auto-mode (lesson 14) safer. Tick as the layer lands.

- [x] Lesson 4 — Branch + draft PR. `main` untouchable; changes visible on remote.
- [ ] Lesson 5 — Permission modes. Project-scoped allow + deny rules.
- [ ] Lesson 6 — CLAUDE.md. Project conventions + things-to-never-do.
- [ ] Lesson 7 — Plan mode. Plan-before-execute discipline documented.
- [ ] Lesson 8 — Slash commands. `allowed-tools` narrowing per command.
- [ ] Lesson 9 — Skills. `disable-model-invocation` on writes.
- [ ] Lesson 10 — Hooks. Schema enforcement on every write to films.json.
- [ ] Lesson 11 — Subagents. Context isolation on the audit.
- [ ] Lesson 12 — Context discipline. `/checkpoint` command + `/compact` habit.
- [ ] Lesson 13 — MCP servers. Bounded external access via typed tools.
- [ ] Lesson 14 — install.sh + auto-mode proof.

## Test plan

- [ ] `bash pick-film.sh wales` returns a film
- [ ] `/film-pick`, `/film-suggest`, `/add-film`, `/pair`, `/audit` all invoke
- [ ] `films-validate.sh` blocks a bad row
- [ ] `claude --dangerously-skip-permissions` exercises the kit without touching `main`

🤖 Generated with [Claude Code](https://claude.com/claude-code)
