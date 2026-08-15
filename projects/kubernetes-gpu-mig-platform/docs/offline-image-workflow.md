# Offline Image Workflow

Private or restricted environments often cannot pull reliably from public registries.

A practical pattern is:

```text
Internet-connected build node
  -> build image
  -> smoke test
  -> export tar
  -> SHA256
  -> controlled transfer
  -> import into containerd
  -> Kubernetes rollout
```

## Build

```bash
docker build \
  -t example/workspace:2026.08.15 \
  .
```

Use immutable version tags. Avoid relying on `latest`.

## Smoke test

```bash
docker run --rm example/workspace:2026.08.15 \
  /bin/bash -lc 'python3 --version || true'
```

For GPU images, test on a GPU-capable build/test host when possible.

## Export

```bash
docker save \
  example/workspace:2026.08.15 \
  -o workspace-2026.08.15.tar

sha256sum workspace-2026.08.15.tar \
  > workspace-2026.08.15.tar.sha256
```

## Transfer

Use the approved internal transfer path. Example:

```bash
scp workspace-2026.08.15.tar* \
  <GPU_NODE_USER>@<GPU_NODE_IP>:/tmp/
```

## Verify destination checksum

```bash
cd /tmp
sha256sum -c workspace-2026.08.15.tar.sha256
```

## Import into Kubernetes containerd

The namespace used by kubelet/containerd is commonly `k8s.io`:

```bash
sudo ctr -n k8s.io images import \
  /tmp/workspace-2026.08.15.tar
```

Verify:

```bash
sudo ctr -n k8s.io images list | grep workspace
```

or with CRI tooling:

```bash
sudo crictl images | grep workspace
```

## Deployment manifest

For intentionally preloaded images:

```yaml
imagePullPolicy: Never
```

Then use the exact imported image reference.

## Rollout

```bash
kubectl set image deployment/workspace \
  workspace=example/workspace:2026.08.15 \
  -n team-a

kubectl rollout status deployment/workspace \
  -n team-a \
  --timeout=300s
```

## Rollback

```bash
kubectl rollout undo deployment/workspace \
  -n team-a
```

Retain at least one known-good image until the new image passes acceptance tests.
