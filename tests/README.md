# Cockswain tests

The evaluation harness and the unattended controller have separate promotion boundaries.

## Verbatim corpus contract

`tests/test-corpus-cases.sh` is deterministic and runs in CI. It verifies ten real-history base cases built from `corpus/chat-history/`:

- four CONTINUE cases;
- two WAIT cases;
- two HUMAN cases;
- two DONE cases.

It also checks ten turn-prefix cases (20 evaluations total), at least two two-sided user/assistant history chunks, and at least three base cases whose expected action changes under history ablation. A deterministic supervisor stub checks that the evaluator removes oracle labels before invocation and removes both transcript content and transcript provenance in without-history mode.

This test proves the harness plumbing and corpus provenance. It does not claim that an open-weight model passes the corpus.

## Live supervisor behavior

Run the public corpus against a configured endpoint with:

```sh
COCKSWAIN_MODEL='openai/gpt-oss-20b' \
COCKSWAIN_BASE_URL='http://127.0.0.1:8000/v1' \
COCKSWAIN_SEND_REASONING_EFFORT=1 \
bin/cockswain-corpus-eval
```

The older synthetic cases under `tests/behavior/` remain useful for targeted failure modes.
They are privacy-reduced rather than transcript evidence. Cases may declare
`required_output` and `forbidden_output` rows; the evaluator removes those
oracle fields before model invocation and grades the complete returned
rationale/prompt/question/evidence text. Current cases cover retained
constraints, ambiguous merge authorization, execution-versus-planning,
correction persistence, and QEMU-versus-physical language.
The contextual-authority family adds full-thread and turn-prefix cases for an
earlier merge-if-clean task, review-only context, revocation, scope change,
state-only refresh, long history, correction persistence, and missing context.

`tests/test-authority-receipt.sh` checks the file boundary into ai-ci. A later
acknowledgement may remain the latest record while the earlier human task stays
the authority source. Acknowledgement-as-source, changed scope, missing context,
revocation, and unresolved objection all produce fail-closed classifications.

`tests/test-merge-state.sh` covers the non-model merge loop. It consumes ai-ci's
plain blocker table and proves READY, running CI, physical action, missing
authority, stale follower, conflict-plus-physical, and genuine ambiguity routing.

`tests/test-pr-retirement.sh` checks account-wide action selection and rejects
uncollected, truncated, malformed, duplicate, and count-mismatched inputs before
they can produce `DONE`. CI also runs ai-ci's account collector and passes its
actual output through this consumer, including paginated, empty, failed, and
managed collections. These are deterministic API fixtures, not live GitHub
account or supervisor-model acceptance.

`tests/test-owner-records.sh` runs exact Cat Food build-plan bytes through the
actual owner collector and deterministic supervisor path. It covers mixed
CONTINUE/HUMAN work, independent WAIT/HUMAN/DONE decisions, stable replay,
preserved failed attempts, explicit unsupported/conditional scope, and
rejection of omitted cells, partial pagination, ref movement, stale evidence,
unsupported-as-PASS, and unevidenced supersession. These are host-side contract
controls. They do not establish a live model judgment, build, package,
installation, launch, or physical-device result.

## Dispatch contract

`tests/test-dispatch.sh` defines the controller boundary:

- CONTINUE sends the next prompt to the existing worker;
- WAIT sends no new work;
- HUMAN sends no worker prompt and surfaces the human-only question;
- DONE sends no new work.

That test remains intentionally red until `bin/cockswain-dispatch` exists. The recurring Cockswain job must stay paused until the dispatch boundary and a selected live supervisor model are accepted.
