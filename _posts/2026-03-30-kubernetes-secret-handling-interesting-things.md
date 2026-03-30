---
title: Interesting things in Kubernetes Secret handling
author: hajnalmt
categories: [Kubernetes, Security]
tags: [kubernetes, secrets, security, devops, rbac, encryption]
toc: true
pin: true
---

Kubernetes Secrets look simple at first glance, but real-world handling has
some non-obvious behavior. This is a practical walkthrough of details that are
easy to miss, especially when moving from a small cluster to production.
> Quick reminder: a Secret is only base64-encoded by default; it is not
> encrypted by itself.
{: .prompt-warning}

### 1) Base64 is transport format, not protection

The `data` field of a Secret stores values as base64 strings. That helps with
serialization, but it is not a security boundary.

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-credentials
type: Opaque
data:
  username: YWRtaW4=
  password: c3VwZXJzZWNyZXQ=
```

Anyone who can read the Secret object from the API can decode these values.
Treat base64 as packaging only.

### 2) `stringData` is convenient, but write-only

For humans, `stringData` is easier than encoding by hand:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-credentials
type: Opaque
stringData:
  username: admin
  password: supersecret
```

The API server converts `stringData` to `data` at write time. When you read the
object back, you only get `data`. This matters when writing GitOps diff logic
or admission checks that expect `stringData` to still exist.

You can see this directly with `kubectl`:

```bash
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: demo-stringdata
  namespace: default
type: Opaque
stringData:
  username: admin
  password: supersecret
EOF

kubectl get secret demo-stringdata -n default -o yaml
```

The returned object includes `data`, not `stringData`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: demo-stringdata
  namespace: default
type: Opaque
data:
  username: YWRtaW4=
  password: c3VwZXJzZWNyZXQ=
```

### 3) Volume updates are dynamic; environment variables are not

If a Secret is mounted as a volume, Kubernetes can refresh files after the
Secret changes (with kubelet sync and cache delays). If the same Secret is
consumed as an environment variable, the running process will not get updates
automatically.

In practice:
- mounted file: usually updates without pod restart
- environment variable: restart rollout needed

This difference is one of the most common sources of confusion during incident
response.

### 4) Immutable Secrets can reduce accidental breakage

For Secrets that should not change, set `immutable: true`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: ca-bundle
immutable: true
type: Opaque
data:
  ca.crt: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0t...
```

This prevents in-place updates and can reduce API server load in large
clusters. The tradeoff is operational: rotation becomes a create-new-secret and
repoint workflow.

### 5) ServiceAccount tokens changed significantly

Long-lived ServiceAccount token Secrets used to be common. Modern Kubernetes
prefers short-lived, automatically rotated tokens via TokenRequest and projected
volumes.

If you still see static `kubernetes.io/service-account-token` Secrets broadly
used, that is usually a sign of legacy behavior and worth revisiting.

### 6) Encryption at rest is cluster-level, and easy to skip

Secrets in `etcd` are not automatically protected unless encryption at rest is
configured on the API server. Production clusters should use an
`EncryptionConfiguration`, ideally with a KMS provider for key management and
rotation controls.

Without this, anyone with direct `etcd` access can read Secret values in plain
form.

Minimal `EncryptionConfiguration` example:

```yaml
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: <base64-32-byte-key>
      - identity: {}
```

The API server typically references this file via
`--encryption-provider-config=/etc/kubernetes/enc/enc.yaml`.

### 7) RBAC is usually the real control plane for Secret safety

Most Secret exposure events are authorization issues, not cryptography issues.

Patterns that help:
- avoid wildcard `get/list/watch` on Secrets
- scope access by namespace and workload identity
- restrict who can create Pods in sensitive namespaces (pod creation can become
  secret read by mounting/injecting)
- audit `cluster-admin` usage and broad controller permissions

Concrete RBAC example for one namespace (`payments`) where an app can only read
one specific Secret:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: payments-secret-reader
  namespace: payments
rules:
  - apiGroups: [""]
    resources: ["secrets"]
    resourceNames: ["stripe-api-key"]
    verbs: ["get"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: payments-secret-reader-binding
  namespace: payments
subjects:
  - kind: ServiceAccount
    name: payments-api
    namespace: payments
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: payments-secret-reader
```

Quick checks:

```bash
kubectl auth can-i get secret/stripe-api-key \
  --as=system:serviceaccount:payments:payments-api -n payments

kubectl auth can-i list secrets \
  --as=system:serviceaccount:payments:payments-api -n payments
```

### 8) External secret managers solve distribution, not policy for free

Operators such as External Secrets Operator or CSI Secret Store can pull values
from dedicated systems (AWS Secrets Manager, GCP Secret Manager, HashiCorp
Vault, Azure Key Vault, etc.). This improves secret source-of-truth and
rotation workflows, but RBAC, namespace boundaries, and workload identity still
decide who can consume what.

In other words: moving secrets out of Git is great, but it does not replace
authorization design.

### Closing thoughts

Kubernetes Secret handling is mostly about operational discipline:
- know where plaintext can appear (API access, logs, shell history, CI output)
- choose the right consumption model (file vs env var)
- enforce least privilege with RBAC and namespace policy
- configure encryption at rest and have a rotation story

The platform gives the primitives, but your policies and defaults determine the
actual security level.

### References

1. Kubernetes docs - Secrets: https://kubernetes.io/docs/concepts/configuration/secret/
2. Kubernetes docs - Distribute credentials securely to Pods:
   https://kubernetes.io/docs/tasks/inject-data-application/distribute-credentials-secure/
3. Kubernetes docs - Immutable Secrets and ConfigMaps:
   https://kubernetes.io/docs/concepts/configuration/secret/#immutable-secrets
4. Kubernetes docs - ServiceAccount token volume projection:
   https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/
5. Kubernetes docs - Encrypt data at rest:
   https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/
6. Kubernetes docs - RBAC reference:
   https://kubernetes.io/docs/reference/access-authn-authz/rbac/
7. External Secrets Operator docs: https://external-secrets.io/latest/
8. Secrets Store CSI Driver docs:
   https://secrets-store-csi-driver.sigs.k8s.io/
