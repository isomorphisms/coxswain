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
