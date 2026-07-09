#!/usr/bin/env bash
#
# check-public.sh — refuse changes that ADD internal MCP doc IDs to this public repo.
#
# Internal IDs (#2152, doc_id=620) address rows in a private knowledge DB. In
# someone else's installation they resolve to unrelated documents, or to nothing
# at all. As parenthetical provenance they are merely noise; in an actionable
# form (`doc_id=NNN`) they are a live defect.
#
# The ~125 pre-existing occurrences are accepted as legacy baseline — rewriting
# them wholesale would churn live skill instructions for cosmetic gain. This
# guard only stops NEW ones from landing. Touching a legacy line makes it show
# up here, which is the natural moment to clean that one line.
#
#   ./check-public.sh                 # staged changes  (wire up as pre-commit)
#   ./check-public.sh --range A..B    # a commit range  (wire up as CI step)
#   ./check-public.sh --all           # full scan, prints the legacy baseline
#
# ADR-000N is intentionally NOT matched: those are public architecture decisions,
# not MCP row IDs.

set -uo pipefail

PATTERN='(#[0-9]{3,5}|doc_id=[0-9]{3,5})'
mode="${1:---staged}"

# Content files only, and never this script itself — its help text quotes the
# very IDs it hunts for, so an unscoped scan would flag the guard as a violation.
SCOPE=('*.md' '*.json' ':(exclude)check-public.sh')

if [ "$mode" = "--all" ]; then
  hits=$(grep -rnE "$PATTERN" . --include='*.md' --include='*.json' \
           --exclude-dir=.git --exclude='check-public.sh' 2>/dev/null || true)
  n=$(printf '%s' "$hits" | grep -c . || true)
  echo "legacy baseline: ${n} line(s) — exempt, not an error"
  [ "$n" -gt 0 ] && printf '%s\n' "$hits"
  exit 0
fi

if [ "$mode" = "--range" ]; then
  diff=$(git diff -U0 "${2:?usage: check-public.sh --range A..B}" -- "${SCOPE[@]}")
else
  diff=$(git diff --cached -U0 -- "${SCOPE[@]}")
fi

added=$(printf '%s\n' "$diff" | grep '^+' | grep -v '^+++' || true)
hits=$(printf '%s\n' "$added" | grep -E "$PATTERN" || true)

if [ -n "$hits" ]; then
  echo "FAIL: this change adds internal MCP doc IDs to a public repo:"
  printf '%s\n' "$hits" | sed 's/^/  /'
  echo
  echo "Drop the ID, keep the prose:"
  echo "  '(Bug#3229 proper fix)'        -> '(proper fix)'"
  echo "  'regression of Spec#2152'      -> 'a known regression'"
  echo "  'Reference: doc_id=620 …'      -> name the convention, not the row"
  echo
  echo "Legacy occurrences are exempt — see './check-public.sh --all'."
  exit 1
fi

echo "OK: no new internal IDs"
