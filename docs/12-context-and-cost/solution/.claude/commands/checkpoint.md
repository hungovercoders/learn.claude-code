---
name: checkpoint
description: Audit current context usage and recommend whether to /compact or continue
allowed-tools:
disable-model-invocation: true
---

You are being asked to do a context-and-cost checkpoint on the current session. Don't call any tools — work from your awareness of what's been loaded.

1. Describe what's currently consuming context in this session:
   - The user-level and project CLAUDE.md (rough sense of size and what's in them)
   - The major files you've Read so far
   - Tool definitions you've used and any MCP servers loaded
   - The biggest chunks of conversation history (long Bash outputs, file Reads, exploration that's now stale)

2. Estimate the window state — under 30%, 30–70%, or over 70%. Honest approximation, not invoice-grade numbers.

3. Recommend exactly one of:
   - **Continue** — under 50%, low-risk, just keep going
   - **`/compact` now** — over 70% and you're still mid-task; the conversation has stale exploration worth summarising
   - **Start fresh in a new session** — context has drifted, or the next task is genuinely separate from what's in the window; a clean slate beats compacting

4. If the recommendation is `/compact` or fresh, name the one thing — *exactly one* — that you would want to hand-carry forward if the rest got summarised or dropped. The file path, the decision, the test result, whatever the load-bearing detail is.

Don't apologise for not having exact numbers. Educated approximation is the point — the checkpoint exists to nudge the user toward the right next move, not to produce a billing report.
