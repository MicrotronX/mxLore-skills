#!/usr/bin/env bash
#
# check-public.sh — refuse changes that ADD internal MCP doc IDs to this public repo.
#
# Internal IDs (#2152, doc_id=620) address rows in a private knowledge DB. In
# someone else's installation they resolve to unrelated documents, or to nothing
# at all. As parenthetical provenance they are merely noise; in an actionable
# form (`doc_id=NNN`) they are a live defect.
#
# The repo carries no internal IDs any more — they were swept out on 2026-07-09,
# together with the canonical ~/.claude sources they are copied from. So this
# guard is now strict rather than incremental: `--all` must report zero, and any
# newly added occurrence fails. The former "legacy baseline" exemption is gone;
# it only ever existed because the backlog did.
#
#   ./check-public.sh                 # staged changes  (wire up as pre-commit)
#   ./check-public.sh --range A..B    # a commit range  (wire up as CI step)
#   ./check-public.sh --all           # full scan, must report zero
#
# ADR-000N is intentionally NOT matched: those are public architecture decisions,
# not MCP row IDs.
#
# The trailing \b keeps the pattern off CSS hex literals: `#2563eb` would
# otherwise match on its leading four digits. Two-digit placeholders in worked
# examples (`doc#12`, `ADR#12`) stay below the {3,5} floor by design.

set -uo pipefail

PATTERN='(#[0-9]{3,5}\b|doc_id=[0-9]{3,5})'
mode="${1:---staged}"

# Content files only, and never this script itself — its help text quotes the
# very IDs it hunts for, so an unscoped scan would flag the guard as a violation.
SCOPE=('*.md' '*.json' ':(exclude)check-public.sh')

if [ "$mode" = "--all" ]; then
  hits=$(grep -rnE "$PATTERN" . --include='*.md' --include='*.json' \
           --exclude-dir=.git --exclude='check-public.sh' 2>/dev/null || true)
  n=$(printf '%s' "$hits" | grep -c . || true)
  if [ "$n" -gt 0 ]; then
    echo "FAIL: ${n} internal ID(s) present (expected: 0)"
    printf '%s\n' "$hits"
    exit 1
  fi
  echo "OK: full scan clean — no internal IDs"
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
  echo "Full scan: './check-public.sh --all' — it must report zero."
  exit 1
fi

echo "OK: no new internal IDs"
