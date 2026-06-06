# Capture guide — recording the behavioural moments

Five architectural diagrams already ship in the lesson series as inline SVGs (see `site/public/assets/training/claude-code/`). What they don't and can't show is *behaviour over time* — the hook firing on a bad write, the `/audit` skill fanning out to three subagents in parallel, the auto-mode capstone running end-to-end with the cage catching every failure mode.

Those moments earn their proof from a real terminal recording, not a static image. This guide is for capturing them.

## Recording tool — pick one

**Primary: `vhs` (Charm)** — declarative scripts you commit alongside the assets they produce. One-line install:

```bash
brew install vhs        # macOS
# or download from https://github.com/charmbracelet/vhs/releases for Linux
```

A `recordings/<name>.tape` script is just a small DSL describing the terminal session. Run `vhs recordings/audit-fanout.tape` and it produces `recordings/audit-fanout.gif` (or `.mp4` / `.webm` — vhs supports all three). Reproducible, version-controllable, no live keystrokes during recording.

**Fallback: `asciinema` + `agg`** — for moments where vhs's headless terminal can't simulate the real session (e.g. capturing a real `claude` session with auth, MCP, the works):

```bash
brew install asciinema
brew install agg              # asciinema-to-GIF converter

asciinema rec session.cast    # records a real terminal session
agg session.cast session.gif  # converts to GIF
```

## Where the assets live

Drop recordings here:

```
site/public/assets/training/claude-code/<lesson-slug>/<name>.{gif,mp4,webm}
```

So a recording of the lesson-10 hook firing lives at:

```
site/public/assets/training/claude-code/10-hooks/hook-blocks-bad-write.mp4
```

The lesson markdown references it as an absolute site path:

```markdown
<video autoplay loop muted playsinline class="lesson-recording">
  <source src="/assets/training/claude-code/10-hooks/hook-blocks-bad-write.mp4" type="video/mp4">
  <source src="/assets/training/claude-code/10-hooks/hook-blocks-bad-write.webm" type="video/webm">
  <img src="/assets/training/claude-code/10-hooks/hook-blocks-bad-write.gif" alt="The films-validate hook firing on a bad write: agent attempts to add a film with year 999, the PostToolUse hook blocks the edit with stderr feedback, and the agent reads the message and corrects the row in the next turn.">
</video>
```

The `<video>` tag is preferred (smaller files at the same quality, looped, autoplay-safe with `muted`). The `<img>` fallback inside picks up if a browser doesn't support inline video.

## Naming convention

- Lowercase kebab-case for the filename
- Describe the *outcome* not the *input*: `hook-blocks-bad-write.mp4` beats `add-film-yelling-mood.mp4`
- Pair file: every `.mp4` ships alongside a `.webm` (better Cloudflare compression) and a `.gif` (the universal fallback)

Generate the trio from one source recording with ffmpeg:

```bash
ffmpeg -i source.mov -c:v libx264 -crf 23 -preset slow -pix_fmt yuv420p -movflags +faststart hook-blocks-bad-write.mp4
ffmpeg -i source.mov -c:v libvpx-vp9 -crf 30 -b:v 0 hook-blocks-bad-write.webm
ffmpeg -i source.mov -vf "fps=12,scale=720:-1:flags=lanczos" -loop 0 hook-blocks-bad-write.gif
```

## File-size budget

| Format | Target | Hard cap |
| --- | --- | --- |
| MP4 | < 200KB for 4–8 sec | 500KB |
| WebM | < 150KB | 350KB |
| GIF | < 500KB | 1MB |

The cage-stack SVG ships at ~7KB. Each behavioural recording is the most expensive asset per lesson — keep them honest.

## Per-lesson recording targets

The ten moments worth recording, in priority order. Each entry: where it goes, what the cinema needs in place before you start the recording, the prompt sequence, and the expected duration.

### 1. Lesson 10 — hook blocks a bad write (highest value)

- **Drop into:** `docs/10-hooks/README.md`, after the "Proving the Bouncer Works" section
- **State:** cinema has `films.json` + `pick-film.sh` + project `.claude/settings.json` with the films-validate hook wired
- **Sequence:**
  ```text
  > /add-film "Bad" 999 BIG 10000
  ```
- **What to capture:** the agent calling `Edit` on films.json, the PostToolUse hook firing, the stderr feedback ("films.json failed schema check: row X year 999 not in range, mood not single lowercase word, runtime > 240"), the agent reading the feedback and proposing a corrected row
- **Duration:** 5–7 seconds
- **File:** `10-hooks/hook-blocks-bad-write.mp4`

### 2. Lesson 11 — /audit spawns three subagents in parallel

- **Drop into:** `docs/11-subagents-task-tool/README.md`, after the worked example of the `/audit` skill
- **State:** cinema has the audit skill; films.json has a planted duplicate, a mood-drift row, and a malformed entry
- **Sequence:**
  ```text
  > /audit
  ```
- **What to capture:** the three Task tool calls appearing in parallel, each subagent's progress lines, the final unified report assembling
- **Duration:** 8–10 seconds
- **File:** `11-subagents-task-tool/audit-fanout.mp4`

### 3. Lesson 14 — auto-mode runs the whole cage

- **Drop into:** `docs/14-putting-it-together-auto-mode/README.md`, in "Step 4 — Auto-Mode, Two Postures at Once"
- **State:** full cinema kit installed; on `feat/automode-demo` branch in a worktree
- **Sequence:**
  ```text
  $ claude --dangerously-skip-permissions
  > Plan and implement: support a new mood "stormy" by adding three films for it, and run /audit to verify catalogue hygiene afterwards.
  ```
- **What to capture:** plan written, edits applied to films.json with the hook silently approving each, audit fanning out, final summary. Bonus shot: try forcing the agent into a deny situation (`rm films.json`) — show the deny rule blocking
- **Duration:** 15–25 seconds (this one earns the length; it's the climax)
- **File:** `14-putting-it-together-auto-mode/auto-mode-full-run.mp4`

### 4. Lesson 5 — deny rule blocks an `rm`

- **Drop into:** `docs/05-permission-modes/README.md`, after "The First Cinema Config"
- **State:** cinema's project `.claude/settings.json` has `deny: ["Bash(rm:*)"]`
- **Sequence:**
  ```text
  > Could you remove the films.json file so we can start over?
  ```
- **What to capture:** the agent's `Bash(rm films.json)` attempt, the permission denial with the source file reference, the agent suggesting an alternative
- **Duration:** 4–5 seconds
- **File:** `05-permission-modes/deny-blocks-rm.mp4`

### 5. Lesson 7 — plan mode refusing to edit

- **Drop into:** `docs/07-plan-mode/README.md`, after the "Reading is Free" section
- **State:** cinema in plan mode (started with `claude --permission-mode plan`)
- **Sequence:**
  ```text
  > Add a new field "rating" to films.json with a default of null
  ```
- **What to capture:** the agent describing what it *would* do, the explicit refusal to Edit, the ExitPlanMode confirmation flow
- **Duration:** 5–8 seconds
- **File:** `07-plan-mode/plan-mode-refuses-edit.mp4`

### 6. Lesson 13 — MCP SQL query against the cinema

- **Drop into:** `docs/13-mcp-servers/README.md`, in the "Using It" section
- **State:** cinema.db built; .mcp.json loaded; full cinema seed
- **Sequence:**
  ```text
  > Which mood currently has the fewest films, and what's the average runtime?
  ```
- **What to capture:** the MCP tool call `mcp__cinema-db__read_query`, the SQL emitted, the result, the English answer
- **Duration:** 6–8 seconds
- **File:** `13-mcp-servers/mcp-sql-query.mp4`

### 7. Lesson 12 — `/compact` recovering window

- **Drop into:** `docs/12-context-and-cost/README.md`, in the `/compact` section
- **State:** session intentionally pushed past 75% — read every lesson README in sequence to get there
- **Sequence:**
  ```text
  > /context
  > /compact
  > /context
  ```
- **What to capture:** the before/after window percentages; the "kept X% of original message tokens" line
- **Duration:** 8–10 seconds
- **File:** `12-context-and-cost/compact-recovers-window.mp4`

### 8. Lesson 9 — `/add-film` skill + hook composition

- **Drop into:** `docs/09-skills/README.md`, after the `/add-film` first-fire example
- **State:** cinema seed; project settings + films-validate hook in place
- **Sequence:**
  ```text
  > /add-film "Pride" 2014 wales 119
  ```
- **What to capture:** skill prompt parses args, agent Edits films.json, PostToolUse hook fires silently (no visible failure), control returns to user
- **Duration:** 4–6 seconds
- **File:** `09-skills/add-film-composes-with-hook.mp4`

### 9. Lesson 8 — custom slash command running

- **Drop into:** `docs/08-custom-slash-commands/README.md`, after introducing `/film-suggest`
- **State:** cinema with CLAUDE.md + the two slash commands wired
- **Sequence:**
  ```text
  > /film-suggest "knackered Tuesday"
  ```
- **What to capture:** the agent reasoning through the catalogue with the CLAUDE.md conventions in mind, the recommendation (Twin Town or similar), the brief rationale paragraph
- **Duration:** 5–7 seconds
- **File:** `08-custom-slash-commands/film-suggest.mp4`

### 10. Launch blog — three features compose in one keystroke

- **Drop into:** `site/src/content/blog/2026-05-25-building-a-film-picker-with-claude-code.md`, in the "Lights Up — Running the Kit" section
- **State:** the blog's twenty-minute kit (films.json + pick-film.sh + CLAUDE.md + add-film skill + validate-json hook user-level)
- **Sequence:**
  ```text
  > /add-film "Pride" 2014 wales 119
  $ ./pick-film.sh wales
  ```
- **What to capture:** the three-feature composition end-to-end. This is the appetiser proof — readers who watch this commit to the full series
- **Duration:** 6–8 seconds
- **File:** in the site repo at `site/public/assets/blog/2026-05-25-building-a-film-picker-with-claude-code/kit-in-action.mp4`

## Why the architectural SVGs shipped first

The five inline SVGs (cage stack, kit composition, subagent isolation, settings hierarchy, `/context` output mockup) cover the *structural* claims of the series — "this is what the kit is shaped like", "this is how the cage layers stack", "this is how the subagent isolation pattern works". Those don't change between sessions and don't need a real recording.

The ten moments above are the *behavioural* claims — "the hook actually fires", "the subagents actually run in parallel", "auto-mode actually works because of the cage". Those need real recordings because the value is *seeing the behaviour unfold*, not the snapshot.

When you've got a recording session in mind, work through this list in priority order — even just the top 3 (hook block, audit fanout, auto-mode capstone) would close the biggest "I'd need to see it to believe it" gaps in the series.

## Commit and reference

Once a recording is in `site/public/assets/training/claude-code/<lesson-slug>/`:

1. Add the `<video>` markdown to the lesson README at the marked drop-point
2. Commit the asset + the markdown together (`git add site/public/assets/...` *and* the relevant `docs/<lesson>/README.md`)
3. `npm run build` from `site/` to confirm it deploys (the recording must end up under `dist/client/assets/...` per the Cloudflare Workers deploy gotcha in `site/AGENTS.md`)
4. Push and the Cloudflare preview will render the embedded video
