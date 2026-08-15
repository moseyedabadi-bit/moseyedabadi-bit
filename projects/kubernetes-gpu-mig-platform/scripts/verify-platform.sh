#!/usr/bin/env bash
set -euo pipefail

NODE="${NODE:-}"

echo "=== Nodes ==="
kubectl get nodes -o wide

if [[ -n "${NODE}" ]]; then
  echo
  echo "=== GPU node allocatable ==="
  kubectl get node "${NODE}" \
    -o jsonpath='CPU: {.status.allocatable.cpu}{"\n"}Memory: {.status.allocatable.memory}{"\n"}GPU: {.status.allocatable.nvidia\.com/gpu}{"\n"}'
fi

echo
echo "=== NVIDIA device plugin ==="
kubectl get pods -A | grep -i nvidia || true

echo
echo "=== Team namespaces ==="
for ns in team-a team-b; do
  echo "--- ${ns} ---"
  kubectl get pods -n "${ns}" \
    -o custom-columns=NAME:.metadata.name,PHASE:.status.phase,QOS:.status.qosClass \
    2>/dev/null || true
  kubectl get pvc -n "${ns}" 2>/dev/null || true
done

echo
echo "=== Node allocated resources ==="
if [[ -n "${NODE}" ]]; then
  kubectl describe node "${NODE}" | \
    sed -n '/Allocated resources:/,/Events:/p'
else
  echo "Set NODE=<gpu-node-name> for node allocation details."
fi
