# Cockswain

Cockswain supervises ongoing AI-assisted work and chooses one next state:

- `CONTINUE`: useful work remains and the existing worker can advance it.
- `WAIT`: a concrete external result is in flight and more prompting would not help.
- `HUMAN`: a genuinely human-only decision or action is required.
- `DONE`: the stated goal appears satisfied and is ready for independent completion verification.

False `DONE` is the highest-severity error. False `HUMAN` is next: uncertainty by itself is not a reason to summon the user.

## Current boundary

This repository contains the first executable supervisor/evaluation harness. It does not resume the retired Cockswain v1 bookkeeping queue and it does not yet drive the ChatGPT UI.

The public chat corpus under `corpus/chat-history/` is strictly verbatim. Summaries and reconstructed context live under `corpus/derived-context/` and do not count as transcript evidence.

## OpenAI developer API mirror

The complete OpenAPI repository published by `openai/openai-openapi` is pinned under `vendor/openai-api/upstream`. `vendor/openai-api/UPSTREAM` records the exact source revision; `sh bin/update-openai-api-mirror` advances the pinned mirror deliberately.

## Verbatim corpus evaluation

Current `main` contains 148 literal public-safe messages: 88 user messages and 60 assistant messages.

`tests/corpus/` contains ten independently labeled real-history base cases. Every action has at least two base cases. Two cases explicitly combine literal user and assistant messages from the same project thread.

Three cases are history-sensitive: their correct supervisory action changes when the conversation policy/context is ablated. Multi-message cases may also carry `checkpoint` rows. `bin/cockswain-corpus-prefixes` expands those into explicit turn prefixes; the current suite adds ten prefix work states, for 20 public real-history evaluations total.

Run a configured supervisor over the base cases and turn prefixes:

```sh
COCKSWAIN_MODEL='openai/gpt-oss-20b' \
COCKSWAIN_BASE_URL='http://127.0.0.1:8000/v1' \
COCKSWAIN_SEND_REASONING_EFFORT=1 \
bin/cockswain-corpus-eval
```

The deterministic CI test does not claim model quality. It verifies corpus provenance, user/assistant role preservation, action coverage, prefix construction, history-sensitive labels, oracle-label isolation, and with/without-history plumbing.

Privacy-reduced cases under `tests/behavior/` cover interpretive failures that
repository checks cannot decide. Their contract grades both the supervisory
action and required/forbidden language, so preserving a QEMU evidence label or
a retained no-Clang constraint cannot pass on the action label alone.
Contextual merge cases cover merge-if-clean followed by “okay,” review-only
followed by the same acknowledgement, revocation, material scope change,
repository-state refresh, long context, explicit human correction, and missing
prior context. Turn checkpoints exercise the decision before and after the
authority-changing record instead of grading only the final thread.

`bin/cockswain-authority-receipt DECISION TARGET OUTPUT` renders the private
conversation classifier's result as the public-safe plain-text receipt consumed
by ai-ci. It preserves the original human source record, context and text
digests, classifier revision/contract, authorized task scope, revocation, and
objection state. It emits no GitHub head, base, check, diff, or evidence claim;
those remain ai-ci's boundary.

`bin/cockswain-authority-collect CONTEXT_REF CONTEXT_TSV STATE_TSV INTENT_FILE
CHANGED_PATHS OUTPUT` is the ordinary live path from recovered private task
context to that receipt. `CONTEXT_TSV` has the plain-text header
`record_id<TAB>role<TAB>text`. Cockswain validates the current ai-ci intent and
changed-path digests, asks the configured classifier only for semantic fields,
then derives the authority text hash, whole-context hash, latest record, exact
classifier revision, and prompt-contract hash itself. A nominated source must
exist in the recovered context and be human; acknowledgement-only sources and
assistant sources cannot authorize a merge. Missing context emits `UNKNOWN`
without reconstructing an earlier task. Private message text is not copied into
the public receipt.

Merge supervision is deterministic when ai-ci has already produced its blocker
table. `bin/cockswain-merge-state MERGE-STATE.tsv` maps mechanical work to
`CONTINUE`, a sole running-CI blocker to `WAIT`, and a sole physical or authority
boundary to `HUMAN`. `READY` means `CONTINUE` with the recorded merge action;
the work is not `DONE` until refreshed objective state says the PR actually
merged. If a physical blocker and a mechanical blocker coexist, Cockswain does
the mechanical work first instead of summoning the human prematurely.

`bin/cockswain-pr-retirement ACCOUNT_OUTPUT_DIRECTORY` consumes an account sweep
from ai-ci and chooses one next retirement action across the collected open-PR set.
READY merges and other mechanical work outrank physical/human boundaries and
running-CI waits, so repeated supervision drains forgotten work instead of
letting an opened PR disappear from the task. Unregistered PRs become
`UNMANAGED_PR` work to attach a retirement policy. Age is deliberately absent
from the decision: intentionally paused old work may remain open.
The consumer requires ai-ci's version 2 `collection.tsv` completion record,
checks its table hashes, headers, unique PR identities, and reported counts,
and refuses missing, incomplete, truncated, or altered collections. Recollect
older account output with the updated ai-ci collector before using it here.
An empty completed scan means no open PRs authored by the account across
repositories visible to the API credential, including organization transfers
and upstream contributions. Other authors and inaccessible repositories remain
outside the scope. The older owner-only scope is rejected because it can omit
unfinished work. The record does not establish live freshness or grant merge authority.

`bin/cockswain-retirement-loop [--apply] RUN_DIRECTORY` is the surrounding
execution loop. It preserves the selector's one-action contract: it collects a
complete account state, records the observed count and queue threshold, selects
one action, executes one authorized `merge` or `close`, then recollects before
asking the selector again. Set `COCKSWAIN_RETIREMENT_COLLECT_CMD` to an
executable that accepts one output-directory argument and writes the current
ai-ci account collection. `--apply` also requires
`COCKSWAIN_RETIREMENT_ACTION_CMD`, an executable that accepts one request TSV,
rechecks the exact head and authority immediately before mutation, and writes a
strict `cockswain-retirement-action-result-v1` result to stdout. The controller
records only digest-bound command output, not credentials or raw command logs.

Unresolved failed writes take priority before accepting the next selector
decision. A changed classification or disappearance from the open collection
requires reconciliation of that recorded attempt; neither can erase the failure
or produce `DONE`. A current READY failed write is retried before other READY
rows, within the bounded retry limit and with the same exact-head safeguards.

Each complete collection receives a durable receipt under
`RUN_DIRECTORY/collection-receipts/`: timestamp, collection scope/digest, open
PR count, `NORMAL`/`WARNING`/`OVER_BUDGET` queue state, threshold transition,
and the time the queue first went over 100 in the current run history. 90+ is a
warning; 100+ is a hard queue-budget violation. At that point exact-head READY
retirements still outrank ordinary work, while active, physical, experimental,
and externally blocked PRs remain open.

Every mutation attempt receives a separate durable action receipt under
`RUN_DIRECTORY/actions/`, including expected and observed heads, authority
receipt reference, pre-action state, response/error class, command-output
digests, and retryability. A retryable write failure triggers a fresh complete
collection and selector pass. A moved head yields
`HEAD_CHANGED_BEFORE_RETRY` and stops instead of replaying the old mutation.
After the bounded retry budget is exhausted, the loop returns the explicit
`RETIREMENT_ACTION_FAILED` or `RETIREMENT_ACTION_RETRY_EXHAUSTED` state rather
than quietly returning the PR to a generic READY pool.

Draft routing follows the declared promotion action: `mark-ready` continues,
`wait`/`hold-draft` waits, and an unrecognized owner decision escalates. A green
draft therefore does not remain stuck after its promotion condition is met,
while an intentional evaluation draft is not churned as repair work.

Owner obligations use the same independent-completion rule. Run
`bin/cockswain-owner-collect` to snapshot a complete, digest-bound owner
enumeration, then pass its generated `work-item.json` to
`bin/cockswain-supervise` with a private `COCKSWAIN_OWNER_STATE_DIRECTORY`.
The deterministic owner controller preserves full cell and attempt projections,
continues useful mechanical work before physical boundaries, and refuses DONE
for partial pagination, stale evidence, disappearing failures, or unsupported
supersession. See [`docs/owner-records.md`](docs/owner-records.md).

## Candidate models

The initial matrix in `models/models.json` is:

- `openai/gpt-oss-20b`
- `Qwen/Qwen3-4B-Instruct-2507`
- `mistralai/Ministral-3-8B-Instruct-2512`
- `microsoft/Phi-4-reasoning-plus`

Reasoning should be as deep as the runtime permits; latency is not an optimization target.

## Private recent history

A full ChatGPT export remains local-only. Normalize it under `.private/` with `bin/import-chatgpt-export`, then use `bin/cockswain-recent-cases` to join selected active branches to independently checked objective state and labels. Private transcripts, generated cases, credentials, and detailed local logs must not be committed.

See `docs/chat-history.md` and `docs/model-evaluation.md` for the evidence and promotion boundaries.
