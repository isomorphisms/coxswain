#!/bin/sh
# Offline adapter contract tests. No remote API and no merge.
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
mkdir -p "$tmp/ai-ci/merge"
printf 'repository\tpolicy\n' > "$tmp/registry.tsv"
cat > "$tmp/ai-ci/merge/collect-account.sh" <<'EOF'
#!/bin/sh
set -eu
[ "$1" = example ] || exit 1
mkdir -p "$3/managed"
printf 'schema\taici-account-collection-v2\nstatus\tCOMPLETE\nscope\towner-authored-visible-repositories\n' > "$3/collection.tsv"
printf 'repository\tpr\tresult\n' > "$3/managed/results.tsv"
EOF
chmod +x "$tmp/ai-ci/merge/collect-account.sh"
AICI_ROOT="$tmp/ai-ci" COCKSWAIN_ACCOUNT_OWNER=example COCKSWAIN_POLICY_REGISTRY="$tmp/registry.tsv" \
  sh "$root/bin/cockswain-collect-account" "$tmp/output"
grep -q 'COMPLETE' "$tmp/output/collection.tsv"
sed -i 's/COMPLETE/INCOMPLETE/' "$tmp/ai-ci/merge/collect-account.sh"
if AICI_ROOT="$tmp/ai-ci" COCKSWAIN_ACCOUNT_OWNER=example COCKSWAIN_POLICY_REGISTRY="$tmp/registry.tsv" \
  sh "$root/bin/cockswain-collect-account" "$tmp/output"; then
  echo 'incomplete collection incorrectly accepted' >&2; exit 1
fi
echo 'collector adapter: positive and incomplete-collection refusal PASS'


# The action adapter must reject stale heads and refuse unapproved writes.
sed -i 's/INCOMPLETE/COMPLETE/' "$tmp/ai-ci/merge/collect-account.sh"
cat >> "$tmp/ai-ci/merge/collect-account.sh" <<'EOF'
printf 'isomorphisms/example\t1\tREADY\n' >> "$3/managed/results.tsv"
mkdir -p "$3/managed/isomorphisms-example-1"
printf 'head_sha\tbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb\n' > "$3/managed/isomorphisms-example-1/pr.tsv"
printf 'state\tvalid\nauthority_kind\ttask-context\nreceipt_ref\treceipt-1\nscope_state\tsame\n' > "$3/managed/isomorphisms-example-1/authorization.tsv"
EOF
printf 'schema\tcockswain-retirement-action-request-v1\nrepository\tisomorphisms/example\npr\t1\nexpected_head\taaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\naction\tmerge\nauthority_kind\ttask-context\nauthority_receipt_ref\treceipt-1\n' > "$tmp/request.tsv"
AICI_ROOT="$tmp/ai-ci" COCKSWAIN_ACCOUNT_OWNER=example COCKSWAIN_POLICY_REGISTRY="$tmp/registry.tsv" \
  sh "$root/bin/cockswain-action-live" "$tmp/request.tsv" > "$tmp/result.tsv"
grep -qx "$(printf 'error_class\tSTALE_REQUEST')" "$tmp/result.tsv"
sed -i 's/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb/' "$tmp/request.tsv"
AICI_ROOT="$tmp/ai-ci" COCKSWAIN_ACCOUNT_OWNER=example COCKSWAIN_POLICY_REGISTRY="$tmp/registry.tsv" \
  sh "$root/bin/cockswain-action-live" "$tmp/request.tsv" > "$tmp/result.tsv"
grep -qx "$(printf 'error_class\tWRITE_DISABLED')" "$tmp/result.tsv"
echo 'stale-head and write-disabled refusal PASS'
