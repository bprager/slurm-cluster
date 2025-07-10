# Grafana Dashboard for Slurm Cluster

This directory contains Grafana dashboard configurations for monitoring the Slurm cluster.

## Setup Instructions

1. Access Grafana (assuming it's already installed on Ubuntu host)
2. Add Prometheus as a data source: <http://172.20.0.30:9090>
3. Import the provided dashboards

## Available Dashboards

- **slurm-cluster-overview.json**: Main cluster overview
- **node-metrics.json**: Individual node performance
- **job-metrics.json**: Job execution statistics

## Metrics Available

### Node Metrics

- CPU usage per node
- Memory usage per node
- Network I/O
- Disk I/O

### Slurm Metrics (when slurm-exporter is deployed)

- Job queue length
- Node states (idle/allocated/down)
- Job completion rates
- Resource utilization

### System Metrics

- Container resource usage
- Docker container states
- Network connectivity between nodes
