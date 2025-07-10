#!/bin/bash

# Comprehensive cluster health check script
# Validates all aspects of the Slurm cluster deployment

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test results tracking
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_WARNINGS=0

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    ((TESTS_WARNINGS++))
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    ((TESTS_FAILED++))
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((TESTS_PASSED++))
}

exec_docker_cmd() {
    docker compose exec -T slurmctld "$@" 2>/dev/null || return 1
}

check_docker_services() {
    log_info "Checking Docker services..."

    local services=("slurmctld" "mysql" "slurmdbd" "slurmd-ubuntu" "prometheus" "node-exporter")

    for service in "${services[@]}"; do
        if docker compose ps --services --filter "status=running" | grep -q "^${service}$"; then
            log_pass "Service $service is running"
        else
            log_error "Service $service is not running"
        fi
    done
}

check_slurm_controller() {
    log_info "Checking Slurm controller..."

    if exec_docker_cmd scontrol ping > /dev/null 2>&1; then
        log_pass "Slurm controller is responsive"
    else
        log_error "Slurm controller is not responding"
        return 1
    fi

    # Check controller status
    local status=$(exec_docker_cmd scontrol show config | grep "SLURM_VERSION" | head -1)
    if [ -n "$status" ]; then
        log_pass "Controller configuration: $status"
    else
        log_warn "Could not retrieve controller configuration"
    fi
}

check_slurm_nodes() {
    log_info "Checking Slurm nodes..."

    local nodes_output=$(exec_docker_cmd sinfo -h -o "%n %t" 2>/dev/null || echo "")

    if [ -z "$nodes_output" ]; then
        log_error "Could not retrieve node information"
        return 1
    fi

    while IFS= read -r line; do
        if [ -n "$line" ]; then
            local node=$(echo "$line" | awk '{print $1}')
            local state=$(echo "$line" | awk '{print $2}')

            case "$state" in
                "idle"|"mix"|"alloc")
                    log_pass "Node $node is $state"
                    ;;
                "down"|"drain"|"fail")
                    log_error "Node $node is $state"
                    ;;
                *)
                    log_warn "Node $node has unknown state: $state"
                    ;;
            esac
        fi
    done <<< "$nodes_output"
}

check_munge_authentication() {
    log_info "Checking Munge authentication..."

    if exec_docker_cmd munge -n | exec_docker_cmd unmunge > /dev/null 2>&1; then
        log_pass "Munge authentication is working"
    else
        log_error "Munge authentication failed"
    fi
}

check_database_connectivity() {
    log_info "Checking database connectivity..."

    if docker compose exec -T mysql mysql -u slurm -pslurm_pass -e "SELECT 1;" > /dev/null 2>&1; then
        log_pass "Database connectivity is working"
    else
        log_error "Database connectivity failed"
    fi

    # Check if accounting is working
    if exec_docker_cmd sacctmgr show cluster -n > /dev/null 2>&1; then
        log_pass "Slurm accounting is functional"
    else
        log_warn "Slurm accounting may not be configured"
    fi
}

check_job_submission() {
    log_info "Checking job submission..."

    # Submit a simple test job
    local job_output=$(exec_docker_cmd sbatch --wrap="echo 'Health check job'" --output=/dev/null --error=/dev/null 2>/dev/null || echo "")

    if [[ $job_output =~ ^"Submitted batch job".*([0-9]+) ]]; then
        local job_id=$(echo "$job_output" | grep -o '[0-9]\+$')
        log_pass "Job submission successful (Job ID: $job_id)"

        # Wait a moment and check job status
        sleep 5
        local job_state=$(exec_docker_cmd squeue -j "$job_id" -h -o "%t" 2>/dev/null || echo "")

        if [ -n "$job_state" ]; then
            log_pass "Job $job_id is in state: $job_state"
        else
            log_pass "Job $job_id completed quickly (likely finished)"
        fi
    else
        log_error "Job submission failed"
    fi
}

check_monitoring_services() {
    log_info "Checking monitoring services..."

    # Check Prometheus
    if curl -s http://localhost:9090/-/healthy > /dev/null 2>&1; then
        log_pass "Prometheus is healthy"
    else
        log_warn "Prometheus is not accessible on localhost:9090"
    fi

    # Check Node Exporter
    if curl -s http://localhost:9100/metrics > /dev/null 2>&1; then
        log_pass "Node Exporter is providing metrics"
    else
        log_warn "Node Exporter is not accessible on localhost:9100"
    fi
}

check_resource_usage() {
    log_info "Checking resource usage..."

    # Check disk space
    local disk_usage=$(df /var/lib/docker | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$disk_usage" -lt 80 ]; then
        log_pass "Disk usage is $disk_usage% (healthy)"
    elif [ "$disk_usage" -lt 90 ]; then
        log_warn "Disk usage is $disk_usage% (consider cleanup)"
    else
        log_error "Disk usage is $disk_usage% (critical)"
    fi

    # Check memory usage
    local mem_usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
    if [ "$mem_usage" -lt 80 ]; then
        log_pass "Memory usage is $mem_usage% (healthy)"
    elif [ "$mem_usage" -lt 90 ]; then
        log_warn "Memory usage is $mem_usage% (monitor closely)"
    else
        log_error "Memory usage is $mem_usage% (critical)"
    fi
}

check_network_connectivity() {
    log_info "Checking network connectivity..."

    # Test controller to worker connectivity
    local controller_ip="172.20.0.10"
    local worker_ip="172.20.0.20"

    if docker compose exec -T slurmctld ping -c 1 "$worker_ip" > /dev/null 2>&1; then
        log_pass "Controller can reach worker nodes"
    else
        log_error "Controller cannot reach worker nodes"
    fi

    # Test DNS resolution within cluster
    if docker compose exec -T slurmctld nslookup mysql > /dev/null 2>&1; then
        log_pass "DNS resolution is working within cluster"
    else
        log_warn "DNS resolution issues detected"
    fi
}

generate_summary() {
    echo ""
    echo "=================================="
    echo "    CLUSTER HEALTH CHECK SUMMARY"
    echo "=================================="
    echo -e "Tests Passed:   ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Tests Failed:   ${RED}$TESTS_FAILED${NC}"
    echo -e "Warnings:       ${YELLOW}$TESTS_WARNINGS${NC}"
    echo ""

    if [ $TESTS_FAILED -eq 0 ]; then
        if [ $TESTS_WARNINGS -eq 0 ]; then
            echo -e "${GREEN}✓ Cluster is healthy!${NC}"
            exit 0
        else
            echo -e "${YELLOW}⚠ Cluster is mostly healthy with some warnings${NC}"
            exit 1
        fi
    else
        echo -e "${RED}✗ Cluster has critical issues that need attention${NC}"
        exit 2
    fi
}

main() {
    echo "Starting comprehensive cluster health check..."
    echo "Time: $(date)"
    echo ""

    check_docker_services
    check_slurm_controller
    check_slurm_nodes
    check_munge_authentication
    check_database_connectivity
    check_job_submission
    check_monitoring_services
    check_resource_usage
    check_network_connectivity

    generate_summary
}

# Run health check
main "$@"
