# Project Brief: Experimental Slurm Cluster

## Project Overview

This is an experimental Slurm-based compute cluster designed to run on heterogeneous hardware including Ubuntu hosts, MacBooks, and QNAP devices. The project aims to create a containerized, multi-platform HPC environment with comprehensive monitoring and management capabilities.

## Core Requirements

### Primary Goals
1. **Heterogeneous Computing Environment**: Support multiple hardware platforms (Ubuntu, macOS, QNAP) in a unified Slurm cluster
2. **Containerized Deployment**: Use Docker for consistent deployment across different platforms
3. **GPU Computing Support**: Enable GPU acceleration on supported hardware
4. **Comprehensive Monitoring**: Integrate Prometheus and Grafana for observability
5. **Production-Ready Features**: Job templates, health checks, and management tools

### Technical Requirements
- **Slurm Version**: 22.05.9 or 23.11.7 (latest stable)
- **Containerization**: Docker Compose for orchestration
- **Authentication**: Munge key-based authentication across all nodes
- **Database**: MySQL for job accounting and history
- **Monitoring**: Prometheus metrics collection and Grafana visualization
- **Multi-platform Support**: Ubuntu, macOS, and QNAP deployment strategies

### Current Status
- **Version**: 0.1.1 (patch version)
- **Status**: NOT WORKING - Critical cgroup plugin issues preventing proper initialization
- **Main Issue**: slurmd-ubuntu service repeatedly restarting due to cgroup/dbus/systemd failures

## Project Scope

### What's Included
- ✅ Multi-platform Slurm cluster architecture
- ✅ Docker-based containerization
- ✅ GPU support configuration
- ✅ Monitoring stack (Prometheus/Grafana)
- ✅ Job templates and management scripts
- ✅ Comprehensive documentation
- ✅ Legacy hardware support strategies

### What's NOT Working
- ❌ **Core Slurm functionality** - cgroup plugin initialization failures
- ❌ **Container startup** - slurmd services failing to start properly
- ❌ **Resource isolation** - cgroup-based resource limits not functional
- ❌ **Production deployment** - Current state unsuitable for production use

### Limitations
- **No resource isolation** - Jobs can access all resources without limits
- **No process containment** - Limited security isolation
- **Development/Testing only** - Not suitable for production environments
- **Cgroup functionality disabled** - Accepting limitations for Docker compatibility

## Success Criteria

### Immediate (Critical)
1. **Fix cgroup plugin issues** - Resolve container startup failures
2. **Achieve basic functionality** - Get Slurm cluster to start and accept jobs
3. **Implement working configuration** - Create stable Docker-based deployment

### Short-term
1. **Functional cluster** - Jobs can be submitted and executed
2. **Basic monitoring** - Prometheus metrics collection working
3. **Multi-platform deployment** - Ubuntu, macOS, and QNAP support

### Long-term
1. **Production readiness** - Security, scalability, and reliability
2. **Performance optimization** - Resource utilization and job scheduling
3. **Complete monitoring** - Full observability and alerting
4. **Comprehensive documentation** - User and administrator guides

## Project Constraints

### Technical Constraints
- **Docker limitations** - No systemd support in standard containers
- **Cgroup compatibility** - Modern Slurm versions deeply integrated with cgroup
- **Platform differences** - Ubuntu, macOS, and QNAP have different capabilities
- **Resource isolation** - Limited without proper cgroup support

### Operational Constraints
- **Development environment** - Not intended for production use
- **Learning/testing focus** - Experimental nature of the project
- **Heterogeneous hardware** - Complex multi-platform deployment
- **Containerization overhead** - Performance impact of Docker layers

## Key Stakeholders

### Primary User
- **Bernd** - Project owner and primary developer
- **Use case**: Experimental HPC environment for learning and testing
- **Requirements**: Multi-platform support, GPU computing, monitoring

### Target Environment
- **Ubuntu Host**: Primary controller and GPU worker
- **MacBook**: CPU-only worker node
- **QNAP Devices**: Legacy hardware workers
- **Development/Testing**: Non-production use cases

## Project Timeline

### Current Phase: Critical Issue Resolution
- **Focus**: Fix cgroup plugin initialization failures
- **Priority**: Get basic cluster functionality working
- **Timeline**: Immediate attention required

### Next Phase: Stability and Features
- **Focus**: Implement working configuration and basic features
- **Priority**: Functional cluster with monitoring
- **Timeline**: Short-term (weeks)

### Future Phase: Production Readiness
- **Focus**: Security, performance, and scalability
- **Priority**: Production-ready deployment
- **Timeline**: Long-term (months)

---

*This project brief serves as the foundation for all memory bank files and defines the core scope, requirements, and success criteria for the Slurm Cluster implementation.* 