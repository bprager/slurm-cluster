# Slurm Cluster Implementation Plan

Based on the architecture document, this implementation plan provides a step-by-step guide to deploy the experimental Slurm cluster.

## Implementation Overview

The implementation creates a heterogeneous Slurm cluster with the following components:

### Infrastructure Components

- **Slurm Controller** (Ubuntu host) - Manages job scheduling and cluster state
- **Slurm Database** (MySQL) - Stores accounting and job history
- **GPU Worker Node** (Ubuntu host) - Executes GPU-accelerated jobs
- **CPU Worker Nodes** (MacBook, modern QNAP) - Execute CPU-only jobs
- **Legacy Worker** (legacy QNAP) - Optional worker with manual setup
- **Monitoring Stack** (Prometheus + Grafana) - Cluster monitoring and metrics

### Key Features

- Containerized deployment using Docker Compose
- Cross-platform compatibility (Ubuntu, macOS, QNAP)
- GPU support for accelerated computing
- Centralized authentication via Munge
- Comprehensive monitoring and logging
- Flexible deployment options for legacy hardware

## Deployment Steps

### Step 1: Prerequisites

1. **Ubuntu Host Setup**

   ```bash
   # Install Docker and Docker Compose
   sudo apt update
   sudo apt install docker.io docker-compose-plugin
   sudo usermod -aG docker $USER

   # For GPU support, install NVIDIA Container Toolkit
   distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
   curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
   curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
   sudo apt update && sudo apt install nvidia-docker2
   sudo systemctl restart docker
   ```

2. **MacBook Setup**

   ```bash
   # Install Docker Desktop for Mac
   # Download from: https://docs.docker.com/desktop/mac/install/

   # Ensure SSH access is configured between Ubuntu host and MacBook
   ssh-copy-id user@macbook-ip
   ```

3. **Modern QNAP Setup**
   - Enable SSH service in QNAP Control Panel
   - Install Container Station from App Center
   - Configure SSH key access from Ubuntu host

### Step 2: Generate Security Keys

```bash
cd /home/bernd/Projects/SlurmCluster
./scripts/generate-munge-key.sh
```

### Step 3: Deploy the Cluster

```bash
# Full deployment (all components)
./scripts/deploy.sh deploy

# Or deploy components individually:
./scripts/deploy.sh controller    # Controller + Ubuntu worker
./scripts/deploy.sh macbook       # MacBook worker
./scripts/deploy.sh qnap-modern   # Modern QNAP worker
./scripts/deploy.sh qnap-legacy   # Legacy QNAP (manual steps)
```

### Step 4: Verify Deployment

```bash
# Check cluster status
./scripts/deploy.sh status

# Create and submit test jobs
./scripts/create-test-jobs.sh
docker compose exec slurmctld sbatch /shared/test-jobs/cpu-test.sh
docker compose exec slurmctld squeue
```

### Step 5: Legacy QNAP Setup (Manual)

For the legacy QNAP device, choose one of these methods:

#### Option A: Entware Installation

```bash
# SSH to legacy QNAP
ssh admin@legacy-qnap-ip
cd /share/slurm-legacy
./install-slurm-entware.sh
```

#### Option B: Alpine Chroot

```bash
# SSH to legacy QNAP
ssh admin@legacy-qnap-ip
cd /share/slurm-legacy
./setup-alpine-chroot.sh
./enter-chroot.sh
# Inside chroot:
/install-slurm.sh
```

## Configuration Details

### Network Configuration

- Docker network: `172.20.0.0/16`
- Controller IP: `172.20.0.10`
- Workers: `172.20.0.20-29`
- Monitoring: `172.20.0.30-39`

### Service Ports

- Slurm Controller: `6817`
- Slurm Database: `6819`
- Prometheus: `9090`
- Node Exporters: `9100`

### File Structure

```
SlurmCluster/
├── docker-compose.yml              # Main container definitions
├── docker-compose.override.*.yml   # Platform-specific overrides
├── docker/                         # Docker build files
│   ├── Dockerfile.slurm
│   ├── entrypoint.sh
│   └── mysql-init.sql
├── shared/                         # Shared configuration
│   ├── slurm.conf
│   ├── slurmdbd.conf
│   ├── cgroup.conf
│   └── munge.key
├── scripts/                        # Deployment scripts
│   ├── deploy.sh
│   ├── generate-munge-key.sh
│   └── create-test-jobs.sh
├── monitoring/                     # Monitoring configuration
│   └── prometheus.yml
├── legacy-qnap/                   # Legacy QNAP installation
│   ├── install-slurm-entware.sh
│   └── setup-alpine-chroot.sh
└── test-jobs/                     # Test job scripts
    ├── cpu-test.sh
    ├── gpu-test.sh
    ├── multi-node-test.sh
    └── array-test.sh
```

## Monitoring Setup

### Prometheus Configuration

- Monitors all cluster nodes via node exporters
- Collects Slurm-specific metrics (when slurm-exporter is added)
- Stores metrics with 200-hour retention

### Grafana Dashboards

- Import the provided dashboard configurations
- Connect to Prometheus data source at `http://172.20.0.30:9090`
- View cluster overview, node metrics, and job statistics

## Troubleshooting

### Common Issues

1. **Munge Authentication Failures**
   - Ensure `munge.key` is identical across all nodes
   - Check file permissions (400) and ownership (munge:munge)

2. **Node Connection Issues**
   - Verify network connectivity between controller and workers
   - Check firewall settings and port accessibility

3. **GPU Not Detected**
   - Ensure NVIDIA Container Toolkit is installed
   - Verify GPU resource configuration in `slurm.conf`

4. **Legacy QNAP Issues**
   - For build failures, ensure all dependencies are installed
   - Consider using the Alpine chroot method for better isolation

### Log Locations

- Container logs: `docker compose logs <service>`
- Slurm logs: `./logs/` directory
- System logs: Standard Docker logging

## Next Steps

1. **Add Slurm Exporter** for detailed job metrics
2. **Configure Job Arrays** for parallel workloads
3. **Set up NFS** for shared job storage
4. **Implement Job Dependencies** for complex workflows
5. **Add More Worker Nodes** as hardware becomes available

## Security Considerations

- Change default MySQL passwords in production
- Use proper SSL/TLS certificates for external access
- Implement network segmentation for production deployments
- Regular security updates for all container images
- Monitor access logs and implement intrusion detection

This implementation provides a solid foundation for experimenting with Slurm in a heterogeneous environment while maintaining flexibility for future enhancements.
