# Voyager

A cloud infrastructure project deploying a full-stack web application to Google Cloud Platform using modern DevOps
tooling. Built as a learning project to get hands-on experience with the kind of infrastructure that real production
environments use. The free credit offering from GCP was used for deployment.

The app itself is simple on purpose: a React frontend, Go backend, and PostgreSQL database where users can register and
log in. The point is not the app. The point is everything around it.

---
## What this project covers

The infrastructure is split across three GCP projects: one shared environment for things like the container registry and
a self-hosted GitLab instance, and separate test and prod environments each with their own network, Kubernetes cluster,
and database. Both environments are brought up with Terraform and managed from a single monorepo.

Code changes flow through a GitLab CI pipeline that runs tests, builds Docker images, packages Helm charts, and deploys
to test automatically. Prod requires a manual approval step. Once deployed, ArgoCD takes over and keeps the cluster in
sync with whatever is in the repo. If something drifts, ArgoCD gets it back in sync.

Secrets never touch the repo or the CI environment as plaintext. Terraform generates database passwords, stores them in
GCP Secret Manager, and a External Secrets tool pulls them into Kubernetes at runtime. The database itself has no
public IP and is only reachable from inside the VPC.

Each environment also runs a monitoring stack: Prometheus scrapes metrics, Loki collects logs via Grafana Alloy, and
Grafana puts it all on dashboards. Alerts go to Discord. A WireGuard VPN on a small GCE instance (which is in the free
tier and allows me to avoid GCP VPN fees) gives private access to
internal services like Grafana without exposing them to the internet.

DNS records are managed automatically by External DNS, which watches for Kubernetes ingress resources and creates the
corresponding Cloud DNS entries. TLS is handled by GCP managed certificates.

---

## Things I ran into

Setting up Workload Identity was one of the trickier parts. In GCP, the recommended way for a Kubernetes pod to
authenticate to GCP services (like Secret Manager or Cloud Storage) is through Workload Identity, which links a
Kubernetes service account to a GCP service account without needing to mount any key files. This proved to be one of the
more trickier parts of earlier iterations.

The app-of-apps pattern in ArgoCD made sense on paper but the sync ordering bit me pretty hard early on. External
Secrets has to be fully running before any app that pulls secrets from it, otherwise those apps just fail on startup and
ArgoCD keeps retrying them.

The private GKE cluster setup caused some early issues too. Private nodes have no public IPs, so pulling images or
reaching external services requires a Cloud NAT gateway. Forgetting to provision that correctly meant pods would get
stuck waiting for images that could never be pulled.

Running a self-managed GitLab instance on a GCE instance in the shared project ended up being more useful than I
expected. Having the runner sitting inside the same network as everything else meant it could talk directly to the
cluster and the artifact registry without jumping through (too many) hoops. The GitLab CI format also just clicked for
me faster than GitHub Actions did. Although future updates have to be handled by me now too, which it already started 
pinging me about every time I opened it.

---
## Potential improvements
- The test and prod Terraform is basically copy-pasted, should be a shared module in a real setup with the config seperating them
- Single node WireGuard VPN is a single point of failure for private access
- The GitLab instance is a single GCE instance with no backup or HA, if it goes down the whole CI pipeline is dead

---
![GitopsCartographer_diagram1.drawio.svg](images/GitopsCartographer_diagram1.drawio.svg)

---
## Stack

| Area                   | Tool                                           |
|------------------------|------------------------------------------------|
| Cloud                  | Google Cloud Platform                          |
| Infrastructure as code | Terraform                                      |
| Kubernetes             | GKE Standard                                   |
| GitOps                 | ArgoCD                                         |
| CI/CD                  | GitLab CI                                      |
| Container registry     | GCP Artifact Registry                          |
| Secrets                | GCP Secret Manager + External Secrets Operator |
| DNS                    | GCP Cloud DNS + External DNS                   |
| TLS                    | GCP Managed Certificates                       |
| Logs                   | Loki + Grafana Alloy                           |
| Metrics                | Prometheus                                     |
| Dashboards             | Grafana                                        |
| Database               | Cloud SQL PostgreSQL 15                        |
| VPN                    | WireGuard on GCE                               |
| Backend                | Go (Fiber)                                     |
| Frontend               | React                                          |

---

## Repository layout

```
argocd/        ArgoCD app-of-apps definitions for test and prod environments
terraform/     Infrastructure as code (shared, test, prod)
sample-app/    Frontend and backend source code with Helm charts
ci/            GitLab CI pipeline configuration and CI Docker image
images/        Architecture diagrams
```

---

## Related

I also did a separate cost analysis [here](https://github.com/drextrime/Cloud-cartographer), where I compared what this setup would cost on AWS versus GCP, looking at equivalent
services on both providers and where the pricing differences actually come from. 