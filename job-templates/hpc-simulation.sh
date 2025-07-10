#!/bin/bash
#SBATCH --job-name=hpc-simulation
#SBATCH --output=hpc-simulation-%j.out
#SBATCH --error=hpc-simulation-%j.err
#SBATCH --time=00:30:00
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=2
#SBATCH --partition=cpu

# High Performance Computing Simulation
# Demonstrates multi-node parallel execution

echo "=== HPC Simulation Started ==="
echo "Job ID: $SLURM_JOB_ID"
echo "Number of nodes: $SLURM_JOB_NUM_NODES"
echo "Node list: $SLURM_JOB_NODELIST"
echo "Total tasks: $SLURM_NTASKS"
echo "Start time: $(date)"

# Parameters
SIMULATION_SIZE=${SIMULATION_SIZE:-"10000"}
ITERATIONS=${ITERATIONS:-"100"}

echo "Simulation Parameters:"
echo "  Size: $SIMULATION_SIZE"
echo "  Iterations: $ITERATIONS"

# Create simulation script
cat > simulation_task.py << 'EOF'
import sys
import time
import random
import math
from mpi4py import MPI

def main():
    comm = MPI.COMM_WORLD
    rank = comm.Get_rank()
    size = comm.Get_size()

    simulation_size = int(sys.argv[1]) if len(sys.argv) > 1 else 10000
    iterations = int(sys.argv[2]) if len(sys.argv) > 2 else 100

    print(f"Rank {rank}/{size}: Starting simulation")

    # Divide work among processes
    local_size = simulation_size // size
    start_idx = rank * local_size
    end_idx = start_idx + local_size

    print(f"Rank {rank}: Processing indices {start_idx} to {end_idx}")

    # Simulate computational work
    local_result = 0.0
    for iteration in range(iterations):
        for i in range(start_idx, end_idx):
            # Simulate complex calculation
            local_result += math.sin(i * 0.001) * math.cos(iteration * 0.01)

        if rank == 0 and iteration % 10 == 0:
            print(f"Iteration {iteration}/{iterations} completed")

    # Gather results from all processes
    global_result = comm.reduce(local_result, op=MPI.SUM, root=0)

    if rank == 0:
        print(f"Final result: {global_result}")
        print("Simulation completed successfully!")

if __name__ == "__main__":
    main()
EOF

# Check if MPI is available, otherwise run simplified version
if command -v mpirun &> /dev/null; then
    echo "Running MPI simulation..."
    srun python3 simulation_task.py $SIMULATION_SIZE $ITERATIONS
else
    echo "MPI not available, running simplified parallel simulation..."
    srun python3 -c "
import sys
import time
import random
import math
import os

rank = int(os.environ.get('SLURM_PROCID', 0))
size = int(os.environ.get('SLURM_NTASKS', 1))
simulation_size = $SIMULATION_SIZE
iterations = $ITERATIONS

print(f'Task {rank}/{size}: Starting simulation on node {os.environ.get(\"SLURMD_NODENAME\", \"unknown\")}')

# Divide work
local_size = simulation_size // size
start_idx = rank * local_size
end_idx = start_idx + local_size

print(f'Task {rank}: Processing indices {start_idx} to {end_idx}')

# Simulate work
local_result = 0.0
for iteration in range(iterations):
    for i in range(start_idx, end_idx):
        local_result += math.sin(i * 0.001) * math.cos(iteration * 0.01)

    if rank == 0 and iteration % 20 == 0:
        print(f'Iteration {iteration}/{iterations} completed')

print(f'Task {rank}: Local result = {local_result}')
print(f'Task {rank}: Simulation completed!')
"
fi

# Cleanup
rm -f simulation_task.py

echo "=== HPC Simulation Completed ==="
echo "End time: $(date)"
