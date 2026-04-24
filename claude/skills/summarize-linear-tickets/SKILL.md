---
description: Review the user's Linear issues and recent GitHub PRs in one pass, mark unambiguously-done issues Done, and produce a consolidated action list (done / needs decision / in flight / agent-ready backlog / top pick). TRIGGER when the user asks to review, triage, summarize, or clean up their Linear tickets, or asks "what should I work on next" in a Linear context. SKIP for generic project-management questions not involving their Linear workspace.
---

# Summarize Linear Tickets

Review the user's Linear issues and recent PRs, then deliver a consolidated action list. Do everything in one pass — do not ask for confirmation on intermediate steps.

## Data to pull (in parallel)

1. Linear issues assigned to the user, **all statuses** (`includeArchived: false`, `limit: 250`). Include: status, title, description, `parentId`, `updatedAt`, url, attachments.
2. GitHub PRs authored by the user in the last 14 days:
   - Merged: `gh pr list --author "@me" --state all --search "merged:>=$(date -u -v-14d +%Y-%m-%d)"`
   - Open: `gh pr list --author "@me" --state open`

   Capture: number, title, `mergedAt`/`createdAt`, state, url, body.

## Cross-reference strategy

Match PRs to issues by **both**:
- Explicit `NS-###` reference in the PR title (authoritative).
- Scope match against the issue description (for PRs that don't name the ticket).

Flag any PR that references `NS-###` in its title but whose content doesn't match that ticket's scope — mislabels happen. Don't silently trust the title.

## Bucket every issue into ONE of

| Bucket | Meaning | Action |
|--------|---------|--------|
| **A. Definitely done** | Merged PR titles the issue OR scope is clearly covered. | Mark Done; attach the PR(s) via `save_issue` `links` (append-only). |
| **B. Likely done but ambiguous** | Probable coverage, needs user confirmation. | Surface with evidence; ask before touching. |
| **C. No longer relevant** | Duplicate, subsumed by a parent, or obsolete after a recent refactor (check memory + PR history). | Surface with reasoning; let the user pick duplicate vs. cancel. |
| **D. Actively in progress** | Has open PRs or multi-phase work underway. | Leave alone; note which PR. |
| **E. Parent epics** | Stay open while children drain. | Identify the children. |
| **F. Stale / needs triage** | Backlog or Todo, no recent activity, no obvious next step. | Surface individually with a one-line "why it might be stale." |
| **G. Overlapping scope** | Consolidation candidates. | Identify the umbrella and the dupes; don't act without confirmation. |

## Agent-ready scoring (for D/F issues still open after cleanup)

Rank each remaining open ticket on:
- **Spec completeness**: explicit file paths, line numbers, exact diff shape? (yes / partial / no)
- **Blocked?**: depends on another ticket, design doc, or human decision? (yes / no)
- **Scope**: rough diff size (<200 LOC / 200–500 / bigger)
- **Ambiguity**: any judgment calls left? (none / small / large)

Tiers:
- **Tier 1** — spec complete + not blocked + small + no ambiguity. Dispatch-ready.
- **Tier 2** — small and clear but needs a light call upfront.
- **Tier 3** — needs design or investigation first.

## Output format

Markdown, in this exact order:

1. **Actions I took** — table of issues closed/marked done, with the justifying PR link.
2. **Needs your decision** — buckets B, C, F, G. One row each with the question you can't answer.
3. **In flight** — buckets D + E, one line each.
4. **Agent-ready backlog** — Tier 1/2/3 ranking, one-line "why it's ready."
5. **Top pick** — the single ticket to dispatch next, and why.

Every issue reference must be a clickable `linear.app` URL. Every PR reference must be a clickable `github.com` URL.

## Scope of autonomous action

**May do directly:**
- Mark issues Done and attach PR links when the match is unambiguous (bucket A).
- Close duplicates with pointers when duplication is obvious (e.g. identical titles).

**Must ask first:**
- Canceling tickets opened by other people — surface them instead.
- Consolidating or merging tickets.
- Changing "In Progress" status on tickets that might be actively worked on.
