#!/usr/bin/env bash
set -euo pipefail

DESC="${1:-}"
TOPICS_CSV="${2:-}"
if [[ -z "$DESC" || -z "$TOPICS_CSV" ]]; then
  echo "Usage: $0 <description> <topics-csv>" >&2
  echo "Example: $0 'Stateful MongoDB on Kubernetes using Helm...' kubernetes,helm,mongodb,devops,cicd,linode,ingress,cert-manager" >&2
  exit 1
fi

if ! command -v gh >/dev/null; then
  echo "GitHub CLI (gh) not found. See https://cli.github.com/" >&2
  exit 2
fi

IFS=',' read -r -a TOPICS <<< "$TOPICS_CSV"
CMD=(gh repo edit --description "$DESC")
for t in "${TOPICS[@]}"; do
  CMD+=(--add-topic "$t")
done
echo "→ ${CMD[*]}"
"${CMD[@]}"

