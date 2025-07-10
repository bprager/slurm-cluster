#!/bin/bash

# Test jobs for Slurm cluster validation

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Create test job scripts
mkdir -p "$PROJECT_DIR/test-jobs"

# Simple CPU test job
cat > "$PROJECT_DIR/test-jobs/cpu-test.sh" << 'EOF'
#!/bin/bash
#SBATCH --job-name=cpu-test
#SBATCH --output=cpu-test.out
#SBATCH --error=cpu-test.err
#SBATCH --time=00:05:00
#SBATCH --cpus-per-task=1
#SBATCH --partition=cpu

echo "Starting CPU test job on $(hostname)"
echo "Current time: $(date)"
echo "Slurm Job ID: $SLURM_JOB_ID"
echo "Node name: $SLURMD_NODENAME"

# Simple CPU workload
echo "Running CPU-intensive calculation..."
python3 -c "
import time
import math
start = time.time()
result = sum(math.sqrt(i) for i in range(1000000))
end = time.time()
print(f'Calculation result: {result:.2f}')
print(f'Execution time: {end-start:.2f} seconds')
"

echo "CPU test completed at $(date)"
EOF

# GPU test job (if GPU available)
cat > "$PROJECT_DIR/test-jobs/gpu-test.sh" << 'EOF'
#!/bin/bash
#SBATCH --job-name=gpu-test
#SBATCH --output=gpu-test.out
#SBATCH --error=gpu-test.err
#SBATCH --time=00:05:00
#SBATCH --gres=gpu:1
#SBATCH --partition=gpu

echo "Starting GPU test job on $(hostname)"
echo "Current time: $(date)"
echo "Slurm Job ID: $SLURM_JOB_ID"
echo "Node name: $SLURMD_NODENAME"

# Check if GPU is available
if command -v nvidia-smi &> /dev/null; then
    echo "GPU Information:"
    nvidia-smi
else
    echo "nvidia-smi not available, checking for GPU devices..."
    ls -la /dev/ | grep -i gpu || echo "No GPU devices found"
fi

# Simple GPU test with Python (if available)
python3 -c "
try:
    import torch
    if torch.cuda.is_available():
        print(f'CUDA is available. GPU count: {torch.cuda.device_count()}')
        print(f'Current GPU: {torch.cuda.get_device_name(0)}')
        # Simple tensor operation on GPU
        x = torch.randn(1000, 1000).cuda()
        y = torch.randn(1000, 1000).cuda()
        z = torch.mm(x, y)
        print(f'GPU matrix multiplication completed. Result shape: {z.shape}')
    else:
        print('CUDA is not available')
except ImportError:
    print('PyTorch not installed, skipping GPU test')
except Exception as e:
    print(f'GPU test failed: {e}')
"

echo "GPU test completed at $(date)"
EOF

# Multi-node test job
cat > "$PROJECT_DIR/test-jobs/multi-node-test.sh" << 'EOF'
#!/bin/bash
#SBATCH --job-name=multi-node-test
#SBATCH --output=multi-node-test.out
#SBATCH --error=multi-node-test.err
#SBATCH --time=00:10:00
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=1
#SBATCH --partition=cpu

echo "Starting multi-node test job"
echo "Current time: $(date)"
echo "Slurm Job ID: $SLURM_JOB_ID"
echo "Number of nodes: $SLURM_JOB_NUM_NODES"
echo "Node list: $SLURM_JOB_NODELIST"

# Run on each node
srun hostname
srun echo "Task running on node: \$(hostname)"

# Test communication between nodes
srun bash -c 'echo "Node \$(hostname) can reach: \$(ping -c 1 \$(scontrol show hostname \$SLURM_JOB_NODELIST | head -1) | head -1)"'

echo "Multi-node test completed at $(date)"
EOF

# Array job test
cat > "$PROJECT_DIR/test-jobs/array-test.sh" << 'EOF'
#!/bin/bash
#SBATCH --job-name=array-test
#SBATCH --output=array-test-%A_%a.out
#SBATCH --error=array-test-%A_%a.err
#SBATCH --time=00:05:00
#SBATCH --array=1-5
#SBATCH --partition=cpu

echo "Starting array job task $SLURM_ARRAY_TASK_ID"
echo "Current time: $(date)"
echo "Slurm Job ID: $SLURM_JOB_ID"
echo "Array Job ID: $SLURM_ARRAY_JOB_ID"
echo "Array Task ID: $SLURM_ARRAY_TASK_ID"
echo "Node name: $SLURMD_NODENAME"

# Simulate different work based on task ID
sleep $((SLURM_ARRAY_TASK_ID * 2))
echo "Task $SLURM_ARRAY_TASK_ID processing data chunk $SLURM_ARRAY_TASK_ID"

# Simple calculation based on task ID
result=$((SLURM_ARRAY_TASK_ID * SLURM_ARRAY_TASK_ID))
echo "Result for task $SLURM_ARRAY_TASK_ID: $result"

echo "Array task $SLURM_ARRAY_TASK_ID completed at $(date)"
EOF

# Make all test scripts executable
chmod +x "$PROJECT_DIR/test-jobs"/*.sh

echo "Test job scripts created in $PROJECT_DIR/test-jobs/"
echo ""
echo "Available test jobs:"
echo "1. cpu-test.sh - Simple CPU workload test"
echo "2. gpu-test.sh - GPU availability and workload test"
echo "3. multi-node-test.sh - Multi-node communication test"
echo "4. array-test.sh - Array job test"
echo ""
echo "To submit a test job:"
echo "  docker compose exec slurmctld sbatch /shared/test-jobs/cpu-test.sh"
echo ""
echo "To check job status:"
echo "  docker compose exec slurmctld squeue"
echo ""
echo "To view job output:"
echo "  docker compose exec slurmctld cat cpu-test.out"
