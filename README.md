# Experimental Slurm Cluster

An experimental Slurm-based compute cluster using heterogeneous hardware: Ubuntu host, MacBook, and QNAP devices. The cluster is containerized using Docker where possible and includes comprehensive monitoring.

## Quick Start

1. **Generate authentication keys:**

   ```bash
   ./scripts/generate-munge-key.sh
   ```

2. **Deploy the cluster:**

   ```bash
   ./scripts/deploy.sh deploy
   ```

3. **Test the cluster:**

   ```bash
   ./scripts/create-test-jobs.sh
   docker compose exec slurmctld sbatch /shared/test-jobs/cpu-test.sh
   ```

## Documentation

- **[Architecture](docs/architecture.md)** - Detailed architecture design
- **[Implementation Plan](docs/implementation-plan.md)** - Step-by-step deployment guide

## Project Structure

```
SlurmCluster/
├── docker-compose.yml              # Main container definitions
├── docker-compose.override.*.yml   # Platform-specific overrides
├── docker/                         # Docker build files
├── shared/                         # Shared Slurm configuration
├── scripts/                        # Deployment and management scripts
├── monitoring/                     # Prometheus configuration
├── legacy-qnap/                   # Legacy QNAP installation scripts
└── docs/                          # Documentation
```

## 2. Objectives

- Centralized Slurm controller on Ubuntu
- Dockerized Slurm workers on MacBook and QNAP
- GPU support on Ubuntu worker
- Unified monitoring with Grafana and Prometheus

## 3. Components

### 3.1 Slurm Controller (Ubuntu Host)

- OS: Ubuntu 22.04
- Role: Runs `slurmctld` and optionally `slurmdbd`
- Configured with:

  - `slurm.conf`
  - `cgroup.conf`
  - `munge.key`

### 3.2 Slurm Workers

- **Ubuntu Host**

  - Runs native or Docker-based `slurmd`
  - GPU support enabled via `--gpus all`

- **MacBook**

  - Runs Docker Desktop
  - CPU-only `slurmd` container
  - Uses override config `docker-compose.override.mac.yml`

- **QNAP Devices (2x)**

  - Runs `slurmd` in Docker via ContainerStation or CLI
  - Uses `docker-compose.override.qnap.yml`

### 3.3 Monitoring Stack

- Prometheus: Gathers metrics from Slurm and nodes
- Grafana: Visualizes metrics (already installed on Ubuntu)
- Exporters:

  - `node_exporter`
  - `slurm_exporter`
  - `cadvisor` (optional)

## 4. Networking and Authentication

- Shared network: `slurm-net` (Docker bridge)
- All nodes use same `munge.key` for auth
- Slurm config shared via bind mount: `./shared/`

## 5. Deployment

### 5.1 Shared Configuration Directory

```
shared/
├── slurm.conf
├── cgroup.conf
└── munge.key
```

### 5.2 Docker Compose Files

- `docker-compose.yml`: Base definition
- `docker-compose.override.mac.yml`: MacBook worker
- `docker-compose.override.qnap.yml`: QNAP workers

### 5.3 Commands

```bash
# Start controller and Ubuntu GPU worker
cd slurm-docker-lab
docker compose up -d

# On MacBook
docker compose -f docker-compose.yml -f docker-compose.override.mac.yml up -d

# On QNAP
docker compose -f docker-compose.yml -f docker-compose.override.qnap.yml up -d
```

## 6. PlantUML Architecture Diagram

```plantuml
@startuml
node "Ubuntu Host" {
  component "slurmctld"
  component "slurmd (GPU)"
  database "slurmdbd (optional)"
  component "Prometheus"
  component "Grafana"
}

node "MacBook" {
  compon
```
