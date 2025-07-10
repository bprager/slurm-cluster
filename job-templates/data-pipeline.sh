#!/bin/bash
#SBATCH --job-name=data-pipeline
#SBATCH --output=data-pipeline-%j.out
#SBATCH --error=data-pipeline-%j.err
#SBATCH --time=01:00:00
#SBATCH --array=1-10
#SBATCH --partition=cpu
#SBATCH --cpus-per-task=2
#SBATCH --mem=4G

# Data Processing Pipeline Job Template
# Each array task processes a different data chunk

echo "=== Data Processing Pipeline Started ==="
echo "Job ID: $SLURM_JOB_ID"
echo "Array Task ID: $SLURM_ARRAY_TASK_ID"
echo "Node: $SLURMD_NODENAME"
echo "Start time: $(date)"

# Parameters
INPUT_DIR=${INPUT_DIR:-"/shared/data/raw"}
OUTPUT_DIR=${OUTPUT_DIR:-"/shared/data/processed"}
CHUNK_SIZE=${CHUNK_SIZE:-"1000"}

echo "Parameters:"
echo "  Input Directory: $INPUT_DIR"
echo "  Output Directory: $OUTPUT_DIR"
echo "  Chunk Size: $CHUNK_SIZE"
echo "  Processing Chunk: $SLURM_ARRAY_TASK_ID"

# Create output directory
mkdir -p $OUTPUT_DIR

# Simulate data processing
echo "Processing data chunk $SLURM_ARRAY_TASK_ID..."

python3 -c "
import time
import random
import json

chunk_id = $SLURM_ARRAY_TASK_ID
chunk_size = $CHUNK_SIZE

print(f'Loading data chunk {chunk_id}...')
time.sleep(2)

# Simulate data processing
print('Processing data...')
processed_records = 0
for i in range(chunk_size):
    # Simulate processing time
    time.sleep(random.uniform(0.001, 0.01))
    processed_records += 1

    if processed_records % 100 == 0:
        print(f'Processed {processed_records}/{chunk_size} records')

# Simulate saving results
output_file = f'$OUTPUT_DIR/chunk_{chunk_id}_results.json'
results = {
    'chunk_id': chunk_id,
    'processed_records': processed_records,
    'processing_time': time.time(),
    'status': 'completed'
}

with open(output_file, 'w') as f:
    json.dump(results, f, indent=2)

print(f'Results saved to: {output_file}')
print(f'Chunk {chunk_id} processing completed!')
"

echo "=== Data Processing Pipeline Completed ==="
echo "End time: $(date)"
