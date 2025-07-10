# Technical Context: Slurm Cluster Technologies

## Technology Stack

### Core Technologies

#### 1. Slurm Workload Manager
- **Version**: 22.05.9 / 23.11.7 (latest stable)
- **Purpose**: Job scheduling and resource management
- **Components**:
  - `slurmctld`: Central controller daemon
  - `slurmd`: Node daemon for job execution
  - `slurmdbd`: Database daemon for accounting
- **Configuration**: `slurm.conf`, `cgroup.conf`, `slurmdbd.conf`

#### 2. Docker & Docker Compose
- **Version**: Latest stable
- **Purpose**: Containerization and orchestration
- **Components**:
  - Docker Engine: Container runtime
  - Docker Compose: Multi-service orchestration
  - Platform-specific overrides
- **Benefits**: Consistent environment across heterogeneous hardware

#### 3. MySQL Database
- **Version**: 8.0
- **Purpose**: Job accounting and history storage
- **Configuration**: `mysql-init.sql` for database setup
- **Integration**: Connected to `slurmdbd` for accounting data

### Monitoring Stack

#### 1. Prometheus
- **Version**: Latest stable
- **Purpose**: Metrics collection and storage
- **Configuration**: `monitoring/prometheus.yml`
- **Targets**: Node exporter, Slurm exporter, system metrics

#### 2. Grafana
- **Version**: Latest stable
- **Purpose**: Metrics visualization and dashboards
- **Configuration**: `monitoring/grafana-dashboard.json`
- **Features**: Real-time dashboards, alerting

#### 3. Exporters
- **Node Exporter**: System metrics collection
- **Slurm Exporter**: Job and queue metrics
- **Custom Metrics**: Application-specific monitoring

### Authentication & Security

#### 1. Munge Authentication
- **Purpose**: Inter-node authentication
- **Implementation**: Shared `munge.key` across all nodes
- **Security**: 600 permissions, secure key distribution

#### 2. Network Security
- **Docker Networks**: Isolated `slurm-net` for cluster communication
- **Port Management**: Controlled port exposure for services
- **Internal Communication**: Service discovery via Docker DNS

## Development Environment

### Host System Requirements

#### Ubuntu Host (Primary)
- **OS**: Ubuntu 22.04 LTS
- **Docker**: Docker Engine with Compose
- **GPU**: NVIDIA GPU with Container Toolkit (optional)
- **Resources**: Minimum 4GB RAM, 20GB storage
- **Network**: Stable internet connection for image pulls

#### MacBook (Worker)
- **OS**: macOS with Docker Desktop
- **Docker**: Docker Desktop for Mac
- **Resources**: Minimum 2GB RAM allocated to Docker
- **Network**: Connection to Ubuntu host

#### QNAP Devices (Workers)
- **OS**: QNAP QTS with ContainerStation
- **Docker**: ContainerStation or Docker CLI
- **Resources**: Varies by device model
- **Network**: Connection to Ubuntu host

### Development Tools

#### 1. Version Control
- **Git**: Source code management
- **Repository**: Local development with remote backup
- **Branching**: Feature-based development workflow

#### 2. Build Tools
- **Docker Build**: Multi-stage builds for Slurm images
- **Docker Compose**: Service orchestration
- **Shell Scripts**: Automation and deployment

#### 3. Monitoring & Debugging
- **Docker Logs**: Container-level logging
- **Prometheus**: Metrics collection and alerting
- **Grafana**: Visualization and dashboards

## Technical Constraints

### 1. Docker Limitations

#### Cgroup Compatibility Issues
- **Problem**: Modern Slurm versions deeply integrated with cgroup
- **Impact**: Container startup failures due to dbus/systemd requirements
- **Current Workaround**: Disable cgroup functionality entirely
- **Trade-off**: No resource isolation, limited security

#### Systemd Dependency
- **Problem**: Slurm cgroup plugins require systemd
- **Impact**: Cannot use standard Docker containers
- **Alternatives**: 
  - Systemd-enabled containers (complex)
  - Older Slurm versions (limited features)
  - Different containerization (LXC/LXD)

### 2. Platform Heterogeneity

#### Hardware Differences
- **Ubuntu**: Full Linux environment, GPU support
- **macOS**: Limited container capabilities, no GPU passthrough
- **QNAP**: ARM architecture, limited resources

#### Network Constraints
- **Latency**: Inter-node communication delays
- **Bandwidth**: Limited by network infrastructure
- **Reliability**: Dependent on network stability

### 3. Resource Limitations

#### Memory Constraints
- **Container Memory**: Limited by host resources
- **Slurm Memory**: Job memory limits not enforced
- **Monitoring Overhead**: Prometheus/Grafana resource usage

#### CPU Constraints
- **Container CPU**: Limited by host allocation
- **Job Scheduling**: No CPU limits enforcement
- **Performance Impact**: Docker layer overhead

### 4. Security Constraints

#### Container Security
- **Privileged Access**: Some features require privileged containers
- **Network Security**: Limited isolation in Docker networks
- **Resource Isolation**: No cgroup-based isolation

#### Authentication Limitations
- **Munge Key**: Shared secret across all nodes
- **No SSL/TLS**: Internal communication not encrypted
- **No RBAC**: No role-based access control

## Dependencies

### 1. Runtime Dependencies

#### Slurm Dependencies
```bash
# Core Slurm packages
slurm
slurm-devel
slurm-perlapi
slurm-pam_slurm
slurm-slurmdbd
slurm-slurmctld
slurm-slurmd
```

#### System Dependencies
```bash
# Ubuntu packages
build-essential
libmunge-dev
libssl-dev
libmysqlclient-dev
```

#### Docker Dependencies
```bash
# Docker requirements
docker-ce
docker-compose-plugin
nvidia-container-toolkit (optional)
```

### 2. Build Dependencies

#### Slurm Build Requirements
```bash
# Build tools
gcc
make
autoconf
automake
libtool
pkg-config
```

#### Development Tools
```bash
# Development utilities
git
curl
wget
vim
```

### 3. Monitoring Dependencies

#### Prometheus Stack
```bash
# Prometheus components
prometheus
node_exporter
slurm_exporter
```

#### Grafana Stack
```bash
# Grafana components
grafana
grafana-dashboards
```

### 4. Database Dependencies

#### MySQL Requirements
```bash
# MySQL components
mysql-server
mysql-client
libmysqlclient-dev
```

## Configuration Management

### 1. Slurm Configuration

#### Core Configuration Files
- **`slurm.conf`**: Main cluster configuration
- **`cgroup.conf`**: Resource management (currently disabled)
- **`slurmdbd.conf`**: Database configuration
- **`munge.key`**: Authentication key

#### Configuration Strategy
- **Bind-mounted**: Runtime configuration updates
- **Version-controlled**: Configuration in Git repository
- **Platform-specific**: Override files for different platforms

### 2. Docker Configuration

#### Compose Files
- **`docker-compose.yml`**: Base service definitions
- **`docker-compose.override.mac.yml`**: macOS-specific overrides
- **`docker-compose.override.qnap.yml`**: QNAP-specific overrides

#### Container Configuration
- **Multi-stage builds**: Optimized image sizes
- **Health checks**: Service availability monitoring
- **Resource limits**: Container-level constraints

### 3. Monitoring Configuration

#### Prometheus Configuration
- **`prometheus.yml`**: Metrics collection targets
- **Scrape intervals**: 15-second default
- **Retention**: 15-day default

#### Grafana Configuration
- **Dashboards**: Pre-configured Slurm dashboards
- **Data sources**: Prometheus integration
- **Alerting**: Basic alerting rules

## Performance Considerations

### 1. Resource Optimization

#### Container Optimization
- **Multi-stage builds**: Reduced image sizes
- **Layer caching**: Faster rebuilds
- **Resource limits**: Prevent resource exhaustion

#### Slurm Optimization
- **Partition configuration**: Efficient resource allocation
- **Job limits**: Prevent job monopolization
- **Accounting**: Minimal overhead

### 2. Network Optimization

#### Docker Network
- **Bridge network**: Internal cluster communication
- **Service discovery**: Automatic DNS resolution
- **Port management**: Controlled external access

#### Monitoring Overhead
- **Scrape intervals**: Balance between detail and overhead
- **Metrics filtering**: Collect only necessary metrics
- **Storage optimization**: Efficient time-series storage

### 3. Storage Optimization

#### Volume Management
- **Bind mounts**: Configuration and data persistence
- **Named volumes**: Database and monitoring data
- **Tmpfs**: Temporary data storage

#### Log Management
- **Log rotation**: Prevent disk space issues
- **Log levels**: Appropriate verbosity
- **Log aggregation**: Centralized logging

## Deployment Considerations

### 1. Environment-Specific Configurations

#### Ubuntu Deployment
- **Native Docker**: Full feature support
- **GPU passthrough**: NVIDIA Container Toolkit
- **Full monitoring**: Complete Prometheus/Grafana stack

#### macOS Deployment
- **Docker Desktop**: Limited container capabilities
- **CPU-only**: No GPU support
- **Basic monitoring**: Node exporter only

#### QNAP Deployment
- **ContainerStation**: Web-based Docker management
- **ARM architecture**: Limited image compatibility
- **Resource constraints**: Limited CPU/memory

### 2. Scaling Considerations

#### Horizontal Scaling
- **Worker nodes**: Easy addition of new nodes
- **Load balancing**: Automatic job distribution
- **Resource discovery**: Dynamic resource detection

#### Vertical Scaling
- **Resource limits**: Container-level constraints
- **Performance tuning**: Slurm parameter optimization
- **Monitoring scaling**: Metrics collection overhead

---

*This technical context document captures the technology stack, development environment, constraints, and dependencies that define the Slurm Cluster implementation.* 