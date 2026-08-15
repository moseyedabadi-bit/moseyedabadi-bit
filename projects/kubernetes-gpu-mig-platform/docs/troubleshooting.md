# Troubleshooting

## Pod is Pending: insufficient GPU

```bash
kubectl describe pod <POD> -n <NAMESPACE>
kubectl describe node <GPU_NODE_NAME> | grep -A12 -E 'Capacity:|Allocatable:'
kubectl get pods -A -o wide
```

Check whether all MIG slices are already allocated.

## Kubernetes does not show GPU capacity

Host checks:

```bash
nvidia-smi
nvidia-smi -L
```

Device plugin checks:

```bash
kubectl get ds -A | grep -i nvidia
kubectl get pods -A | grep -i nvidia
kubectl logs -n <PLUGIN_NAMESPACE> <DEVICE_PLUGIN_POD>
```

If `nvidia-smi` fails on the host, fix the host driver/hardware problem before debugging Kubernetes.

## MIG exists but workload sees no GPU

Check:

```bash
kubectl describe pod <POD> -n <NAMESPACE>
kubectl exec -n <NAMESPACE> <POD> -- nvidia-smi -L
```

Then validate:

- NVIDIA Container Toolkit
- containerd runtime configuration
- device plugin configuration
- chosen device list strategy
- CDI support if using `cdi-cri`

## Pod QoS is Burstable instead of Guaranteed

```bash
kubectl get pod <POD> -n <NAMESPACE> \
  -o jsonpath='{.status.qosClass}{"\n"}'

kubectl get pod <POD> -n <NAMESPACE> \
  -o jsonpath='{.spec.containers[*].resources}{"\n"}'
```

Every container must satisfy the CPU and memory request/limit criteria.

## PVC is Pending

```bash
kubectl get pv
kubectl get pvc -A
kubectl describe pvc <PVC> -n <NAMESPACE>
```

For static PVs, check:

- PV capacity satisfies PVC request
- access mode matches
- storageClassName matches or is intentionally empty
- volumeName/selector is correct when used
- node affinity is correct
- LUN is visible to the node

## FC volume will not mount

Host:

```bash
sudo multipath -ll
lsblk -f
dmesg | tail -n 100
```

Kubernetes:

```bash
kubectl describe pod <POD> -n <NAMESPACE>
journalctl -u kubelet --since '-15 min'
```

Never reformat a device as a troubleshooting shortcut.

## Rollout leaves old and new Pods temporarily

During a Deployment rollout, old and new ReplicaSets can coexist briefly.

Check:

```bash
kubectl get pods -n <NAMESPACE> -o wide
kubectl get rs -n <NAMESPACE>
kubectl rollout status deployment/<DEPLOYMENT> -n <NAMESPACE>
```

If storage or GPU constraints require only one Pod at a time, use:

```yaml
strategy:
  type: Recreate
```

## OOMKilled

```bash
kubectl describe pod <POD> -n <NAMESPACE>
kubectl get pod <POD> -n <NAMESPACE> -o json
```

If the container hit its memory limit, profile the workload before increasing the limit. Preserve host headroom.

## Reboot validation

After reboot:

```bash
systemctl is-active containerd
systemctl is-active kubelet
nvidia-smi -L
kubectl get nodes
kubectl get pods -A
kubectl get pv,pvc -A
```

Then verify one GPU command and one persistent-file read per team.
