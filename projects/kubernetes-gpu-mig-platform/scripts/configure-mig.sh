#!/usr/bin/env bash
set -euo pipefail

# Public reference script.
# Default example: two 3g.40gb instances on a compatible 80 GB MIG GPU.
#
# WARNING:
# This script changes GPU partitioning. Run only during a maintenance window.
# Existing MIG instances may need to be deleted before applying a different layout.
# Never delete MIG instances while workloads are active.

PROFILE="${PROFILE:-3g.40gb}"
COUNT="${COUNT:-2}"
APPLY="${APPLY:-false}"

if ! command -v nvidia-smi >/dev/null 2>&1; then
  echo "ERROR: nvidia-smi not found." >&2
  exit 1
fi

echo "=== GPU inventory ==="
nvidia-smi -L

echo
echo "=== Supported GPU instance profiles ==="
sudo nvidia-smi mig -lgip

echo
echo "Requested layout: ${COUNT} x ${PROFILE}"

if [[ "${APPLY}" != "true" ]]; then
  echo
  echo "DRY RUN ONLY."
  echo "Review the supported profile table and confirm the GPU is idle."
  echo "To apply:"
  echo "  sudo APPLY=true PROFILE='${PROFILE}' COUNT='${COUNT}' $0"
  exit 0
fi

active_pids="$(
  nvidia-smi --query-compute-apps=pid --format=csv,noheader,nounits 2>/dev/null \
    | sed '/^[[:space:]]*$/d' || true
)"

if [[ -n "${active_pids}" ]]; then
  echo "ERROR: active GPU compute processes detected:" >&2
  echo "${active_pids}" >&2
  echo "Stop GPU workloads before changing MIG geometry." >&2
  exit 1
fi

profiles=""
for ((i=1; i<=COUNT; i++)); do
  if [[ -z "${profiles}" ]]; then
    profiles="${PROFILE}"
  else
    profiles="${profiles},${PROFILE}"
  fi
done

echo "Enabling MIG mode..."
sudo nvidia-smi -mig 1

echo
echo "If an incompatible existing layout is present, this command may fail."
echo "This script does NOT automatically delete existing instances."
echo "Delete/recreate only after an explicit maintenance decision."

sudo nvidia-smi mig -cgi "${profiles}" -C

echo
echo "=== Result ==="
nvidia-smi -L
