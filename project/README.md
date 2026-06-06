# cinema — the finished Cinema Companion

This directory is the end-state of the learn.claude-code series. Every
lesson adds one or more files; by lesson eleven the kit looks like this.

## What's in here

```
films.json                  Catalogue (lesson 1 seed)
pick-film.sh                Bash + jq picker (lesson 1 seed)
CLAUDE.md                   Project context (lesson 4)
install.sh                  Symlinks .claude/ into ~/.claude/ (lesson 11)
plans/lesson-05-mcp-feature.md   Plan-mode artefact (lesson 5)
scripts/build-cinema-db.sh  Builds cinema.db from films.json (lesson 10)
.mcp.json                   MCP server wiring (lesson 10)
.claude/
  settings.json             Permission allowlist + hook wiring (lessons 3, 8)
  commands/film-pick.md     Slash command — wraps pick-film.sh (lesson 6)
  commands/film-suggest.md  Slash command — Claude-reasoned pick (lesson 6)
  skills/add-film/SKILL.md  Skill — append-only writes with safety belts (lesson 7)
  skills/pair/SKILL.md      Skill — snack + drink + co-watcher pairings (lesson 7)
  skills/audit/SKILL.md     Skill — parallel subagent audit (lesson 9)
  hooks/films-validate.sh   PostToolUse hook — schema-checks films.json (lesson 8)
```

## Using it as a forker

Two paths.

**Build along** — start from the lesson 1 seed (`films.json` + `pick-film.sh`)
and add files as each lesson walks you through them. Each lesson's
`solution/` directory holds the exact delta for that lesson, so if
you get stuck you can `cp -r ../docs/06-custom-slash-commands/solution/. .`
and carry on.

**Clone the end state** — `cp -r learn.claude-code/project/. ~/dev/learn.claude-code/`
gives you the whole thing in one shot. Useful for sanity-checking your
own build, or for grabbing the cinema as a starter for your own work.

## Running it

```bash
cd ~/dev/learn.claude-code
chmod +x pick-film.sh install.sh .claude/hooks/films-validate.sh scripts/build-cinema-db.sh
./install.sh                 # symlinks .claude/ contents into ~/.claude/
./pick-film.sh fun           # one film matching mood "fun"
./scripts/build-cinema-db.sh # builds cinema.db for the MCP server
```

Inside `claude`:

```text
> /film-pick cardiff
> /film-suggest "knackered Tuesday"
> /add-film "Pride" 2014 wales 119
> /pair "Hot Fuzz"
> /audit
```

The `films-validate.sh` hook blocks any edit that breaks the schema —
try `/add-film "Bad" 999 BIG 10000` and watch it refuse.
