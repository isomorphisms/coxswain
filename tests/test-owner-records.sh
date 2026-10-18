#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM

owner_revision=b387f90d3973aae39ba19d370a830da627299ab1
source_identity=873d03e86ec2e4a9236bb2d253fee3c8fde83b6c
policy_sha256=97bb5fc4a79eb34e53a53fb7a10e6ccd99feef3143345da2c5ffa18e7f3aa431
profile_sha256=9f7e65468378bd383bd26c34b589560880909797c0854e22756c1132c3102281
phone_scope=1111111111111111111111111111111111111111111111111111111111111111
c67_scope=2222222222222222222222222222222222222222222222222222222222222222
phone_evidence=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
c67_evidence=bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
cells_header='cell_id\ttarget\tsource_identity\tscope_sha256\tmaterial_sha256\tpolicy_sha256\tprofile_sha256\tacceptance_kind\tstate\tdependency_state\tevidence_kind\tevidence_locator\tevidence_source_identity\tevidence_sha256\tsuperseded_by\tsupersession_evidence_locator\tsupersession_evidence_sha256\treason\tnext_action'
attempts_header='cell_id\tattempt_id\tobservation\tsource_identity\tmaterial_sha256\tevidence_kind\tevidence_locator\tevidence_sha256\tdetail'

seal_collection() {
    directory=$1
    expected_pages=${2:-1}
    observed_pages=${3:-1}
    expected_cells=${4:-2}
    observed_cells=${5:-2}
    expected_attempts=${6:-2}
    observed_attempts=${7:-2}
    material=$(sha256sum "$directory/owner-record.tsv" | awk '{print $1}')
    cells_sha=$(sha256sum "$directory/cells.tsv" | awk '{print $1}')
    attempts_sha=$(sha256sum "$directory/attempts.tsv" | awk '{print $1}')
    {
        printf 'schema\tcockswain-owner-record-collection-v1\n'
        printf 'status\tCOMPLETE\n'
        printf 'enumeration_complete\tyes\n'
        printf 'owner\tisomorphisms/catfood\n'
        printf 'owner_schema\tcatfood-android-build-plan-v1\n'
        printf 'owner_revision\t%s\n' "$owner_revision"
        printf 'owner_locator\thttps://github.com/isomorphisms/catfood/blob/%s/android/plan-build.sh\n' "$owner_revision"
        printf 'expected_pages\t%s\n' "$expected_pages"
        printf 'observed_pages\t%s\n' "$observed_pages"
        printf 'expected_cells\t%s\n' "$expected_cells"
        printf 'observed_cells\t%s\n' "$observed_cells"
        printf 'expected_attempts\t%s\n' "$expected_attempts"
        printf 'observed_attempts\t%s\n' "$observed_attempts"
        printf 'owner_record_sha256\t%s\n' "$material"
        printf 'cells_sha256\t%s\n' "$cells_sha"
        printf 'attempts_sha256\t%s\n' "$attempts_sha"
        printf 'policy_sha256\t%s\n' "$policy_sha256"
        printf 'profile_sha256\t%s\n' "$profile_sha256"
    } > "$directory/collection.tsv"
}

new_case() {
    directory=$1
    phone_state=$2
    phone_dependency=$3
    c67_state=$4
    c67_dependency=$5
    mkdir -p "$directory"
    cp "$root/tests/owner-records/catfood-plan.tsv" "$directory/owner-record.tsv"
    material=$(sha256sum "$directory/owner-record.tsv" | awk '{print $1}')
    phone_kind=build
    phone_evidence_kind=-
    phone_locator=-
    phone_evidence_source=-
    phone_digest=-
    phone_reason=-
    phone_next=build-phone
    phone_observation=NOT_RUN
    c67_kind=physical
    c67_evidence_kind=-
    c67_locator=-
    c67_evidence_source=-
    c67_digest=-
    c67_reason=-
    c67_next=run-c67-physical
    c67_observation=NOT_RUN
    if [ "$phone_state" = COMPLETE ]; then
        mkdir -p "$directory/evidence"
        printf '%s\n' 'synthetic host build evidence for owner-controller testing' > "$directory/evidence/phone-build.tsv"
        phone_evidence=$(sha256sum "$directory/evidence/phone-build.tsv" | awk '{print $1}')
        phone_evidence_kind=build
        phone_locator=evidence/phone-build.tsv
        phone_evidence_source=$source_identity
        phone_digest=$phone_evidence
        phone_reason=complete
        phone_next=-
        phone_observation=PASS
    fi
    if [ "$c67_state" = COMPLETE ]; then
        mkdir -p "$directory/evidence"
        printf '%s\n' 'synthetic physical evidence bytes for owner-controller testing' > "$directory/evidence/c67-physical.tsv"
        c67_evidence=$(sha256sum "$directory/evidence/c67-physical.tsv" | awk '{print $1}')
        c67_evidence_kind=physical
        c67_locator=evidence/c67-physical.tsv
        c67_evidence_source=$source_identity
        c67_digest=$c67_evidence
        c67_reason=complete
        c67_next=-
        c67_observation=PASS
    elif [ "$c67_state" = UNSUPPORTED ]; then
        c67_kind=unsupported
        c67_reason=owner-declared-incompatible
        c67_next=-
        c67_observation=SKIPPED
    elif [ "$c67_state" = CONDITIONAL ]; then
        c67_kind=conditional
        c67_reason=condition-does-not-apply
        c67_next=-
        c67_observation=SKIPPED
    elif [ "$c67_state" = WAITING ]; then
        c67_next=wait-for-owner-dependency
    fi
    {
        printf '%b\n' "$cells_header"
        printf 'wegert-phone\tphone\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t-\t-\t-\t%s\t%s\n' \
            "$source_identity" "$phone_scope" "$material" "$policy_sha256" "$profile_sha256" \
            "$phone_kind" "$phone_state" "$phone_dependency" "$phone_evidence_kind" "$phone_locator" \
            "$phone_evidence_source" "$phone_digest" "$phone_reason" "$phone_next"
        printf 'wegert-c67\tc67\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t-\t-\t-\t%s\t%s\n' \
            "$source_identity" "$c67_scope" "$material" "$policy_sha256" "$profile_sha256" \
            "$c67_kind" "$c67_state" "$c67_dependency" "$c67_evidence_kind" "$c67_locator" \
            "$c67_evidence_source" "$c67_digest" "$c67_reason" "$c67_next"
    } > "$directory/cells.tsv"
    {
        printf '%b\n' "$attempts_header"
        printf 'wegert-phone\tphone-1\t%s\t%s\t%s\t%s\t%s\t%s\tphone-attempt\n' \
            "$phone_observation" "$source_identity" "$material" "$phone_evidence_kind" "$phone_locator" "$phone_digest"
        printf 'wegert-c67\tc67-1\t%s\t%s\t%s\t%s\t%s\t%s\tc67-attempt\n' \
            "$c67_observation" "$source_identity" "$material" "$c67_evidence_kind" "$c67_locator" "$c67_digest"
    } > "$directory/attempts.tsv"
    seal_collection "$directory"
}

reject_case() {
    name=$1
    expected=$2
    directory=$3
    if "$root/bin/cockswain-owner-state" --validate "$directory" >"$tmp/$name.out" 2>"$tmp/$name.err"; then
        printf 'invalid owner record survived: %s\n' "$name" >&2
        exit 1
    fi
    grep -F "$expected" "$tmp/$name.err" >/dev/null
}

# The real Cat Food plan bytes drive the actual collector and deterministic
# supervisor path. Mechanical work outranks the separately preserved C67
# physical boundary.
new_case "$tmp/mixed" ACTIONABLE READY HUMAN HUMAN_REQUIRED
work_item=$("$root/bin/cockswain-owner-collect" "$tmp/mixed" "$tmp/mixed-snapshot")
jq -e '.state.owner_obligations | length == 2' "$work_item" >/dev/null
jq -e '.state.owner_attempts | length == 2' "$work_item" >/dev/null
jq -e '.state.owner_obligations[] | has("source_identity") and has("evidence_sha256") and has("dependency_state")' \
    "$work_item" >/dev/null
COCKSWAIN_OWNER_STATE_DIRECTORY="$tmp/mixed-state" \
    "$root/bin/cockswain-supervise" "$work_item" > "$tmp/mixed-decision.json"
[ "$(jq -r .action "$tmp/mixed-decision.json")" = CONTINUE ]
[ "$(jq -r .next_prompt "$tmp/mixed-decision.json")" = build-phone ]
[ "$(jq -r .human_question "$tmp/mixed-decision.json")" = null ]

# Equal rescans reuse one digest-named receipt and do not duplicate obligations.
COCKSWAIN_OWNER_STATE_DIRECTORY="$tmp/mixed-state" \
    "$root/bin/cockswain-supervise" "$work_item" > "$tmp/mixed-replay.json"
cmp "$tmp/mixed-decision.json" "$tmp/mixed-replay.json"
[ "$(find "$tmp/mixed-state/scans" -type f | wc -l | tr -d ' ')" -eq 1 ]
[ "$(awk 'END {print NR-1}' "$tmp/mixed-state/cell-ledger.tsv")" -eq 2 ]

new_case "$tmp/wait" COMPLETE SATISFIED WAITING UNAVAILABLE
"$root/bin/cockswain-owner-collect" "$tmp/wait" "$tmp/wait-snapshot" >/dev/null
[ "$("$root/bin/cockswain-owner-state" "$tmp/wait-snapshot" "$tmp/wait-state" | awk -F '\t' '$1=="action" {print $2}')" = WAIT ]

new_case "$tmp/human" COMPLETE SATISFIED HUMAN HUMAN_REQUIRED
"$root/bin/cockswain-owner-collect" "$tmp/human" "$tmp/human-snapshot" >/dev/null
[ "$("$root/bin/cockswain-owner-state" "$tmp/human-snapshot" "$tmp/human-state" | awk -F '\t' '$1=="action" {print $2}')" = HUMAN ]

new_case "$tmp/done" COMPLETE SATISFIED UNSUPPORTED NOT_APPLICABLE
"$root/bin/cockswain-owner-collect" "$tmp/done" "$tmp/done-snapshot" >/dev/null
[ "$("$root/bin/cockswain-owner-state" "$tmp/done-snapshot" "$tmp/done-state" | awk -F '\t' '$1=="action" {print $2}')" = DONE ]
grep -Fq 'owner-declared-incompatible' "$tmp/done-snapshot/cells.tsv"

# Same-scope supersession remains a visible historical row and requires
# refreshable evidence bytes.
new_case "$tmp/superseded" COMPLETE SATISFIED COMPLETE SATISFIED
mkdir -p "$tmp/superseded/evidence"
printf '%s\n' 'same-scope owner supersession evidence' > "$tmp/superseded/evidence/supersession.tsv"
supersession_sha=$(sha256sum "$tmp/superseded/evidence/supersession.tsv" | awk '{print $1}')
awk -F '\t' -v OFS='\t' -v scope="$phone_scope" -v supersession="$supersession_sha" '
    NR==2 {
        $9="SUPERSEDED"; $10="SATISFIED"; $11="-"; $12="-"; $13="-"; $14="-"
        $15="wegert-c67"; $16="evidence/supersession.tsv"; $17=supersession
        $18="evidenced-same-scope-successor"; $19="-"
    }
    NR==3 {$4=scope; $8="build"; $11="build"}
    {print}
' "$tmp/superseded/cells.tsv" > "$tmp/superseded/cells.new"
mv "$tmp/superseded/cells.new" "$tmp/superseded/cells.tsv"
awk -F '\t' -v OFS='\t' 'NR==3 {$6="build"} {print}' \
    "$tmp/superseded/attempts.tsv" > "$tmp/superseded/attempts.new"
mv "$tmp/superseded/attempts.new" "$tmp/superseded/attempts.tsv"
seal_collection "$tmp/superseded"
"$root/bin/cockswain-owner-collect" "$tmp/superseded" "$tmp/superseded-snapshot" >/dev/null
[ "$("$root/bin/cockswain-owner-state" "$tmp/superseded-snapshot" "$tmp/superseded-state" | awk -F '\t' '$1=="action" {print $2}')" = DONE ]

new_case "$tmp/conditional" COMPLETE SATISFIED CONDITIONAL NOT_APPLICABLE
"$root/bin/cockswain-owner-state" --validate "$tmp/conditional"

# Omitted cells, incomplete pagination, ref movement and stale evidence cannot
# collapse the declared denominator into DONE.
cp -R "$tmp/done" "$tmp/omitted"
sed -n '1,2p' "$tmp/omitted/cells.tsv" > "$tmp/omitted/cells.new"
mv "$tmp/omitted/cells.new" "$tmp/omitted/cells.tsv"
seal_collection "$tmp/omitted"
reject_case omitted 'omitted or extra owner cell' "$tmp/omitted"

cp -R "$tmp/done" "$tmp/partial"
seal_collection "$tmp/partial" 2 1
reject_case partial 'partial owner pagination' "$tmp/partial"

cp -R "$tmp/done" "$tmp/moved-ref"
sed 's/^catfood_commit\t.*/catfood_commit\t0000000000000000000000000000000000000000/' \
    "$tmp/moved-ref/owner-record.tsv" > "$tmp/moved-ref/owner-record.new"
mv "$tmp/moved-ref/owner-record.new" "$tmp/moved-ref/owner-record.tsv"
seal_collection "$tmp/moved-ref"
reject_case moved-ref 'owner ref changed across the scan' "$tmp/moved-ref"

cp -R "$tmp/done" "$tmp/wrong-source"
awk -F '\t' -v OFS='\t' 'NR==2 {$13="0000000000000000000000000000000000000000"} {print}' \
    "$tmp/wrong-source/cells.tsv" > "$tmp/wrong-source/cells.new"
mv "$tmp/wrong-source/cells.new" "$tmp/wrong-source/cells.tsv"
seal_collection "$tmp/wrong-source"
reject_case wrong-source 'complete cell lacks current source-bound evidence' "$tmp/wrong-source"

cp -R "$tmp/done" "$tmp/stale-evidence"
printf '%s\n' changed >> "$tmp/stale-evidence/evidence/phone-build.tsv"
reject_case stale-evidence 'complete cell evidence bytes are missing or stale' "$tmp/stale-evidence"

cp -R "$tmp/done" "$tmp/symlink-evidence"
mv "$tmp/symlink-evidence/evidence/phone-build.tsv" "$tmp/symlink-evidence/outside-evidence.tsv"
ln -s ../outside-evidence.tsv "$tmp/symlink-evidence/evidence/phone-build.tsv"
reject_case symlink-evidence 'complete cell evidence bytes are missing or stale' "$tmp/symlink-evidence"

cp -R "$tmp/done" "$tmp/unsupported-pass"
awk -F '\t' -v OFS='\t' -v source="$source_identity" -v digest="$c67_evidence" '
    NR==3 {$11="physical"; $12="evidence/forged"; $13=source; $14=digest} {print}
' "$tmp/unsupported-pass/cells.tsv" > "$tmp/unsupported-pass/cells.new"
mv "$tmp/unsupported-pass/cells.new" "$tmp/unsupported-pass/cells.tsv"
seal_collection "$tmp/unsupported-pass"
reject_case unsupported-pass 'unsupported or conditional cell was promoted' "$tmp/unsupported-pass"

cp -R "$tmp/mixed" "$tmp/bad-supersession"
awk -F '\t' -v OFS='\t' 'NR==2 {$9="SUPERSEDED"; $10="SATISFIED"; $15="wegert-c67"; $16="-"; $17="-"} {print}' \
    "$tmp/bad-supersession/cells.tsv" > "$tmp/bad-supersession/cells.new"
mv "$tmp/bad-supersession/cells.new" "$tmp/bad-supersession/cells.tsv"
seal_collection "$tmp/bad-supersession"
reject_case bad-supersession 'unsupported supersession' "$tmp/bad-supersession"

# The collector reads and then rechecks the owner bytes; a ref/file change in
# that interval cannot produce a snapshot.
new_case "$tmp/midscan" ACTIONABLE READY HUMAN HUMAN_REQUIRED
hook=$tmp/change-owner-record
{
    printf '#!/bin/sh\n'
    printf 'printf %s\\n changed-during-scan >> "$1/owner-record.tsv"\n' "'#'"
} > "$hook"
chmod 0755 "$hook"
if COCKSWAIN_OWNER_TESTING=1 COCKSWAIN_OWNER_TEST_AFTER_COPY_CMD="$hook" \
    "$root/bin/cockswain-owner-collect" "$tmp/midscan" "$tmp/midscan-snapshot" \
    >"$tmp/midscan.out" 2>"$tmp/midscan.err"; then
    echo 'owner record changed midscan without rejection' >&2; exit 1
fi
grep -F 'owner record changed during collection' "$tmp/midscan.err" >/dev/null

# A failed attempt remains in the persistent run history. A later refresh may
# add another attempt, but it cannot erase the failure row.
new_case "$tmp/history-a" ACTIONABLE READY HUMAN HUMAN_REQUIRED
material=$(sha256sum "$tmp/history-a/owner-record.tsv" | awk '{print $1}')
awk -F '\t' -v OFS='\t' 'NR==2 {$3="FAIL"; $6="build"; $7="https://example.invalid/failure"; $8="cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"} {print}' \
    "$tmp/history-a/attempts.tsv" > "$tmp/history-a/attempts.new"
mv "$tmp/history-a/attempts.new" "$tmp/history-a/attempts.tsv"
seal_collection "$tmp/history-a"
"$root/bin/cockswain-owner-state" "$tmp/history-a" "$tmp/history-state" >/dev/null
cp -R "$tmp/history-a" "$tmp/history-b"
awk -F '\t' -v OFS='\t' 'NR==2 {$3="NOT_RUN"; $6="-"; $7="-"; $8="-"} {print}' \
    "$tmp/history-b/attempts.tsv" > "$tmp/history-b/attempts.new"
mv "$tmp/history-b/attempts.new" "$tmp/history-b/attempts.tsv"
seal_collection "$tmp/history-b"
if "$root/bin/cockswain-owner-state" "$tmp/history-b" "$tmp/history-state" \
    >"$tmp/history.out" 2>"$tmp/history.err"; then
    echo 'interrupted refresh erased a prior failure' >&2; exit 1
fi
grep -F 'prior owner attempt disappeared' "$tmp/history.err" >/dev/null

printf '%s\n' 'Cockswain owner-record collection and reconciliation: PASS'
