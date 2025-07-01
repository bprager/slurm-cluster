# Experimental Slurm Cluster Architecture

> 📁 This document is located in the `docs/` subdirectory as part of the overall project structure.

## 1. Overview

This document describes the architecture for an experimental Slurm-based compute cluster using a heterogeneous mix of hardware: a powerful Ubuntu host, a MacBook, and two QNAP NAS devices (one modern, one legacy). The cluster is containerized using Docker where possible, and integrates with Grafana for monitoring.

## 2. Objectives

* Centralized Slurm controller on Ubuntu
* Dockerized Slurm workers on MacBook and modern QNAP
* Real or simulated `slurmd` on legacy QNAP
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

* **QNAP #1 (QTS 5.1.0.60)**

  * Runs `slurmd` in Docker via ContainerStation
  * Uses `docker-compose.override.qnap.yml`

* **QNAP #2 (QTS 3.4.6, Legacy)**

  * Does not support Docker or ContainerStation
  * Possible approaches:

    1. **Install Entware and Build Slurm Natively**

       * Install Entware and dependencies
       * Build Slurm from source with `munge`
    2. **Use Lightweight Chroot**

       * Deploy Alpine or Debian in a chroot
       * Run `slurmd` inside the environment
    3. **Cross-Compile Static `slurmd` Binary**

       * Build statically linked Slurm binary on another machine
       * Deploy and run manually
    4. **QEMU-Based Emulation** (least recommended)

       * Run a Linux VM in QEMU
    5. **Fallback Role**

       * Serve as NFS job storage or logging node
       * Simulated node in `slurm.conf` (no `slurmd`)

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
* `docker-compose.override.qnap.yml`: QNAP (modern) worker

### 5.3 Commands

```bash
# Start controller and Ubuntu GPU worker
cd slurm-docker-lab
docker compose up -d

# On MacBook
docker compose -f docker-compose.yml -f docker-compose.override.mac.yml up -d

# On QNAP #1 (modern)
docker compose -f docker-compose.yml -f docker-compose.ove
```

