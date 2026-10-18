# Owner-record supervision

Cockswain consumes immutable snapshots of work owned elsewhere. It does not
move Cat Food cells, application policy, evidence, or attempt history into a
second canonical matrix.

`bin/cockswain-owner-collect OWNER_RECORD_DIRECTORY SNAPSHOT_DIRECTORY`
validates and snapshots four files:

- `owner-record.tsv`: the exact owner plan; the first supported producer is
  Cat Food `catfood-android-build-plan-v1`;
- `collection.tsv`: the Cockswain-side collection receipt, including the owner
  revision and locator, exact file digests, explicit cell/attempt denominators,
  page counts, and a positive completeness marker;
- `cells.tsv`: the lossless projection of stable owner cell identity, exact
  source/scope/material/policy/profile, acceptance kind, current dependency
  state, evidence identity, explicit reason and next action, and supported
  supersession;
- `attempts.tsv`: every observed attempt, including failed, interrupted,
  timed-out, skipped, and not-run attempts.

The collector reads the source twice around the copy. Ref or byte movement
during that interval rejects the snapshot. The projected work item retains the
cell and attempt rows instead of reducing them to a model summary.

`bin/cockswain-owner-state SNAPSHOT_DIRECTORY STATE_DIRECTORY` independently
revalidates the complete snapshot, records one digest-keyed scan receipt, and
selects one action. Failed and actionable mechanical cells select `CONTINUE`
before waits or physical/authority boundaries. A genuine unavailable or
in-flight dependency selects `WAIT`; a remaining physical or authority-only
cell selects `HUMAN`. `DONE` requires every declared cell to be complete,
explicitly unsupported/conditional with a reason, or validly superseded by a
same-scope cell.

The state directory retains the latest complete cell set and full attempt
history. A refresh may add attempts and obligations. It cannot omit a prior
cell or attempt, so interruption and retry do not erase a failure. Replaying
equal bytes reuses the same scan receipt and obligation identities.

Complete evidence must match the current source and material. Unsupported or
conditional cells cannot carry PASS evidence. Supersession requires an exact
evidence digest and a present successor with the same scope and acceptance
kind. Partial pagination, denominator mismatch, stale policy/profile/material,
changed refs, and absent evidence all reject before action selection.

`bin/cockswain-supervise` recognizes the collector's work item and routes these
objective states through the deterministic owner controller. It does not call a
model for this mechanical classification. Semantic claim interpretation still
requires a separately accepted model endpoint and its own qualification; no
fixture result is promoted to that boundary.

## Candidate compatibility inputs

[isomorphisms/catfood PR #143, “Bind Android currentness to approved package
graph (CF-A2-S2)”](https://github.com/isomorphisms/catfood/pull/143), exact
candidate head `7f4a3707a63812af1039ad80aea8ad7e86983670`, supplies the
unmerged approved-obligation and package-binding shape. The owner projection
keeps policy, material and dependency identities distinct so that candidate can
be consumed after its own acceptance; this branch does not treat it as released
Cat Food policy.

[isomorphisms/ai-ci PR #286, “Preserve stage failures and attempt history in
aggregate verdicts”](https://github.com/isomorphisms/ai-ci/pull/286), exact
candidate head `a9595ec901268dca0ebee99f594e0e8797668c39`, supplies the
unmerged observation vocabulary and lossless-attempt requirement. Cockswain
retains all owner attempts but does not relabel that candidate as an accepted
AICI verdict interface.
