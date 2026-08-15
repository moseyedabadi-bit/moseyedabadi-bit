# NVIDIA MIG Design

## Why MIG

MIG is useful when separate workloads need stronger GPU isolation than simple process sharing.

A MIG-capable GPU can expose multiple hardware-isolated GPU instances. The exact profile names and counts depend on the GPU model.

For NVIDIA H100 80 GB, NVIDIA documents that `3g.40gb` supports two instances.

Official profile reference:
https://docs.nvidia.com/datacenter/tesla/mig-user-guide/supported-mig-profiles.html

## Inspect before changing anything

```bash
nvidia-smi
nvidia-smi -L
sudo nvidia-smi mig -lgip
```

Never assume a profile ID from another GPU generation or driver. NVIDIA `nvidia-smi` accepts a profile ID, short profile name, or full profile name when creating GPU instances.

## Maintenance-window workflow

1. Stop GPU workloads.
2. Confirm no active compute processes.
3. Enable MIG mode if needed.
4. Remove old compute/GPU instances only if a layout change is intended.
5. Create the desired GPU and compute instances.
6. Verify with `nvidia-smi -L`.
7. Restart or verify the Kubernetes device plugin.
8. Confirm node GPU capacity.
9. Launch one validation Pod per slice.

Example for two equal H100 80 GB slices:

```bash
sudo nvidia-smi -mig 1
sudo nvidia-smi mig -cgi 3g.40gb,3g.40gb -C
nvidia-smi -L
```

Before recreating a layout, a clean-up operation may be required:

```bash
sudo nvidia-smi mig -dci
sudo nvidia-smi mig -dgi
```

Those commands are destructive to the current MIG layout. Do not run them while GPU workloads are active.

## Reboot persistence

Created MIG devices are not guaranteed to persist across a system reset. Make the desired geometry reproducible using a controlled boot-time mechanism such as a systemd unit or NVIDIA's MIG partition tooling.

This repository includes an example script:

```text
scripts/configure-mig.sh
```

## Kubernetes device plugin

The NVIDIA Kubernetes device plugin supports MIG strategies:

```text
none
single
mixed
```

For a node where every MIG device uses the same profile, `single` is simple. Under `single`, MIG devices are exposed as `nvidia.com/gpu` resources.

A configuration example:

```yaml
version: v1
flags:
  migStrategy: single
  plugin:
    deviceListStrategy: cdi-cri
    deviceIDStrategy: uuid
```

`cdi-cri` requires a compatible Kubernetes/CRI/container runtime path. If the environment does not support it, use a supported strategy such as `envvar`.

Official NVIDIA plugin:
https://github.com/NVIDIA/k8s-device-plugin

## Verify Kubernetes sees the slices

```bash
kubectl describe node <GPU_NODE_NAME> | grep -A10 -E 'Capacity:|Allocatable:'
```

Expected shape for two equal slices under `migStrategy=single`:

```text
nvidia.com/gpu: 2
```

Do not hardcode MIG UUIDs into team Deployment manifests. Let the scheduler/device plugin allocate a slice.
