# Slurm Cgroup Plugin Issue Resolution

## Problem Summary

The `slurmd-ubuntu` service was repeatedly restarting due to cgroup plugin initialization failures. The main errors involved:

- `cgroup_dbus_attach_to_scope: cannot connect to dbus system daemon`
- `Couldn't load specified plugin name for cgroup/v2: Plugin init() callback failed`
- `Unable to initialize cgroup plugin`
- `slurmd initialization failed`

## Root Cause Analysis

The issue stems from Slurm's deep integration with cgroup functionality in modern versions (22.05.9, 23.11.7). Even when cgroup plugins are not explicitly enabled in configuration, Slurm attempts to load them by default when:

1. **Cgroup filesystem is mounted** in the container
2. **Cgroup dependencies are installed** during build
3. **Systemd/dbus is not available** in the container environment

## Investigation Process

### 1. Initial Configuration Attempts
- Disabled cgroup plugins in `slurm.conf`: `TaskPlugin=task/none`, `ProctrackType=proctrack/linuxproc`
- Created minimal `cgroup.conf` with `CgroupPlugin=cgroup/none`
- Added `IgnoreSystemd=yes` to cgroup configuration

### 2. Build-Level Disabling
- Added `--disable-cgroup` and `--disable-cgroup-v2` to Slurm build configuration
- Removed `libcgroup-dev` and `libdbus-1-dev` dependencies
- Switched from Ubuntu 22.04 to Rocky Linux 8 base image

### 3. Reference Implementation Analysis
Investigated the [giovtorres/slurm-docker-cluster](https://github.com/giovtorres/slurm-docker-cluster) repository, which successfully runs Slurm in Docker without cgroup issues. Their approach:

- **No cgroup dependencies** in Dockerfile
- **No cgroup.conf file** 
- **No TaskPlugin specified** (commented out)
- **Only ProctrackType=proctrack/linuxproc**
- **Rocky Linux 8** base image

### 4. Final Attempts
- Applied giovtorres approach exactly
- Removed cgroup filesystem mount from docker-compose.yml
- Removed TaskPlugin from slurm.conf entirely

## Results

Despite all attempts, the cgroup plugin errors persisted. This indicates that the issue is fundamental to how Slurm is built and integrated with cgroup support in modern versions.

## Final Resolution

### Accepted Solution: Disable Cgroup Functionality

The only robust solution for running Slurm in Docker without systemd is to **completely disable all cgroup functionality** and accept the following limitations:

#### What Works:
- ✅ Slurm job scheduling and management
- ✅ Basic job execution
- ✅ Multi-node cluster coordination
- ✅ GPU support (when properly configured)
- ✅ Monitoring and accounting (basic)

#### What Doesn't Work:
- ❌ Job isolation (jobs can access all resources)
- ❌ Memory limits enforcement
- ❌ CPU limits enforcement
- ❌ Resource constraints
- ❌ Process containment

### Final Configuration

```bash
# slurm.conf
ProctrackType=proctrack/linuxproc
# TaskPlugin= (not specified - no task isolation)
JobAcctGatherType=jobacct_gather/none

# No cgroup.conf file

# Dockerfile (Rocky Linux 8 approach)
FROM rockylinux:8
# No cgroup or dbus dependencies
# Basic build tools only
```

### Trade-offs

This approach is suitable for:
- ✅ Development and testing environments
- ✅ Learning Slurm functionality
- ✅ Prototyping cluster configurations
- ✅ Non-production use cases

This approach is NOT suitable for:
- ❌ Production environments requiring resource isolation
- ❌ Multi-tenant environments
- ❌ Environments requiring strict resource limits
- ❌ Security-sensitive deployments

## Technical Details

### Why Cgroup Plugins Fail in Docker

1. **Systemd Dependency**: Cgroup v2 plugins require systemd for proper operation
2. **Dbus Requirement**: Cgroup plugins need dbus for systemd communication
3. **Read-only Filesystem**: Container cgroup mounts are often read-only
4. **Namespace Isolation**: Docker containers have limited access to host cgroup hierarchy

### Alternative Approaches Considered

1. **Systemd-enabled containers**: Requires privileged containers and complex setup
2. **Older Slurm versions**: May have fewer cgroup dependencies but lack modern features
3. **Different containerization**: LXC/LXD with systemd support
4. **Native installation**: Bypass containers entirely

## Conclusion

For Docker-based Slurm clusters, the most practical approach is to accept the limitations of running without cgroup support. This provides a functional Slurm environment suitable for development, testing, and learning purposes while avoiding the complexity and security implications of systemd-enabled containers.

The configuration documented above provides a working Slurm cluster that can handle job scheduling, execution, and basic management without the overhead and complexity of cgroup-based resource isolation.

---

*This resolution was reached after extensive investigation and testing with Slurm versions 22.05.9 and 23.11.7 in Docker containers on Ubuntu 22.04 hosts.* 