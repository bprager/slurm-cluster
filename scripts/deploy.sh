#!/bin/bash

# Main deployment script for Slurm cluster
# This script orchestrates the deployment across all nodes

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Configuration
UBUNTU_HOST="172.20.0.1"  # Replace with actual Ubuntu host IP
MACBOOK_HOST="192.168.1.100"  # Replace with actual MacBook IP
QNAP_MODERN_HOST="192.168.1.101"  # Replace with actual modern QNAP IP
QNAP_LEGACY_HOST="192.168.1.102"  # Replace with actual legacy QNAP IP

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if required files exist
check_prerequisites() {
    log "Checking prerequisites..."

    if [ ! -f "$PROJECT_DIR/shared/munge.key" ]; then
        warn "Munge key not found. Generating..."
        "$PROJECT_DIR/scripts/generate-munge-key.sh"
    fi

    if [ ! -f "$PROJECT_DIR/shared/slurm.conf" ]; then
        error "slurm.conf not found in shared directory"
        exit 1
    fi

    # Check if Docker is available
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed or not in PATH"
        exit 1
    fi

    if ! command -v docker compose &> /dev/null; then
        error "Docker Compose is not installed or not in PATH"
        exit 1
    fi

    log "Prerequisites check completed"
}

# Build Docker images
build_images() {
    log "Building Slurm Docker image..."
    cd "$PROJECT_DIR"
    docker build -t slurm:latest -f docker/Dockerfile.slurm docker/
    log "Docker image built successfully"
}

# Deploy controller and Ubuntu worker
deploy_controller() {
    log "Deploying Slurm controller and Ubuntu worker..."
    cd "$PROJECT_DIR"

    # Create logs directory
    mkdir -p logs
    chmod 777 logs

    # Start the main stack
    docker compose up -d

    # Wait for services to be ready
    log "Waiting for services to start..."
    sleep 30

    # Check if controller is running
    if docker compose ps | grep -q "slurmctld.*Up"; then
        log "Slurm controller started successfully"
    else
        error "Failed to start Slurm controller"
        docker compose logs slurmctld
        exit 1
    fi
}

# Deploy MacBook worker
deploy_macbook() {
    log "Deploying MacBook worker..."

    # Copy files to MacBook (requires SSH setup)
    if ping -c 1 "$MACBOOK_HOST" &> /dev/null; then
        log "Copying files to MacBook..."
        rsync -av --exclude='.git' --exclude='logs' "$PROJECT_DIR/" "user@$MACBOOK_HOST:~/slurm-cluster/"

        # SSH into MacBook and start services
        ssh "user@$MACBOOK_HOST" "cd ~/slurm-cluster && docker compose -f docker-compose.yml -f docker-compose.override.mac.yml up -d"

        log "MacBook worker deployed"
    else
        warn "MacBook ($MACBOOK_HOST) is not reachable. Skipping deployment."
    fi
}

# Deploy modern QNAP worker
deploy_qnap_modern() {
    log "Deploying modern QNAP worker..."

    if ping -c 1 "$QNAP_MODERN_HOST" &> /dev/null; then
        log "Copying files to modern QNAP..."
        rsync -av --exclude='.git' --exclude='logs' "$PROJECT_DIR/" "admin@$QNAP_MODERN_HOST:/share/slurm-cluster/"

        # SSH into QNAP and start services
        ssh "admin@$QNAP_MODERN_HOST" "cd /share/slurm-cluster && docker compose -f docker-compose.yml -f docker-compose.override.qnap.yml up -d"

        log "Modern QNAP worker deployed"
    else
        warn "Modern QNAP ($QNAP_MODERN_HOST) is not reachable. Skipping deployment."
    fi
}

# Deploy legacy QNAP (manual steps required)
deploy_qnap_legacy() {
    log "Legacy QNAP deployment requires manual steps..."

    if ping -c 1 "$QNAP_LEGACY_HOST" &> /dev/null; then
        log "Copying installation scripts to legacy QNAP..."
        rsync -av "$PROJECT_DIR/legacy-qnap/" "admin@$QNAP_LEGACY_HOST:/share/slurm-legacy/"
        rsync -av "$PROJECT_DIR/shared/" "admin@$QNAP_LEGACY_HOST:/share/slurm-legacy/config/"

        echo ""
        warn "Manual steps required for legacy QNAP:"
        echo "1. SSH to legacy QNAP: ssh admin@$QNAP_LEGACY_HOST"
        echo "2. Choose installation method:"
        echo "   - Entware: /share/slurm-legacy/install-slurm-entware.sh"
        echo "   - Alpine chroot: /share/slurm-legacy/setup-alpine-chroot.sh"
        echo "3. Follow the on-screen instructions"
        echo ""
    else
        warn "Legacy QNAP ($QNAP_LEGACY_HOST) is not reachable. Skipping deployment."
    fi
}

# Initialize cluster
initialize_cluster() {
    log "Initializing Slurm cluster..."

    # Wait for all services to be ready
    sleep 60

    # Add cluster to accounting
    docker compose exec slurmctld sacctmgr -i add cluster experimental-cluster

    # Add default account
    docker compose exec slurmctld sacctmgr -i add account default Cluster=experimental-cluster

    # Add default user
    docker compose exec slurmctld sacctmgr -i add user $USER DefaultAccount=default

    log "Cluster initialized successfully"
}

# Show cluster status
show_status() {
    log "Cluster Status:"
    echo ""

    # Show node information
    echo "=== Node Information ==="
    docker compose exec slurmctld sinfo -N -l || echo "Controller not ready"
    echo ""

    # Show partition information
    echo "=== Partition Information ==="
    docker compose exec slurmctld sinfo || echo "Controller not ready"
    echo ""

    # Show running containers
    echo "=== Running Containers ==="
    docker compose ps
    echo ""

    # Show service URLs
    echo "=== Service URLs ==="
    echo "Prometheus: http://localhost:9090"
    echo "Node Exporter: http://localhost:9100"
    echo ""
}

# Main deployment flow
main() {
    case "${1:-deploy}" in
        "check")
            check_prerequisites
            ;;
        "build")
            check_prerequisites
            build_images
            ;;
        "controller")
            check_prerequisites
            build_images
            deploy_controller
            ;;
        "macbook")
            deploy_macbook
            ;;
        "qnap-modern")
            deploy_qnap_modern
            ;;
        "qnap-legacy")
            deploy_qnap_legacy
            ;;
        "init")
            initialize_cluster
            ;;
        "status")
            show_status
            ;;
        "deploy")
            check_prerequisites
            build_images
            deploy_controller
            deploy_macbook
            deploy_qnap_modern
            deploy_qnap_legacy
            initialize_cluster
            show_status
            ;;
        "stop")
            log "Stopping all services..."
            docker compose down
            ;;
        *)
            echo "Usage: $0 {check|build|controller|macbook|qnap-modern|qnap-legacy|init|status|deploy|stop}"
            echo ""
            echo "Commands:"
            echo "  check       - Check prerequisites"
            echo "  build       - Build Docker images"
            echo "  controller  - Deploy controller and Ubuntu worker"
            echo "  macbook     - Deploy MacBook worker"
            echo "  qnap-modern - Deploy modern QNAP worker"
            echo "  qnap-legacy - Setup legacy QNAP (manual steps)"
            echo "  init        - Initialize cluster accounting"
            echo "  status      - Show cluster status"
            echo "  deploy      - Full deployment (all components)"
            echo "  stop        - Stop all services"
            exit 1
            ;;
    esac
}

main "$@"
