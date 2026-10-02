#!/usr/bin/env bash

REPO="${REPO:-}"
WORKFLOW="${WORKFLOW:-}"
PRIOR_RUN_ID="${PRIOR_RUN_ID:-}"
FIND_RETRIES="${FIND_RETRIES:-20}"
FIND_RETRY_WAIT_TIME="${FIND_RETRY_WAIT_TIME:-15}"
RETRIES="${RETRIES:-180}"
RETRY_WAIT_TIME="${RETRY_WAIT_TIME:-30}"

if [[ -z "$REPO" ]]; then echo "REPO is not set"; exit 1; fi
if [[ -z "$WORKFLOW" ]]; then echo "WORKFLOW is not set"; exit 1; fi

RUN_ID=""

for ((i = 0; i < FIND_RETRIES; i++)); do
  CANDIDATE_ID=$(gh run list --repo "$REPO" --workflow "$WORKFLOW" --limit 1 --json databaseId --jq '.[0].databaseId // empty' 2>/dev/null)

  if [[ -n "$CANDIDATE_ID" && "$CANDIDATE_ID" != "$PRIOR_RUN_ID" ]]; then
    RUN_ID="$CANDIDATE_ID"
    break
  fi

  echo "Waiting for a new $WORKFLOW run to appear ..."
  sleep "$FIND_RETRY_WAIT_TIME"
done

if [[ -z "$RUN_ID" ]]; then
  echo "Error: no new $WORKFLOW run appeared"
  exit 1
fi

RUN_URL=$(gh run view "$RUN_ID" --repo "$REPO" --json url --jq '.url' 2>/dev/null)
echo "Found $WORKFLOW run: $RUN_URL"

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  {
    echo "run_id=${RUN_ID}"
    echo "run_url=${RUN_URL}"
  } >> "$GITHUB_OUTPUT"
fi

for ((i = 0; i < RETRIES; i++)); do
  RESULT=$(gh run view "$RUN_ID" --repo "$REPO" --json status,conclusion --jq '[.status, .conclusion] | @tsv' 2>/dev/null)
  STATUS="${RESULT%%$'\t'*}"
  CONCLUSION="${RESULT##*$'\t'}"

  if [[ "$STATUS" == "completed" ]]; then
    if [[ "$CONCLUSION" == "success" ]]; then
      echo "$WORKFLOW run $RUN_ID completed successfully"
      exit 0
    fi
    echo "Error: $WORKFLOW run $RUN_ID completed with conclusion '$CONCLUSION'"
    exit 1
  fi

  echo "Waiting for $WORKFLOW run $RUN_ID to finish (status: ${STATUS:-unknown}) ..."
  sleep "$RETRY_WAIT_TIME"
done

echo "Error: $WORKFLOW run $RUN_ID did not finish in time"
exit 1
