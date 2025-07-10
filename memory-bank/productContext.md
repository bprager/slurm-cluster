# Product Context: Experimental Slurm Cluster

## Why This Project Exists

### Problem Statement

Traditional HPC (High-Performance Computing) environments are typically homogeneous, requiring identical hardware across all nodes. This creates significant barriers for:

1. **Heterogeneous Hardware Environments**: Users with mixed hardware (Ubuntu workstations, MacBooks, NAS devices) cannot easily create unified computing clusters
2. **Learning and Experimentation**: Complex HPC setups are difficult to deploy for learning purposes
3. **Resource Utilization**: Underutilized hardware across different platforms cannot be pooled effectively
4. **Development and Testing**: No easy way to test HPC applications across different environments

### Market Gap

Existing solutions have limitations:
- **Traditional Slurm**: Requires homogeneous hardware and complex setup
- **Cloud HPC**: Expensive and not suitable for local development
- **Simple job schedulers**: Lack the power and features of enterprise HPC systems
- **Container-only solutions**: Don't provide the full HPC experience

## Problems This Project Solves

### Primary Problems

1. **Heterogeneous Hardware Integration**
   - **Problem**: Cannot use mixed hardware (Ubuntu, macOS, QNAP) in a single cluster
   - **Solution**: Containerized Slurm that works across different platforms
   - **Benefit**: Pool resources from all available hardware

2. **Complex HPC Setup**
   - **Problem**: Slurm installation and configuration is complex and error-prone
   - **Solution**: Docker-based deployment with automated setup
   - **Benefit**: One-command deployment and management

3. **Learning and Development Barriers**
   - **Problem**: HPC environments are difficult to set up for learning
   - **Solution**: Pre-configured templates and examples
   - **Benefit**: Easy experimentation with HPC concepts

4. **Resource Underutilization**
   - **Problem**: Hardware sits idle when not in use
   - **Solution**: Centralized job scheduling across all available resources
   - **Benefit**: Better resource utilization and throughput

### Secondary Problems

5. **Monitoring and Observability**
   - **Problem**: No visibility into cluster performance and job status
   - **Solution**: Integrated Prometheus/Grafana monitoring
   - **Benefit**: Real-time insights into cluster health and performance

6. **Job Management Complexity**
   - **Problem**: Manual job submission and management is error-prone
   - **Solution**: Job templates and management scripts
   - **Benefit**: Simplified job submission and monitoring

## How It Should Work

### User Experience Goals

#### For Cluster Administrators
1. **Simple Deployment**
   ```
   ./scripts/generate-munge-key.sh
   ./scripts/deploy.sh deploy
   ```

2. **Easy Management**
   ```
   ./scripts/health-check.sh
   ./scripts/performance-monitor.sh
   ```

3. **Multi-platform Support**
   - Ubuntu: Native Docker support
   - macOS: Docker Desktop integration
   - QNAP: ContainerStation compatibility

#### For End Users
1. **Simple Job Submission**
   ```
   ./scripts/job-manager.sh submit-ml
   ./scripts/job-manager.sh submit-test
   ```

2. **Job Monitoring**
   ```
   ./scripts/job-manager.sh status
   ./scripts/job-manager.sh logs
   ```

3. **Resource Access**
   - GPU computing on supported hardware
   - CPU computing across all nodes
   - Automatic resource allocation

### Technical Architecture

#### Core Components
1. **Slurm Controller** (`slurmctld`)
   - Central job scheduler
   - Resource management
   - Job accounting

2. **Slurm Workers** (`slurmd`)
   - Job execution nodes
   - Resource reporting
   - Platform-specific optimizations

3. **Database Backend** (`slurmdbd`)
   - Job history
   - Accounting data
   - Performance metrics

4. **Monitoring Stack**
   - Prometheus: Metrics collection
   - Grafana: Visualization
   - Node exporters: System metrics

#### Platform Integration
1. **Ubuntu Host**
   - Primary controller
   - GPU worker node
   - Full monitoring stack

2. **MacBook**
   - CPU worker node
   - Docker Desktop integration
   - Limited resource monitoring

3. **QNAP Devices**
   - Legacy hardware support
   - ContainerStation deployment
   - Basic resource reporting

### Expected Workflows

#### Cluster Setup
1. **Initial Deployment**
   - Generate authentication keys
   - Deploy controller and workers
   - Verify cluster health
   - Configure monitoring

2. **Adding New Nodes**
   - Copy configuration files
   - Start worker containers
   - Verify node registration
   - Monitor resource availability

#### Job Execution
1. **Job Submission**
   - User submits job via script or direct Slurm commands
   - Slurm scheduler allocates resources
   - Job executes on appropriate worker node
   - Results and logs are collected

2. **Resource Management**
   - Automatic resource detection
   - Dynamic job scheduling
   - Load balancing across nodes
   - GPU/CPU resource allocation

3. **Monitoring and Debugging**
   - Real-time job status
   - Performance metrics
   - Error logging and debugging
   - Resource utilization tracking

## Success Metrics

### Technical Metrics
- **Cluster Uptime**: >95% availability
- **Job Success Rate**: >90% successful execution
- **Resource Utilization**: >70% average utilization
- **Response Time**: <5 seconds for job submission

### User Experience Metrics
- **Deployment Time**: <10 minutes for initial setup
- **Job Submission**: <30 seconds from submission to execution
- **Monitoring Access**: Real-time dashboard availability
- **Error Recovery**: Automatic recovery from common failures

### Business Metrics
- **Resource Efficiency**: 3x improvement in hardware utilization
- **Development Speed**: 5x faster HPC application development
- **Learning Curve**: 50% reduction in time to productive HPC usage
- **Cost Savings**: Significant reduction in cloud HPC costs

## Current Reality vs. Vision

### Current State (Not Working)
- ❌ **Core functionality broken** - cgroup plugin issues
- ❌ **Container startup failures** - slurmd services not starting
- ❌ **No job execution** - Cluster cannot accept or run jobs
- ❌ **Limited monitoring** - Basic infrastructure only

### Target State
- ✅ **Functional cluster** - Jobs can be submitted and executed
- ✅ **Multi-platform support** - Ubuntu, macOS, and QNAP working
- ✅ **Comprehensive monitoring** - Full observability stack
- ✅ **Production-ready features** - Security, scalability, reliability

### Gap Analysis
1. **Critical Issues**: Fix cgroup plugin initialization failures
2. **Stability**: Implement working Docker configuration
3. **Features**: Add job templates and management tools
4. **Monitoring**: Complete Prometheus/Grafana integration
5. **Documentation**: Comprehensive user and admin guides

---

*This product context defines the vision, problems, and expected user experience for the Slurm Cluster project.* 