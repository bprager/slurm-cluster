#!/bin/bash
#SBATCH --job-name=ml-training
#SBATCH --output=ml-training-%j.out
#SBATCH --error=ml-training-%j.err
#SBATCH --time=02:00:00
#SBATCH --gres=gpu:1
#SBATCH --partition=gpu
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G

# Machine Learning Training Job Template
# Usage: sbatch --export=DATASET=/path/to/data,MODEL=resnet50 ml-training.sh

echo "=== ML Training Job Started ==="
echo "Job ID: $SLURM_JOB_ID"
echo "Node: $SLURMD_NODENAME"
echo "Start time: $(date)"

# Default parameters
DATASET=${DATASET:-"/shared/datasets/sample"}
MODEL=${MODEL:-"simple_cnn"}
EPOCHS=${EPOCHS:-"10"}
BATCH_SIZE=${BATCH_SIZE:-"32"}

echo "Parameters:"
echo "  Dataset: $DATASET"
echo "  Model: $MODEL"
echo "  Epochs: $EPOCHS"
echo "  Batch Size: $BATCH_SIZE"

# Check GPU availability
if command -v nvidia-smi &> /dev/null; then
    echo "GPU Status:"
    nvidia-smi --query-gpu=name,memory.total,memory.free --format=csv
else
    echo "Warning: No GPU detected"
fi

# Create working directory
WORK_DIR="/tmp/ml_job_$SLURM_JOB_ID"
mkdir -p $WORK_DIR
cd $WORK_DIR

# Training simulation (replace with actual ML code)
echo "Starting training simulation..."
python3 -c "
import time
import random

print('Loading dataset: $DATASET')
time.sleep(2)

print('Initializing model: $MODEL')
time.sleep(1)

for epoch in range(1, $EPOCHS + 1):
    # Simulate training
    loss = random.uniform(0.1, 1.0) * (1.0 - epoch / $EPOCHS)
    accuracy = random.uniform(0.7, 0.95) * (epoch / $EPOCHS)

    print(f'Epoch {epoch}/$EPOCHS - Loss: {loss:.4f} - Accuracy: {accuracy:.4f}')
    time.sleep(5)  # Simulate training time

print('Training completed successfully!')
print('Model saved to: $WORK_DIR/model.pkl')
"

# Cleanup
echo "Cleaning up temporary files..."
rm -rf $WORK_DIR

echo "=== ML Training Job Completed ==="
echo "End time: $(date)"
