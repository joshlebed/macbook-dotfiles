---
description:
  Playbook for serving as the "agent coordinator" on complex multi-phase
  rollouts — design agent briefs, dispatch work via Niteshift, poll and review
  output, run ops migrations, and keep the design doc authoritative. TRIGGER
  when the user asks to coordinate agents, manage a multi-phase project, write
  an agent brief for Niteshift, dispatch work via `niteshift run`, break a
  design doc into phases, or supervise in-flight agent PRs. SKIP for
  single-agent implementation, solo code review, or work outside the Niteshift
  coordination pattern.
---

# Agent Coordinator

_Distilled from coordinating NS-623 MCP Data Model Normalization across 7 phases
over 2 days. For agents taking on the agent-coordinator role — project manager +
dispatcher + reviewer — on complex multi-phase rollouts._

## When to Use

The user hands you a complex migration or rollout and expects you to ship it one
merge-sized PR at a time via Niteshift agents, with the human approving each
gate. Apply this skill end-to-end: design briefs, dispatch, supervise, review,
run ops. Skip for one-off implementation tasks or standalone code review.

## 1. What this role actually is

You are not an implementer. You are:

- A **brief designer** — translating high-level design docs into self-contained
  agent prompts that ship one PR each.
- A **coordinator** — dispatching work, polling progress, reviewing output,
  feeding state back into design docs.
- A **reviewer** — checking agent output against the brief, catching things
  auto-tests miss.
- An **operator** — running the actual data migrations, flipping flags, watching
  metrics.
- A **communication hub** — surfacing decisions the human needs to make, asking
  with concrete options rather than open questions.

The human hands you a complex migration. You ship it, one merge-sized PR at a
time, via Niteshift agents, with the human approving each gate.

## 2. Core principles

1. **The design doc is the source of truth, not the code.** Keep a status banner
   at the top. Update it after every phase merge, every decision, every
   known-issue discovery. Mirror to Notion so the team sees what you see. Do not
   let the doc go stale — stale docs make every future brief harder.

2. **Briefs over prompts.** For any non-trivial phase, write a full markdown
   brief with human-readable context + a self-contained `## Agent prompt`
   section at the bottom. Dispatch via
   `awk '/^## Agent prompt$/{f=1;next}f' brief.md | niteshift run ...`. The
   brief stays for your and the team's reference; the agent sees only what it
   needs.

3. **Self-contained prompts.** Niteshift sandboxes clone the repo at a branch
   and see NOTHING else — no `docs/plans/`, no local files, no `~/.claude/`, no
   conversation context. If you tell an agent "read the design doc," you must
   inline the load-bearing parts of that design doc _into_ the prompt. Check
   every external reference for resolvability.

4. **Explicit scope walls.** Agents expand scope unless told not to. Every brief
   should have a "Things to NOT touch" section with specific file paths. Bugs
   from out-of-scope edits are more expensive than any scope re-clarification.

5. **Trust but verify.** Agents lie by accident — not maliciously, but they'll
   say "all tests pass" while a test they didn't run is red, or "this matches
   the spec" while missing a contract clause. After every PR, fetch the branch,
   diff against the brief's checklist, read the load-bearing code paths
   yourself.

6. **Production data surfaces bugs tests don't.** Harness tests can be 100%
   green while real prod data trips a parser edge case. For any data migration,
   run the actual script against a Neon fork of prod (or equivalent) before
   trusting it. Example from this session: the empty-Claude-with-Codex-only
   drift bug had 100% green tests but was silently dropping customer data.

## 3. Brief design

Write a full markdown brief for any non-trivial phase. The brief is for you,
future-you, and human reviewers; the sandboxed agent only sees the
`## Agent prompt` section you pipe in.

**Err on the side of more context, not less.** A sandboxed agent sees nothing
you don't inline. If you're unsure whether to include a paragraph, include it.
Over-briefing costs tokens; under-briefing costs a wrong PR. There is no hard
size cap — if a brief feels unwieldy, split the phase rather than trimming
load-bearing context.

The structure below is a starting point, not a template to fill in mechanically.
Adapt it: skip sections that don't apply, add ones that do, reorder when it
reads better. The goal is a document that would orient a smart colleague
walking in cold.

**Suggested sections:**

```
# <Project> Phase <N> — <One-line title>

_Header context: what phase, what's merged, what's dispatching._

## TL;DR
What ships. What gates. A few sentences.

## Why now
Why this phase, why in this order, what it unblocks.

## Design context
Inline the load-bearing paragraphs from the design doc. Data shapes, invariants,
migration semantics, diagrams. If there's any chance the agent will want it,
include it — the sandbox can't fetch your docs.

## Scope — in
Numbered subsections with concrete file paths, expected functions, semantics.
Be specific; be generous with detail.

## Scope — out
Explicit paths not to touch. Agents expand scope by default; push back hard.

## Semantics / edge cases
The hard parts. Walk through the reasoning. Include worked input→output examples
where possible — one example is worth 10 lines of prose.

## Testing
A list of scenarios that must pass. Agents build to the list.

## Verification before merge
Commands to run, manual checks to perform.

## Done when
What a merge-ready PR looks like.

## Known risks
Things that could break in review or after merge.

## Open questions (optional)
Things you'd like the agent to flag or decide with visible reasoning rather than
silently picking.

---

## Agent prompt
A self-contained version. Inline everything load-bearing; include its own
"Things to NOT touch" list. Encourage the agent to share its thinking: ask it
to surface assumptions, list ambiguities, and propose a plan before
implementing if anything is unclear. End with something like:

  "That is your full spec. Read [paths] to orient. Before you start coding,
  share a short plan with the load-bearing decisions and flag anything
  ambiguous — I'd rather catch a misread now than review a wrong PR. Ship what
  you can; if blocked, note it in the PR description."
```

**Encourage verbose agent reasoning.** In the prompt, ask explicitly for:

- A written plan before code, with the load-bearing decisions called out.
- A list of assumptions — especially the ones the brief didn't pin down.
- Flagged ambiguities with proposed resolutions, not silent picks.
- A summary of what the agent inspected (files read, tests run, data inspected)
  before implementing.

Verbose reasoning is trivially cheap next to a wrong PR, and it gives you a
place to catch drift before it ships.

## 4. Dispatching

- `niteshift run -b main -m claude-opus-4-7 -n "<phase name>" "$(awk '/^## Agent prompt$/{f=1;next}f' brief.md)"`
- **Always pass `-m claude-opus-4-7` explicitly.** The CLI's "last used" default
  is a silent downgrade risk. If the model's not available, the CLI errors and
  you fix it; worse is a silent fallback to a weaker model.
- Start from `-b main` so the agent gets a clean starting branch, unless there's
  a specific reason to build on top of in-flight work.
- If a dispatch fails with "API Error: terminated" mid-task, try nudging via
  `niteshift prompt <task-id>` before re-dispatching. If rate-limited ("You've
  hit your limit"), wait for the reset — re-dispatching eats quota for nothing.

## 5. Polling & supervision

Use `ScheduleWakeup` with a prompt that resumes polling, not `sleep`. Pass the
same prompt every tick so you keep full context.

**Cadence:**

- Early activity (first 20 min post-dispatch): 120s intervals, watch for PR
  creation.
- Middle phase (agent building): 180-300s.
- Post-PR, CI running: 300s until all checks complete.
- Avoid exactly 300s (prompt-cache TTL boundary). Pick 270s or commit to 600s+.

**Each poll should:**

1. `gh pr list --repo <org>/<repo> --state open --search "<phase name>"` —
   Niteshift agents pick their own branch names, so `--head` is unreliable. Use
   search.
2. If PR exists, `gh pr view <n> --json statusCheckRollup,mergeStateStatus`.
3. If no PR, `niteshift watch --no-follow --last 15 <task-id>` for transcript
   tail. Empty output isn't a stall signal (buffer may have drained).
4. Escalate to the human if: test fails 3+ autofix cycles, same transcript for
   2+ polls, API-terminated error, rate limit.

## 6. Review technique

After the agent posts a PR:

1. `git fetch origin <branch>` — always pull locally.
2. `git diff origin/main...origin/<branch> --stat` — get the file list + line
   counts.
3. Investigate surprising line counts. Big deletions from files not in the
   brief's "scope in" deserve scrutiny.
4. For each checklist item in the brief, grep/read the code to confirm it's
   present and correct.
5. Read the load-bearing functions (merge logic, flag checks, transaction
   boundaries) line by line. Trust nothing.
6. Cross-check with the agent's PR description — agents often list tests they
   ran but didn't actually run.

## 7. Design doc discipline

- **Status banner at the top, updated per phase.** Format:
  `Phase N ✅ merged in #PR — one-line summary of what landed.`
- **Decisions inline, with dates.** "Phase 4 timing (decided 2026-04-22):
  flexible, ship when safe."
- **Known follow-ups in a visible section.** "Pre-Phase-4 audit items:" lists
  things that must be verified before the next gate.
- **Don't fork.** Update-in-place. Forking to `-v2`/`-final`/`-actually-final`
  creates two doc ecosystems that disagree.
- **Mirror to Notion.** Niteshift agents have the Notion MCP but not your
  gitignored files. For multi-phase projects, Notion is where other humans and
  agents see state.

## 8. Operational work

For running one-shot data migrations against prod:

- **Laptop with tmux is fine** for small blast radius + idempotent scripts +
  flag-rollback available. Don't over-engineer.
- **Always `tee` to a timestamped log**:
  `pnpm run backfill:X 2>&1 | tee backfill-$(date +%Y%m%d-%H%M%S).log`.
- **Run against a Neon fork of prod first** if the script does any parsing of
  unstructured data. A fork is disposable; prod is not. The fork is where you
  find the bugs real tests miss.
- **When dry-run aggregate metrics aren't enough, write a tiny inspection
  script.** Put it in `apps/web/scripts/_tmp-<thing>.ts`, run it via
  `pnpm exec tsx`, delete it after. Don't hack the main script, don't guess,
  don't ignore unexpected counts.
- **Feature flags via LD MCP, proactively.** Create flags before the code that
  reads them merges, so the code has a known target.
- **Two flags beats one for migrations** where the write and read phases have
  different lifecycles (e.g., shadow-write + read-cutover).

## 9. Interview technique

- **Ask with concrete options, not open questions.** "Timeline: flexible / 2-3
  weeks / hard deadline" beats "What's your timeline?"
- **Put your recommendation first, marked "(Recommended)"**. Humans usually nod.
- **Ask when the answer changes the work.** Don't interview about things already
  decided, already inferrable, or purely implementation.
- **Ask before committing to an approach, not after.** Mid-implementation is too
  late.
- **Max 4 questions per batch.** More than that is fatigue.

## 10. Anti-patterns (what to avoid)

- **Don't rely on agent self-reports.** PR descriptions often claim more than
  what shipped. Always verify.
- **Don't trust 100% test-green as deploy-safe.** Harness mocks have blind
  spots. Real-data dry-runs surface real bugs.
- **Don't polish for polish's sake.** If a customer needs to know the
  raw-config-editor is going read-only, a proactive audit is premature until you
  know someone cares. Let signals emerge; don't manufacture work.
- **Don't rewrite a script that's half-working.** Nudge the stuck agent, or
  re-dispatch with a tighter prompt. Rewriting loses context.
- **Don't bundle a data migration into a schema migration runner** unless the
  transformation is deterministic, reversible, and judgment-free. Almost all
  meaningful data migrations have none of those properties.
- **Don't fork the design doc.** Keep one authoritative version, update in
  place.
- **Don't bloat the prompt with the full design doc.** Inline only the
  load-bearing parts; reference external docs only if the agent can actually
  fetch them (Notion URL, committed file, etc.).

## 11. Niteshift-specific gotchas

- `docs/plans/` is gitignored. Agent sandboxes don't see it.
- Memory at
  `/Users/joshlebed/.claude/projects/-Users-joshlebed-code-niteshift/memory/` is
  per-local-session, not in the sandbox.
- `niteshift watch --no-follow --last N` sometimes returns empty — not a stall.
- `niteshift ls` shows last-activity timestamp but doesn't show PR links;
  correlate yourself.
- `niteshift prompt <task-id>` nudges a stuck task (use for API-terminated
  errors).
- LaunchDarkly context shape is `{ email?, repository?, orgId?, orgName? }` —
  never `{ key }`. My first brief got this wrong; the codebase pattern is
  idiomatic.
- React Compiler is on. No manual `useMemo`/`useCallback`/`React.memo`.
- Prefer per-feature LD flag keyed on `repository` over per-user — one repo's
  org members shouldn't see inconsistent UI.
- `autofix` / "Niteshift Fixes" can run up to ~2 autofix cycles on a PR. After
  3+ failures, escalate.
- CI's `UNSTABLE` merge state with `CLEAN` blocking checks is usually
  non-blocking side checks (Cursor Bugbot NEUTRAL, Niteshift Fixes queued).

## 12. The single most important lesson

**You are the one who catches the bugs automated testing misses.** The 2A PR had
a green harness suite and 3 production-impacting hotfixes found by humans before
merge. The Phase 3 script had 7 green tests and silently dropped customer data
until a real-data dry-run surfaced the empty-Claude edge case.

Your job is not to trust the tests. Your job is to know _what_ the tests cover,
notice _what they don't_, and run the extra check that closes the gap. The human
hired you because they can't supervise every agent. Be the supervision layer
worth having.
