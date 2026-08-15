# Workload Deployment Runbook

## Pre-change checks

```bash
kubectl get nodes
kubectl get pods -A
kubectl describe node <GPU_NODE_NAME> | \
  sed -n '/Allocated resources:/,/Events:/p'
```

Confirm sufficient unallocated CPU, RAM, and GPU resources.

## Create namespace

```bash
kubectl apply -f manifests/namespaces.yaml
```

## Apply ResourceQuota

```bash
kubectl apply -f manifests/resource-quotas.yaml
```

## Bind persistent storage

For static storage, confirm the PV/PVC is `Bound` before deploying the workspace.

```bash
kubectl get pv
kubectl get pvc -A
```

## Deploy

```bash
kubectl apply -f manifests/team-a-deployment.yaml
```

## Wait for rollout

```bash
kubectl rollout status deployment/workspace \
  -n team-a \
  --timeout=300s
```

## Validate resources

```bash
kubectl get deployment workspace \
  -n team-a \
  -o jsonpath='{.spec.template.spec.containers[0].resources}{"\n"}'
```

## Validate QoS

```bash
kubectl get pods -n team-a \
  -o custom-columns=NAME:.metadata.name,QOS:.status.qosClass
```

## Validate GPU

```bash
kubectl exec -n team-a deploy/workspace -- nvidia-smi -L
```

## Validate storage

```bash
kubectl exec -n team-a deploy/workspace -- df -h /workspace
```

Persistence test:

```bash
kubectl exec -n team-a deploy/workspace -- \
  sh -lc 'date -u > /workspace/persistence-test.txt'

kubectl delete pod \
  -n team-a \
  -l app=workspace

kubectl rollout status deployment/workspace \
  -n team-a \
  --timeout=300s

kubectl exec -n team-a deploy/workspace -- \
  cat /workspace/persistence-test.txt
```

## Rollback

```bash
kubectl rollout history deployment/workspace -n team-a
kubectl rollout undo deployment/workspace -n team-a
```
