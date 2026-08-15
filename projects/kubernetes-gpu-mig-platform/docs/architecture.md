# Architecture

## Goal

Provide separate teams with predictable CPU, RAM, GPU, and persistent storage while keeping the Kubernetes node stable and recoverable.

## Layers

```text
Hardware
  ├─ CPU
  ├─ RAM
  ├─ NVIDIA GPU
  └─ local / SAN storage
        │
Linux host
  ├─ NVIDIA driver
  ├─ DM-Multipath (optional)
  ├─ containerd
  └─ systemd
        │
Kubernetes node
  ├─ kubelet
  ├─ CNI
  ├─ NVIDIA device plugin
  └─ namespaces / quotas
        │
Workloads
  ├─ Team A workspace
  └─ Team B workspace
```

## Isolation model

### GPU

Use NVIDIA MIG when supported. MIG creates hardware-partitioned GPU instances with dedicated slices of memory and compute resources.

Kubernetes should schedule those partitions using the NVIDIA device plugin rather than an application hardcoding a production MIG UUID.

### CPU and memory

Use Kubernetes requests and limits.

For predictable workspaces:

```yaml
resources:
  requests:
    cpu: "16"
    memory: "128Gi"
  limits:
    cpu: "16"
    memory: "128Gi"
```

Matching requests and limits can contribute to `Guaranteed` Pod QoS when all containers satisfy the Kubernetes criteria.

### Namespace

Use a namespace per administrative or workload boundary:

```text
team-a
team-b
```

Attach a `ResourceQuota` to prevent accidental resource growth.

### Storage

Each team should receive a distinct persistent volume when using a single-writer filesystem such as ext4 or xfs.

```text
SAN LUN A -> PV A -> PVC A -> Team A /workspace
SAN LUN B -> PV B -> PVC B -> Team B /workspace
```

## Host safety

Do not allocate the entire physical node to application Pods.

The host still needs resources for:

- kernel
- ssh / remote recovery
- kubelet
- container runtime
- CNI
- control-plane components when co-located
- logging / metrics agents
- filesystem cache and storage services
- emergency operational headroom

Use `systemReserved` and `kubeReserved` only after profiling the node and validating recovery. Kubernetes Node Allocatable is the scheduler-facing mechanism for protecting node capacity.

Official documentation:
- https://kubernetes.io/docs/tasks/administer-cluster/reserve-compute-resources/
