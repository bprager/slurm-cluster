#!/bin/bash
set -e

# Function to wait for a service to be ready
wait_for_service() {
    local host=$1
    local port=$2
    local service_name=$3

    echo "Waiting for $service_name to be ready at $host:$port..."
    while ! nc -z $host $port; do
        sleep 1
    done
    echo "$service_name is ready!"
}

# Start munge daemon
echo "Starting munge daemon..."
mkdir -p /run/munge /var/run/munge
chown munge:munge /run/munge /var/run/munge
chmod 755 /run/munge /var/run/munge

# Create required Slurm directories
echo "Creating Slurm directories..."
mkdir -p /var/spool/slurmd /var/log/slurm /var/lib/slurm
chown -R slurm:slurm /var/spool/slurmd /var/log/slurm /var/lib/slurm
chmod 755 /var/spool/slurmd

# Copy munge key if it exists
if [ -f /etc/slurm/munge.key ]; then
    cp /etc/slurm/munge.key /etc/munge/munge.key
    chown munge:munge /etc/munge/munge.key
    chmod 400 /etc/munge/munge.key
fi

# Start munge daemon as root first, then it will drop privileges
/usr/sbin/munged --force &

# Wait a moment for munge to start
sleep 2

# Determine node type and start appropriate service
case "${SLURM_NODE_TYPE:-controller}" in
    "controller")
        echo "Starting slurmctld..."
        wait_for_service mysql 3306 "MySQL"
        exec slurmctld -D -vvv
        ;;
    "dbd")
        echo "Starting slurmdbd..."
        wait_for_service mysql 3306 "MySQL"
        exec slurmdbd -D -vvv
        ;;
    "worker")
        echo "Starting slurmd for node: ${SLURM_NODE_NAME:-$(hostname)}"
        
        # Debug: Check cgroup support
        echo "Checking cgroup support..."
        if [ -d "/sys/fs/cgroup" ]; then
            echo "Cgroup filesystem found at /sys/fs/cgroup"
            ls -la /sys/fs/cgroup/ | head -10
        else
            echo "Warning: Cgroup filesystem not found"
        fi
        
        # Debug: Check Slurm configuration
        echo "Checking Slurm configuration..."
        if [ -f "/etc/slurm/slurm.conf" ]; then
            echo "slurm.conf found"
            grep -E "(ProctrackType|TaskPlugin)" /etc/slurm/slurm.conf || echo "No ProctrackType/TaskPlugin found in slurm.conf"
        else
            echo "Error: slurm.conf not found"
        fi
        
        if [ -f "/etc/slurm/cgroup.conf" ]; then
            echo "cgroup.conf found"
            cat /etc/slurm/cgroup.conf
        else
            echo "Warning: cgroup.conf not found"
        fi
        
        wait_for_service slurmctld 6817 "slurmctld"
        exec slurmd -D -vvv
        ;;
    *)
        echo "Unknown SLURM_NODE_TYPE: ${SLURM_NODE_TYPE}"
        exit 1
        ;;
esac
