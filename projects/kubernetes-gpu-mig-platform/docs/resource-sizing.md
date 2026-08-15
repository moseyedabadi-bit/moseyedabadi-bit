# CPU and Memory Sizing

## First rule: size from Allocatable, not from wishful Capacity

Collect:

```bash
kubectl get node <GPU_NODE_NAME> \
  -o jsonpath='Capacity CPU: {.status.capacity.cpu}{"\n"}Capacity Memory: {.status.capacity.memory}{"\n"}Allocatable CPU: {.status.allocatable.cpu}{"\n"}Allocatable Memory: {.status.allocatable.memory}{"\n"}'
```

Then inspect current requests:

```bash
kubectl describe node <GPU_NODE_NAME> | \
  sed -n '/Allocated resources:/,/Events:/p'
```

## Protect the host

The OS, kernel, kubelet, container runtime, CNI, monitoring, and control-plane components need resources.

Kubernetes provides:

```yaml
kubeReserved:
  cpu: "<MEASURED_VALUE>"
  memory: "<MEASURED_VALUE>"

systemReserved:
  cpu: "<MEASURED_VALUE>"
  memory: "<MEASURED_VALUE>"
```

Do not copy reservation values blindly. Profile the node first.

Official documentation:
https://kubernetes.io/docs/tasks/administer-cluster/reserve-compute-resources/

## Team policy

For strict workspaces where predictable performance is more important than opportunistic bursting, set CPU and memory requests equal to limits:

```yaml
resources:
  requests:
    cpu: "8"
    memory: "64Gi"
    nvidia.com/gpu: "1"
  limits:
    cpu: "8"
    memory: "64Gi"
    nvidia.com/gpu: "1"
```

When every container in the Pod satisfies the CPU and memory request/limit criteria, Kubernetes classifies it as `Guaranteed`.

Official documentation:
https://kubernetes.io/docs/concepts/workloads/pods/pod-qos/

## Equal allocation example

```yaml
node_example:
  cpu: 128
  memory: "~2TiB"

host_operational_headroom:
  cpu: "~16"
  memory: "~256Gi"

team_a:
  cpu: 56
  memory: 880Gi

team_b:
  cpu: 56
  memory: 880Gi
```

This demonstrates the pattern:

```text
workload_budget = allocatable - host/system margin
team_share = workload_budget / number_of_teams
```

## Asymmetric allocation example

Requirements do not always justify equal memory.

```yaml
team_a:
  cpu: 56
  memory: 90Gi
  gpu: 1

team_b:
  cpu: 56
  memory: 1670Gi
  gpu: 1
```

The important property is that total workload requests plus system workload requests remain below node Allocatable with operational headroom.

## Verify QoS

```bash
kubectl get pods -n team-a \
  -o custom-columns=NAME:.metadata.name,QOS:.status.qosClass

kubectl get pods -n team-b \
  -o custom-columns=NAME:.metadata.name,QOS:.status.qosClass
```

Expected for strict workspaces:

```text
Guaranteed
```

## Operational note

Memory limits are hard cgroup limits. A container that exceeds its limit can be OOM-killed. CPU limits are throttled rather than OOM-killed.

Monitor before increasing limits.
