# Persistent Storage Design

## Generic design

```text
Storage Array
   │
   ├─ LUN A
   │    └─ FC zoning/masking
   │         └─ GPU node
   │              └─ DM-Multipath
   │                   └─ Kubernetes PV
   │                        └─ Team A PVC
   │                             └─ /workspace
   │
   └─ LUN B
        └─ FC zoning/masking
             └─ GPU node
                  └─ DM-Multipath
                       └─ Kubernetes PV
                            └─ Team B PVC
                                 └─ /workspace
```

## Stable identifiers

Do not depend on Linux paths such as:

```text
/dev/sdb
/dev/sdc
/dev/mapper/mpathb
```

Those names can change.

Use a stable storage identifier such as the LUN WWID in storage and multipath procedures.

Never publish a production WWID in a public repository.

## Multipath checks

```bash
sudo multipath -ll
lsblk -f
```

Confirm the expected size and path count before creating or mounting a filesystem.

## Static Fibre Channel PV example

See:

```text
manifests/fc-pv-pvc-example.yaml
```

The Kubernetes `fc` volume source can use either WWIDs or target WWNs + LUN. FC zoning and LUN masking must already be configured so the Kubernetes node can access the device.

Official Kubernetes documentation:
https://kubernetes.io/docs/concepts/storage/volumes/#fc

## Single-writer warning

A normal ext4 or xfs filesystem is not a clustered filesystem.

Do not mount the same LUN read/write on multiple nodes simultaneously.

For a simple workspace, use:

```yaml
accessModes:
  - ReadWriteOnce
```

and a reclaim policy appropriate to the data lifecycle, often:

```yaml
persistentVolumeReclaimPolicy: Retain
```

## Filesystem ownership

Initialize a new LUN only after confirming:

- correct WWID
- correct size
- correct host mapping
- no existing production filesystem
- correct multipath device

Formatting the wrong LUN is destructive.

## Kubernetes ownership model

Recommended relationship:

```text
1 LUN
  -> 1 filesystem
    -> 1 static PV
      -> 1 PVC
        -> 1 team workspace
```

This is intentionally simple and auditable.
