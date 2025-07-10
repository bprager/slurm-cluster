# Slurm Cluster Quick Reference

## Common Commands

### Cluster Management

```bash
# Deploy full cluster
./scripts/deploy.sh deploy

# Check cluster status
./scripts/deploy.sh status

# Stop all services
./scripts/deploy.sh stop

# View logs
docker compose logs slurmctld
docker compose logs slurmd-ubuntu
```

### Job Submission

```bash
# Submit a simple job
docker compose exec slurmctld sbatch /shared/test-jobs/cpu-test.sh

# Submit to specific partition
docker compose exec slurmctld sbatch --partition=gpu /shared/test-jobs/gpu-test.sh

# Submit array job
docker compose exec slurmctld sbatch /shared/test-jobs/array-test.sh

# Interactive job
docker compose exec slurmctld srun --pty bash
```

### Job Monitoring

```bash
# View job queue
docker compose exec slurmctld squeue

# View job details
docker compose exec slurmctld scontrol show job JOBID

# View job history
docker compose exec slurmctld sacct

# Cancel job
docker compose exec slurmctld scancel JOBID
```

### Cluster Information

```bash
# View nodes
docker compose exec slurmctld sinfo

# View node details
docker compose exec slurmctld scontrol show node

# View partitions
docker compose exec slurmctld sinfo -s

# View cluster configuration
docker compose exec slurmctld scontrol show config
```

## Advanced Tools

### Job Management

```bash
# Easy job submission interface
./scripts/job-manager.sh submit-test
./scripts/job-manager.sh submit-ml MODEL=resnet50 EPOCHS=20
./scripts/job-manager.sh submit-pipeline INPUT_DIR=/data/raw
./scripts/job-manager.sh submit-hpc SIMULATION_SIZE=50000

# Job status and logs
./scripts/job-manager.sh status
./scripts/job-manager.sh logs JOBID
./scripts/job-manager.sh cancel JOBID
```

### Health Monitoring

```bash
# Comprehensive health check
./scripts/health-check.sh

# Performance monitoring
./scripts/performance-monitor.sh monitor    # Standard 5-min
./scripts/performance-monitor.sh quick      # Quick 1-min
./scripts/performance-monitor.sh extended   # Extended 15-min
```

### Job Templates

Available in `./job-templates/`:

- **ml-training.sh**: Machine learning training with GPU support
- **data-pipeline.sh**: Parallel data processing pipeline
- **hpc-simulation.sh**: Multi-node HPC simulation

## Service URLs

- **Prometheus**: <http://localhost:9090>
- **Node Exporter**: <http://localhost:9100>
- **Grafana**: <http://localhost:3000> (if configured)

## File Locations

- **Configuration**: `./shared/`
- **Logs**: `./logs/`
- **Test Jobs**: `./test-jobs/`
- **Scripts**: `./scripts/`

## Troubleshooting

### Common Issues

1. **Services won't start**

   ```bash
   docker compose logs <service-name>
   ```

2. **Nodes in down state**

   ```bash
   docker compose exec slurmctld scontrol update NodeName=<node> State=IDLE
   ```

3. **Authentication errors**
   - Check munge.key permissions (400)
   - Restart munge service

4. **No GPU detected**
   - Verify NVIDIA Container Toolkit installation
   - Check GPU configuration in slurm.conf

### Log Levels

- **Debug**: Change `DebugLevel` in configuration files
- **Container logs**: `docker compose logs -f <service>`
- **Slurm logs**: Check `./logs/` directory

## Configuration Files

- **slurm.conf**: Main Slurm configuration
- **slurmdbd.conf**: Database daemon configuration
- **cgroup.conf**: Resource management
- **munge.key**: Authentication key (must be identical on all nodes)

## Node Types

- **ubuntu-gpu**: GPU-enabled worker on Ubuntu host
- **macbook-cpu**: CPU-only worker on MacBook
- **qnap-modern**: CPU-only worker on modern QNAP
- **qnap-legacy**: Optional worker on legacy QNAP (manual setup)

## Partitions

- **gpu**: GPU nodes (ubuntu-gpu)
- **cpu**: CPU-only nodes (macbook-cpu, qnap-modern, qnap-legacy)
- **all**: All available nodes
