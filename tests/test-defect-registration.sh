#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
owner_checkout=${1:?point to the pinned ai-ci checkout}
incident=2026-10-holomorphic-generated-test-proxy
release="$owner_checkout/incidents/$incident/release/obligations.tsv"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM

jq -n --arg incident "$incident" '{state: {defect_registration: $incident}}' > "$tmp/item.json"
COCKSWAIN_DEFECT_RELEASE_FILE="$release" "$root/bin/cockswain-supervise" "$tmp/item.json" > "$tmp/decision.json"
jq -e '
    .action == "CONTINUE" and
    (.next_prompt | startswith("a05-aici-eval-enforcement (isomorphisms/ai-ci) ")) and
    (.evidence_gaps | length == 8) and
    any(.evidence_gaps[]; startswith("a05-catfood-device-bundle [pending] ")) and
    any(.evidence_gaps[]; startswith("a05-flexible-pipes-job-adapter [blocked] ")) and
    any(.evidence_gaps[]; startswith("a05-holomorphic-worker-smoke [ready] "))
' "$tmp/decision.json" >/dev/null

reject_release() {
    if COCKSWAIN_DEFECT_RELEASE_FILE="$1" "$root/bin/cockswain-supervise" "$tmp/item.json" > "$tmp/rejected" 2> "$tmp/diagnostic"; then
        echo 'invalid defect release reached a supervisor decision' >&2
        exit 1
    fi
    test ! -s "$tmp/rejected"
    grep -F 'differs from the released owner obligations' "$tmp/diagnostic" >/dev/null
}
awk -F '\t' '$1 != "a05-catfood-device-bundle"' "$release" > "$tmp/omitted.tsv"
reject_release "$tmp/omitted.tsv"

awk -F '\t' -v OFS='\t' 'NR > 1 {$6="complete"} {print}' "$release" > "$tmp/complete.tsv"
reject_release "$tmp/complete.tsv"

jq '.state.owner_record_snapshot = "untrusted"' "$tmp/item.json" > "$tmp/mixed.json"
if COCKSWAIN_DEFECT_RELEASE_FILE="$release" "$root/bin/cockswain-supervise" "$tmp/mixed.json" > "$tmp/rejected" 2> "$tmp/diagnostic"; then
    echo 'ambiguous owner work item reached a supervisor decision' >&2
    exit 1
fi
test ! -s "$tmp/rejected"
grep -F 'selects both an owner snapshot and a defect registration' "$tmp/diagnostic" >/dev/null

printf '%s\n' 'Released ai-ci defect registration and unresolved supervisor obligations: PASS'
