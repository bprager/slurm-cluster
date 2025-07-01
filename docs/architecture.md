# Experimental Slurm Cluster Architecture

## 1. Overview

This document describes the architecture for an experimental Slurm-based compute cluster using a heterogeneous mix of hardware: a powerful Ubuntu host, a MacBook, and two QNAP NAS devices. The cluster is containerized using Docker where possible, and integrates with Grafana for monitoring.

## 2. Objectives

* Centralized Slurm controller on Ubuntu
* Dockerized Slurm workers on MacBook and QNAP
* GPU support on Ubuntu worker
* Unified monitoring with Grafana and Prometheus

## 3. Components

### 3.1 Slurm Controller (Ubuntu Host)

* OS: Ubuntu 22.04
* Role: Runs `slurmctld` and optionally `slurmdbd`
* Configured with:

  * `slurm.conf`
  * `cgroup.conf`
  * `munge.key`

### 3.2 Slurm Workers

* **Ubuntu Host**

  * Runs native or Docker-based `slurmd`
  * GPU support enabled via `--gpus all`

* **MacBook**

  * Runs Docker Desktop
  * CPU-only `slurmd` container
  * Uses override config `docker-compose.override.mac.yml`

* **QNAP Devices (2x)**

  * Runs `slurmd` in Docker via ContainerStation or CLI
  * Uses `docker-compose.override.qnap.yml`

### 3.3 Monitoring Stack

* Prometheus: Gathers metrics from Slurm and nodes
* Grafana: Visualizes metrics (already installed on Ubuntu)
* Exporters:

  * `node_exporter`
  * `slurm_exporter`
  * `cadvisor` (optional)

## 4. Networking and Authentication

* Shared network: `slurm-net` (Docker bridge)
* All nodes use same `munge.key` for auth
* Slurm config shared via bind mount: `./shared/`

## 5. Deployment

### 5.1 Shared Configuration Directory

```
shared/
├── slurm.conf
├── cgroup.conf
└── munge.key
```

### 5.2 Docker Compose Files

* `docker-compose.yml`: Base definition
* `docker-compose.override.mac.yml`: MacBook worker
* `docker-compose.override.qnap.yml`: QNAP workers

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
  component "slurmd (Docker)"
}

node "QNAP #1" {
  component "slurmd (Docker)"
}

node "QNAP #2" {
  component "slurmd (Docker)"
}

Ubuntu Host --> MacBook : Docker Network
Ubuntu Host --> QNAP #1 : Docker Network
Ubuntu Host --> QNAP #2 : Docker Network
Ubuntu Host --> Prometheus : Metrics
Prometheus --> Grafana : Data Source
@enduml
```

## 7. Future Extensions

* Integrate `slurmdbd` and MariaDB for accounting
* Add GPU workers on other nodes (if supported)
* Central NFS job directory shared from QNAP
* Advanced scheduling and SLURM job accounting

