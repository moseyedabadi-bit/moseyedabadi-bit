# Kubernetes GPU MIG Platform

A sanitized, vendor-neutral reference implementation for running isolated GPU-enabled development workspaces on Kubernetes with NVIDIA MIG, explicit CPU/RAM allocation, persistent storage, and offline-friendly image workflows.

> **Public reference architecture.** This repository intentionally contains no production IP addresses, hostnames, domains, usernames, WWIDs, UUIDs, credentials, organization names, or environment-specific secrets.

## What this repository teaches

This project shows how to move from a bare GPU server to a Kubernetes platform where separate teams receive isolated resources:

- NVIDIA MIG partitions for hard GPU isolation
- Kubernetes namespaces and resource quotas
- explicit CPU and memory requests/limits
- `Guaranteed` QoS for predictable workloads
- persistent workspace storage
- optional Fibre Channel / multipath-backed static PVs
- offline image build, export, transfer, and import
- safe rollout, rollback, reboot recovery, and verification

## Reference topology

```text
                    ┌──────────────────────────────┐
                    │        Kubernetes Node       │
                    │                              │
                    │  CPU / RAM / local runtime   │
                    │                              │
                    │  NVIDIA GPU with MIG         │
                    │   ├─ MIG slice 1 ─ Team A    │
                    │   └─ MIG slice 2 ─ Team B    │
                    │                              │
                    │  containerd + kubelet        │
                    └──────────────┬───────────────┘
                                   │
                              Kubernetes
                         namespaces / quotas
                                   │
                  ┌────────────────┴───────────────┐
                  │                                │
             Team A Pod                       Team B Pod
          CPU / RAM / MIG                  CPU / RAM / MIG
          persistent PVC                   persistent PVC
                  │                                │
                  └──────────────┬─────────────────┘
                                 │
                         Optional SAN storage
                         FC + DM-Multipath
```

## Example GPU design

For an NVIDIA H100 80 GB GPU, NVIDIA documents that the `3g.40gb` MIG profile can be instantiated twice. A simple two-team layout is therefore:

```text
H100 80 GB
├── MIG 3g.40gb  -> Team A
└── MIG 3g.40gb  -> Team B
```

The exact profile set depends on the GPU model. Always inspect the supported profiles on the target host before creating instances.

```bash
nvidia-smi
nvidia-smi mig -lgip
```

## Recommended reading order

1. [`docs/architecture.md`](docs/architecture.md)
2. [`docs/gpu-mig-design.md`](docs/gpu-mig-design.md)
3. [`docs/resource-sizing.md`](docs/resource-sizing.md)
4. [`docs/storage-design.md`](docs/storage-design.md)
5. [`docs/offline-image-workflow.md`](docs/offline-image-workflow.md)
6. [`docs/security-model.md`](docs/security-model.md)
7. [`runbooks/gpu-node-bootstrap.md`](runbooks/gpu-node-bootstrap.md)
8. [`runbooks/workload-deployment.md`](runbooks/workload-deployment.md)
9. [`docs/troubleshooting.md`](docs/troubleshooting.md)

For AI tools and coding agents, read [`llms.txt`](llms.txt) first.

## Repository layout

```text
.
├── README.md
├── PROJECT.yaml
├── llms.txt
├── SECURITY.md
├── LICENSE.md
├── docs/
│   ├── architecture.md
│   ├── gpu-mig-design.md
│   ├── resource-sizing.md
│   ├── storage-design.md
│   ├── offline-image-workflow.md
│   ├── security-model.md
│   └── troubleshooting.md
├── manifests/
│   ├── namespaces.yaml
│   ├── resource-quotas.yaml
│   ├── team-a-deployment.yaml
│   ├── team-b-deployment.yaml
│   └── fc-pv-pvc-example.yaml
├── runbooks/
│   ├── gpu-node-bootstrap.md
│   └── workload-deployment.md
└── scripts/
    ├── configure-mig.sh
    └── verify-platform.sh
```

## Core design principles

- Reserve resources for the host and Kubernetes before assigning workloads.
- Treat GPU slices as schedulable resources, not as manually selected UUIDs in application manifests.
- Prefer `requests == limits` for workloads that require predictable CPU/RAM and `Guaranteed` QoS.
- Never mount the same single-writer filesystem read/write from multiple nodes at the same time.
- Keep credentials in Kubernetes Secrets or an external secret system; never commit them.
- Prefer immutable image tags or image digests for production.
- Make GPU geometry reproducible after reboot.
- Verify storage, GPU visibility, services, and QoS after every rollout.

## Quick example: team resource allocation

A node with 128 logical CPUs and about 2 TiB of RAM might reserve a meaningful margin for the OS, kubelet, container runtime, control-plane components, monitoring, and emergency headroom.

An illustrative allocation could be:

```yaml
node_example:
  cpu_capacity: 128
  memory_capacity: "~2TiB"

host_headroom:
  cpu: "~16"
  memory: "~256Gi"

team_a:
  cpu: 56
  memory: 880Gi
  gpu: 1

team_b:
  cpu: 56
  memory: 880Gi
  gpu: 1
```

An asymmetric workload is equally valid when business requirements differ:

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

These are examples, not universal recommendations. Size from actual `Capacity`, `Allocatable`, system-daemon usage, workload profiles, and failure/recovery requirements.

## Kubernetes QoS

If every container in a Pod has CPU and memory requests equal to its limits, Kubernetes can classify the Pod as `Guaranteed`.

Example:

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

Verify:

```bash
kubectl get pods -n team-a \
  -o custom-columns=NAME:.metadata.name,QOS:.status.qosClass
```

## References

- Kubernetes: Pod Quality of Service Classes
- Kubernetes: Reserve Compute Resources for System Daemons
- Kubernetes: Volumes / Fibre Channel
- NVIDIA Multi-Instance GPU User Guide
- NVIDIA Kubernetes Device Plugin

See the documentation files for links and implementation notes.

## Scope

This repository focuses on infrastructure patterns. It does **not** provide:

- production credentials
- organization-specific network configuration
- vendor support entitlements
- a universal sizing calculator
- a guarantee that a specific GPU profile is available on every accelerator
- a replacement for backup, monitoring, security review, or change management

## License

MIT. See [`LICENSE.md`](LICENSE.md).
