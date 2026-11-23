# Supervisor contract

Cockswain receives a work state and chooses one next action.

## CONTINUE

Choose CONTINUE when useful work remains that the working ChatGPT thread can perform without human judgment.

The result should contain one short next prompt. It should advance the first unresolved point rather than repeat settled background.

## WAIT

Choose WAIT only when progress depends on a concrete external event such as a currently running CI job and there is no useful parallel investigation to request.

Name the event being awaited.

## HUMAN

Choose HUMAN only when a human decision or action is genuinely required. Examples include choosing between incompatible unstated semantics, granting credentials, or performing a physical action.

Uncertainty is not itself a reason to choose HUMAN. If ChatGPT can investigate, inspect evidence, run another check, or narrow the question, choose CONTINUE.

## DONE

Choose DONE only when the stated completion conditions appear satisfied and secondary discoveries are either resolved or durably tracked.

DONE is not terminal authority. The controller must independently refresh objective state before retiring the item. If that refresh contradicts the model's conclusion, the item returns to CONTINUE or WAIT.

## Error priorities

1. False DONE.
2. False HUMAN.
3. Failure to continue useful work.
4. Weak or repetitive next prompt.
5. Extra latency or compute.

The evaluation harness reports the first two explicitly.

## Objective owner records

When a work item comes from `cockswain-owner-collect`, the owner revision,
complete denominator, cells, attempts and evidence identities are objective
inputs. `cockswain-owner-state` validates them before choosing an action. Useful
mechanical cells take precedence over waiting and human-only cells. DONE is
allowed only after a fresh complete enumeration contains no failed,
actionable, waiting, or human-only cell.

Owner-declared unsupported or conditional scope remains visible with its
reason; it is not PASS. A complete cell requires source-bound evidence at its
declared acceptance kind. A superseded cell remains in history and needs a
same-scope successor plus exact supersession evidence.
