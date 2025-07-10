<!-- markdownlint-disable MD024 -->
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## TODO

### Critical Issues (Current Version Not Working)
- **Fix cgroup plugin initialization failures** - slurmd-ubuntu service keeps restarting due to dbus/systemd issues
- **Resolve container startup problems** - Investigate why cgroup plugins are being loaded despite configuration attempts to disable them
- **Implement working Slurm configuration** - Current setup fails to initialize properly in Docker environment

### Immediate Next Steps
- **Debug cgroup plugin loading** - Investigate why Slurm still tries to load cgroup plugins even when disabled
- **Test alternative base images** - Try different Linux distributions (Alpine, Debian) that might have better Docker compatibility
- **Implement systemd-enabled containers** - Consider using systemd-enabled Docker containers as alternative approach
- **Create minimal working configuration** - Strip down to bare minimum Slurm setup that actually works

### Medium-term Improvements
- **Add comprehensive health checks** - Implement proper monitoring and alerting for cluster status
- **Improve error handling** - Better logging and error recovery mechanisms
- **Document troubleshooting procedures** - Create step-by-step guides for common issues
- **Add automated testing** - Implement CI/CD pipeline for configuration validation

### Long-term Goals
- **Production readiness** - Address security, scalability, and reliability concerns
- **Performance optimization** - Tune Slurm configuration for better resource utilization
- **Monitoring integration** - Complete Prometheus/Grafana setup with proper dashboards
- **Documentation completion** - Comprehensive user and administrator guides

### Evaluate similar exisiting GitHub repo
- **Check out [slurm-docker-cluster](https://github.com/giovtorres/slurm-docker-cluster) repo
- **Reproduce it, get it running and compare the differences

## [0.1.1] - 2025-01-10

### Fixed
- **Cgroup plugin investigation** - Documented extensive troubleshooting of cgroup/dbus issues in Docker environment
- **Configuration analysis** - Identified root causes of Slurm initialization failures
- **Alternative approaches** - Researched and documented multiple solution strategies

### Changed
- **Documentation structure** - Added comprehensive issue resolution documentation
- **Project status** - Updated implementation status to reflect current non-working state
- **Technical approach** - Shifted focus from feature completion to stability and reliability

### Added
- **CGROUP_ISSUE_RESOLUTION.md** - Comprehensive documentation of cgroup plugin troubleshooting
- **IMPLEMENTATION_COMPLETE.md** - Detailed implementation status and feature documentation
- **Enhanced project structure** - Added monitoring, job templates, and management scripts
- **Multi-platform support** - Docker Compose overrides for Ubuntu, macOS, and QNAP platforms

## [0.1.0] - Tue Jul  1 10:43:58 AM PDT 2025

### Added

- Initial version
- Changelog
