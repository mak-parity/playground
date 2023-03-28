#!/usr/bin/env bash
set -euo pipefail

# Script for generating a summary of PRs in Substrate,
# as requested in https://github.com/paritytech/opstooling/issues/185.

# Prerequisites:
# - jq
# - gq (gh cli uses it underneath so we use it too for consistency)

# DATE_FROM="2023-01-10"
# DATE_TO="2023-02-10"
# The --label search is an AND type of query.
RUNTIME_LABELS="B1-note_worthy,T1-runtime"
NODE_LABELS="B1-note_worthy,T0-node"
PR_TEMPLATE='{{range .}}

---

# [#{{.number}}]({{.url}}) {{.title}}

{{.body}}
{{end}}'


# First, get note-worthy runtime PRs.

RUNTIME_OUTPUT=$(
gh search prs --repo paritytech/substrate --limit 999 \
  --label "$RUNTIME_LABELS" \
  --merged-at="${DATE_FROM}..${DATE_TO}" \
  --json "number,title,body,url" \
  --template "$PR_TEMPLATE"
)
echo "Here are note-worthy **runtime** PRs in Substrate repo merged between ${DATE_FROM} and ${DATE_TO}.${RUNTIME_OUTPUT}" > 1_runtime.md

# Second, get note-worthy node PRs.

NODE_OUTPUT=$(
gh search prs --repo paritytech/substrate --limit 999 \
  --label "$NODE_LABELS" \
  --merged-at="${DATE_FROM}..${DATE_TO}" \
  --json "number,title,body,url" \
  --template "$PR_TEMPLATE"
)
echo "Here are note-worthy **node** PRs in Substrate repo merged between ${DATE_FROM} and ${DATE_TO}.${NODE_OUTPUT}" > 2_node.md

# Third, generate a list of all other PRs in case something was not labeled properly.
# It consists of not note-worthy PRs, or note-worthy without a node and runtime label.

NOT_NOTEWORTHY=$(
gh search prs --repo paritytech/substrate --limit 999 \
  --merged-at="${DATE_FROM}..${DATE_TO}" \
  --json "number,title,body,url" \
  -- -label:B1-note_worthy
)

NOTEWORTHY_NO_NODE_AND_RUNTIME=$(
gh search prs --repo paritytech/substrate --limit 999 \
  --merged-at="${DATE_FROM}..${DATE_TO}" \
  --json "number,title,body,url" \
  -- label:B1-note_worthy -label:T0-node,T1-runtime
)

REST_OUTPUT=$(
jq --argjson arg1 "$NOT_NOTEWORTHY" --argjson arg2 "$NOTEWORTHY_NO_NODE_AND_RUNTIME" \
  -n '$arg1 + $arg2 | unique' \
  | gq "$PR_TEMPLATE"
)

echo "Here is the rest of PRs in Substrate repo merged between ${DATE_FROM} and ${DATE_TO}.${REST_OUTPUT}" > 3_rest.md

echo -e "Generated markdown files with PR summaries.\nYou can create a (secret) gist by running:\ngh gist create 1_runtime.md 2_node.md 3_rest.md"
