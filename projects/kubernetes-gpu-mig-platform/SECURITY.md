# Security and Sanitization Policy

This repository is intentionally safe for public use.

## Never commit

- production IP addresses or internal DNS names
- employee or customer identities
- usernames tied to a production environment
- passwords, API keys, tokens, certificates, private keys
- Kubernetes Secret values
- SAN WWPNs, target WWNs, LUN WWIDs, filesystem UUIDs
- GPU or MIG UUIDs copied from a production host
- hardware serial numbers, asset tags, support identifiers
- screenshots containing organization-specific information
- log excerpts that expose internal topology or identities

## Use placeholders

Use names such as:

```text
<GPU_NODE_IP>
<API_SERVER_ENDPOINT>
<SAN_LUN_WWID>
<TARGET_WWN>
<WORKSPACE_SIZE>
<IMAGE_REGISTRY>
```

## Before publishing a change

Run a local secret scanner if available, then manually review:

```bash
grep -RInE \
  '(password|token|secret|private[_ -]?key|BEGIN .*PRIVATE KEY|wwid|wwpn|uuid|10\.[0-9]+\.[0-9]+\.[0-9]+|192\.168\.[0-9]+\.[0-9]+)' \
  .
```

False positives are expected. Review every match.

## Production safety

Several operations in this repository can disrupt workloads, especially:

- enabling/disabling MIG mode
- deleting GPU/compute instances
- changing kubelet reservations
- remapping SAN LUNs
- changing multipath configuration

Use a maintenance window and a tested rollback path.
