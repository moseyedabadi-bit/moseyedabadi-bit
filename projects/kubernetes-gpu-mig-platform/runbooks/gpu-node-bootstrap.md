# GPU Node Bootstrap Runbook

This runbook describes the order of operations, not a distribution-specific installer.

## 1. Baseline the host

Record:

```bash
hostnamectl
uname -a
lscpu
free -h
lsblk -f
ip -br addr
```

Do not publish production output without sanitization.

## 2. Verify NVIDIA driver

```bash
nvidia-smi
```

Stop if the GPU is not healthy at the host level.

## 3. Inspect MIG capability

```bash
nvidia-smi mig -lgip
```

Choose a profile supported by the exact GPU.

## 4. Configure MIG during a maintenance window

For a two-slice H100 80 GB example:

```bash
sudo nvidia-smi -mig 1
sudo nvidia-smi mig -cgi 3g.40gb,3g.40gb -C
nvidia-smi -L
```

Do not delete an existing layout while GPU workloads are running.

## 5. Install/configure container runtime

Use containerd with systemd cgroups when appropriate for the Kubernetes distribution.

Validate:

```bash
systemctl is-active containerd
```

## 6. Install NVIDIA Container Toolkit

Follow NVIDIA's current official documentation for the target distribution and container runtime.

Validate the runtime configuration before starting production workloads.

## 7. Bootstrap Kubernetes

The exact kubeadm/RKE2/other distribution commands are environment-specific.

Record:

- Kubernetes version
- Pod CIDR
- Service CIDR
- CNI
- API endpoint
- node role

Do not put production values in a public repository.

## 8. Deploy NVIDIA device plugin

Choose a plugin version compatible with your Kubernetes version and driver stack.

For uniform MIG partitions, configure:

```yaml
migStrategy: single
```

If using CDI through CRI, ensure the entire CRI/containerd/Kubernetes path supports it.

## 9. Verify GPU resources

```bash
kubectl describe node <GPU_NODE_NAME> | \
  grep -A12 -E 'Capacity:|Allocatable:'
```

## 10. Apply namespaces and quotas

```bash
kubectl apply -f manifests/namespaces.yaml
kubectl apply -f manifests/resource-quotas.yaml
```

Adjust quotas to the actual node budget.

## 11. Configure persistent storage

Only after storage zoning/masking/multipath validation.

```bash
kubectl apply -f manifests/fc-pv-pvc-example.yaml
```

Replace every placeholder first.

## 12. Deploy workspaces

```bash
kubectl apply -f manifests/team-a-deployment.yaml
kubectl apply -f manifests/team-b-deployment.yaml
```

## 13. Acceptance

```bash
bash scripts/verify-platform.sh
```

Then manually validate:

- one MIG slice per team
- expected CPU/RAM resources
- expected QoS class
- persistent file survives Pod recreation
- services recover after node reboot
