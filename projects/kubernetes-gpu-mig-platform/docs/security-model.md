# Security Model

## Trust boundaries

```text
Host administrator
   │
   ├─ owns node, runtime, kubelet, drivers, storage mapping
   │
Kubernetes
   │
   ├─ namespace: team-a
   └─ namespace: team-b
          │
       workloads
```

## Workload rules

A team workspace should not need:

```yaml
hostNetwork: true
hostPID: true
privileged: true
```

Avoid `hostPath` for persistent team data.

Use PVC-backed storage.

## Secrets

Do not store passwords directly in manifests.

Example:

```bash
kubectl create secret generic workspace-credentials \
  -n team-a \
  --from-literal=root-password='<ENTER_INTERACTIVELY_OR_FROM_SECURE_SOURCE>'
```

Prefer application-specific non-root users where possible.

## Service exposure

For administrative interfaces such as JupyterLab, code-server, or noVNC, prefer one of:

- internal ingress with authentication and TLS
- VPN/private network
- SSH tunneling

Avoid exposing development services directly to untrusted networks.

## GPU isolation

Request the GPU through Kubernetes:

```yaml
resources:
  limits:
    nvidia.com/gpu: "1"
```

Do not inject a production MIG UUID manually into a public manifest.

## Service accounts

Disable automatic service-account token mounting when the workspace does not need Kubernetes API access:

```yaml
automountServiceAccountToken: false
```

## Pod security

Use the narrowest privileges that still allow the workload to function.

GPU support should be implemented through the node runtime/device plugin stack, not by making application Pods privileged.
