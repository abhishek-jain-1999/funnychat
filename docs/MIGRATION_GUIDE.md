# Migration Guide: KIND to Production (Kubeadm / EKS)

This guide outlines the steps to migrate your Chat App from the local KIND setup to a production Kubernetes cluster.

## 1. Infrastructure Setup

### Kubeadm (Self-Managed)
-   Provision servers (1 Master, N Workers).
-   Initialize cluster: `kubeadm init`.
-   Join workers: `kubeadm join ...`.
-   Install CNI (e.g., Calico, Flannel).

### AWS EKS (Managed)
-   Create EKS Cluster using `eksctl` or Terraform.
-   Configure `kubectl` context: `aws eks update-kubeconfig ...`.

## 2. Storage (Persistent Volumes)

**KIND** uses `standard` storage class which maps to host path.
**Production** requires a real CSI driver.

-   **AWS EKS**: Install **EBS CSI Driver**.
    -   Change `storageClassName` in PVCs to `gp2` or `gp3`.
-   **Kubeadm**: Install a storage solution like **Longhorn**, **Rook/Ceph**, or **NFS**.

## 3. Ingress Controller

**KIND** uses a specific NGINX deployment for bare metal.
**Production** usually uses a LoadBalancer service.

-   **AWS EKS**:
    -   Install **AWS Load Balancer Controller**.
    -   Use `Ingress` with ALB annotations OR install NGINX Ingress Controller exposed via a Network Load Balancer (NLB).
-   **Kubeadm**:
    -   Use `MetalLB` to provide LoadBalancer IPs.
    -   Or use NodePort/HostNetwork (not recommended for prod).

## 4. Image Registry

**KIND** loads images directly from Docker Daemon.
**Production** needs a container registry (ECR, Docker Hub, Harbor).

1.  **Tag Images**:
    ```bash
    docker tag chat-app-backend:latest myregistry.com/chat-app-backend:v1
    ```
2.  **Push Images**:
    ```bash
    docker push myregistry.com/chat-app-backend:v1
    ```
3.  **Update Manifests**:
    -   Update `image:` fields in `backend.yaml` and `frontend.yaml` to point to the registry URL.
    -   Add `imagePullSecrets` if the registry is private.

## 5. Configuration & Secrets

-   **Secrets**: Do not store secrets (DB passwords, JWT keys) in plain YAML.
    -   Use **Sealed Secrets**, **External Secrets Operator** (with AWS Secrets Manager), or **HashiCorp Vault**.
-   **ConfigMaps**: Externalize non-sensitive config.

## 6. Monitoring & Logging

-   Install **Prometheus** and **Grafana** for metrics.
-   Install **EFK Stack** (Elasticsearch, Fluentd, Kibana) or **Loki** for logs.

## Summary Checklist

- [ ] Provision Cluster (EKS/Kubeadm)
- [ ] Configure Storage Class (EBS/Longhorn)
- [ ] Push Images to Registry (ECR/Docker Hub)
- [ ] Update Manifests (Image URLs, StorageClass)
- [ ] Setup Ingress (ALB/MetalLB)
- [ ] Secure Secrets
- [ ] Deploy!
