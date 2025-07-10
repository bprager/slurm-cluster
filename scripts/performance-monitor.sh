#!/bin/bash

# Performance monitoring and optimization script
# Monitors cluster performance and provides optimization recommendations

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Configuration
MONITORING_DURATION=${MONITORING_DURATION:-300}  # 5 minutes default
OUTPUT_DIR="$PROJECT_DIR/performance-reports"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

create_output_dir() {
    mkdir -p "$OUTPUT_DIR"
}

collect_system_metrics() {
    log_info "Collecting system metrics..."

    local report_file="$OUTPUT_DIR/system_metrics_$TIMESTAMP.txt"

    {
        echo "=== System Performance Report ==="
        echo "Generated: $(date)"
        echo "Duration: $MONITORING_DURATION seconds"
        echo ""

        echo "=== CPU Usage ==="
        docker compose exec -T slurmctld top -bn1 | head -20
        echo ""

        echo "=== Memory Usage ==="
        docker compose exec -T slurmctld free -h
        echo ""

        echo "=== Disk Usage ==="
        docker compose exec -T slurmctld df -h
        echo ""

        echo "=== Network Statistics ==="
        docker compose exec -T slurmctld cat /proc/net/dev
        echo ""

        echo "=== Container Resource Usage ==="
        docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}"

    } > "$report_file"

    log_info "System metrics saved to: $report_file"
}

collect_slurm_metrics() {
    log_info "Collecting Slurm metrics..."

    local report_file="$OUTPUT_DIR/slurm_metrics_$TIMESTAMP.txt"

    {
        echo "=== Slurm Performance Report ==="
        echo "Generated: $(date)"
        echo ""

        echo "=== Cluster Overview ==="
        docker compose exec -T slurmctld sinfo
        echo ""

        echo "=== Node Details ==="
        docker compose exec -T slurmctld scontrol show nodes
        echo ""

        echo "=== Current Jobs ==="
        docker compose exec -T slurmctld squeue -o "%.18i %.9P %.20j %.8u %.8T %.10M %.9l %.6D %R"
        echo ""

        echo "=== Job History (Last 24 hours) ==="
        docker compose exec -T slurmctld sacct --starttime=$(date -d '24 hours ago' +%Y-%m-%d) --format=JobID,JobName,State,Start,End,Elapsed,AllocCPUS,ReqMem,NodeList
        echo ""

        echo "=== Partition Information ==="
        docker compose exec -T slurmctld scontrol show partition
        echo ""

        echo "=== Controller Statistics ==="
        docker compose exec -T slurmctld scontrol show stats

    } > "$report_file"

    log_info "Slurm metrics saved to: $report_file"
}

collect_monitoring_metrics() {
    log_info "Collecting monitoring metrics..."

    local report_file="$OUTPUT_DIR/monitoring_metrics_$TIMESTAMP.txt"

    {
        echo "=== Monitoring Metrics Report ==="
        echo "Generated: $(date)"
        echo ""

        echo "=== Prometheus Targets ==="
        if curl -s http://localhost:9090/api/v1/targets > /dev/null 2>&1; then
            curl -s http://localhost:9090/api/v1/targets | jq -r '.data.activeTargets[] | "\(.labels.instance) - \(.health)"' 2>/dev/null || echo "jq not available for JSON parsing"
        else
            echo "Prometheus not accessible"
        fi
        echo ""

        echo "=== Node Exporter Metrics Sample ==="
        if curl -s http://localhost:9100/metrics > /dev/null 2>&1; then
            curl -s http://localhost:9100/metrics | grep -E "^(node_cpu_seconds_total|node_memory_MemTotal_bytes|node_memory_MemAvailable_bytes)" | head -10
        else
            echo "Node Exporter not accessible"
        fi
        echo ""

        echo "=== Container Health ==="
        docker compose ps

    } > "$report_file"

    log_info "Monitoring metrics saved to: $report_file"
}

analyze_performance() {
    log_info "Analyzing performance..."

    local analysis_file="$OUTPUT_DIR/performance_analysis_$TIMESTAMP.txt"

    {
        echo "=== Performance Analysis ==="
        echo "Generated: $(date)"
        echo ""

        # CPU Analysis
        echo "=== CPU Performance Analysis ==="
        local cpu_usage=$(docker stats --no-stream --format "{{.CPUPerc}}" | grep -o '[0-9.]*' | awk '{sum+=$1; count++} END {print sum/count}')
        echo "Average CPU usage across containers: ${cpu_usage:-N/A}%"

        if [ -n "$cpu_usage" ] && [ $(echo "$cpu_usage > 80" | bc -l 2>/dev/null || echo 0) -eq 1 ]; then
            echo "⚠ HIGH CPU USAGE detected - consider adding more worker nodes"
        elif [ -n "$cpu_usage" ] && [ $(echo "$cpu_usage < 20" | bc -l 2>/dev/null || echo 1) -eq 1 ]; then
            echo "ℹ Low CPU usage - cluster may be underutilized"
        fi
        echo ""

        # Memory Analysis
        echo "=== Memory Performance Analysis ==="
        local mem_info=$(docker compose exec -T slurmctld free | grep Mem)
        local mem_total=$(echo "$mem_info" | awk '{print $2}')
        local mem_used=$(echo "$mem_info" | awk '{print $3}')
        local mem_percent=$(echo "scale=2; $mem_used * 100 / $mem_total" | bc -l 2>/dev/null || echo "N/A")
        echo "Memory usage: ${mem_percent}%"

        if [ -n "$mem_percent" ] && [ $(echo "$mem_percent > 85" | bc -l 2>/dev/null || echo 0) -eq 1 ]; then
            echo "⚠ HIGH MEMORY USAGE detected - consider optimizing job memory requirements"
        fi
        echo ""

        # Job Analysis
        echo "=== Job Performance Analysis ==="
        local pending_jobs=$(docker compose exec -T slurmctld squeue -t PD -h | wc -l)
        local running_jobs=$(docker compose exec -T slurmctld squeue -t R -h | wc -l)

        echo "Pending jobs: $pending_jobs"
        echo "Running jobs: $running_jobs"

        if [ "$pending_jobs" -gt 5 ]; then
            echo "⚠ High number of pending jobs - consider adding more worker nodes"
        fi
        echo ""

        # Node Analysis
        echo "=== Node Performance Analysis ==="
        local down_nodes=$(docker compose exec -T slurmctld sinfo -h -t down | wc -l)
        local idle_nodes=$(docker compose exec -T slurmctld sinfo -h -t idle | wc -l)

        echo "Down nodes: $down_nodes"
        echo "Idle nodes: $idle_nodes"

        if [ "$down_nodes" -gt 0 ]; then
            echo "⚠ Some nodes are down - check node health"
        fi
        echo ""

        # Recommendations
        echo "=== Optimization Recommendations ==="
        echo "1. Monitor job completion times and adjust resource requests"
        echo "2. Use job arrays for parallel workloads"
        echo "3. Configure appropriate job time limits"
        echo "4. Monitor disk I/O for storage bottlenecks"
        echo "5. Use Grafana dashboards for real-time monitoring"
        echo "6. Consider implementing QoS policies for job prioritization"

    } > "$analysis_file"

    log_info "Performance analysis saved to: $analysis_file"
}

generate_summary_report() {
    log_info "Generating summary report..."

    local summary_file="$OUTPUT_DIR/performance_summary_$TIMESTAMP.html"

    cat > "$summary_file" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Slurm Cluster Performance Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #f0f0f0; padding: 20px; border-radius: 5px; }
        .section { margin: 20px 0; padding: 15px; border-left: 4px solid #007acc; }
        .warning { border-left-color: #ff9900; background-color: #fff3cd; }
        .error { border-left-color: #dc3545; background-color: #f8d7da; }
        .good { border-left-color: #28a745; background-color: #d4edda; }
        pre { background-color: #f8f9fa; padding: 10px; border-radius: 3px; overflow-x: auto; }
        .metric { display: inline-block; margin: 10px; padding: 10px; background-color: #e9ecef; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Slurm Cluster Performance Report</h1>
        <p>Generated: $(date)</p>
        <p>Report ID: $TIMESTAMP</p>
    </div>

    <div class="section">
        <h2>Quick Metrics</h2>
        <div class="metric">
            <strong>Active Nodes:</strong> $(docker compose exec -T slurmctld sinfo -h | wc -l)
        </div>
        <div class="metric">
            <strong>Running Jobs:</strong> $(docker compose exec -T slurmctld squeue -t R -h | wc -l)
        </div>
        <div class="metric">
            <strong>Pending Jobs:</strong> $(docker compose exec -T slurmctld squeue -t PD -h | wc -l)
        </div>
        <div class="metric">
            <strong>Completed Jobs (24h):</strong> $(docker compose exec -T slurmctld sacct --starttime=$(date -d '24 hours ago' +%Y-%m-%d) --state=COMPLETED -n | wc -l)
        </div>
    </div>

    <div class="section">
        <h2>System Health</h2>
        <p>Run health check: <code>./scripts/health-check.sh</code></p>
        <p>View detailed metrics in the generated report files.</p>
    </div>

    <div class="section">
        <h2>Generated Files</h2>
        <ul>
            <li>System Metrics: system_metrics_$TIMESTAMP.txt</li>
            <li>Slurm Metrics: slurm_metrics_$TIMESTAMP.txt</li>
            <li>Monitoring Metrics: monitoring_metrics_$TIMESTAMP.txt</li>
            <li>Performance Analysis: performance_analysis_$TIMESTAMP.txt</li>
        </ul>
    </div>

    <div class="section">
        <h2>Useful Commands</h2>
        <pre>
# View current status
./scripts/job-manager.sh status

# Submit test jobs
./scripts/job-manager.sh submit-test

# Health check
./scripts/health-check.sh

# Performance monitoring
./scripts/performance-monitor.sh
        </pre>
    </div>
</body>
</html>
EOF

    log_info "Summary report saved to: $summary_file"
    log_info "Open in browser: file://$summary_file"
}

main() {
    echo "Starting performance monitoring..."
    echo "Duration: $MONITORING_DURATION seconds"
    echo "Output directory: $OUTPUT_DIR"
    echo ""

    create_output_dir
    collect_system_metrics
    collect_slurm_metrics
    collect_monitoring_metrics
    analyze_performance
    generate_summary_report

    echo ""
    echo "Performance monitoring completed!"
    echo "Reports available in: $OUTPUT_DIR"
}

# Handle command line arguments
case "${1:-monitor}" in
    "monitor")
        main
        ;;
    "quick")
        MONITORING_DURATION=60
        main
        ;;
    "extended")
        MONITORING_DURATION=900  # 15 minutes
        main
        ;;
    *)
        echo "Usage: $0 [monitor|quick|extended]"
        echo "  monitor   - Standard 5-minute monitoring (default)"
        echo "  quick     - Quick 1-minute check"
        echo "  extended  - Extended 15-minute monitoring"
        exit 1
        ;;
esac
