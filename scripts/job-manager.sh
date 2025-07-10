#!/bin/bash

# Job submission helper script
# Provides easy interface for submitting common job types

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

show_help() {
    echo "Slurm Job Submission Helper"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  submit-test         Submit test jobs"
    echo "  submit-ml          Submit ML training job"
    echo "  submit-pipeline    Submit data pipeline"
    echo "  submit-hpc         Submit HPC simulation"
    echo "  status             Show job status"
    echo "  cancel             Cancel jobs"
    echo "  logs               View job logs"
    echo ""
    echo "Examples:"
    echo "  $0 submit-test              # Submit all test jobs"
    echo "  $0 submit-ml MODEL=resnet50 # Submit ML job with specific model"
    echo "  $0 status                   # Show current job queue"
    echo "  $0 logs JOBID               # Show logs for specific job"
}

exec_slurm_cmd() {
    docker compose exec slurmctld "$@"
}

submit_test_jobs() {
    echo "Submitting test jobs..."

    echo "1. CPU test job"
    exec_slurm_cmd sbatch /shared/test-jobs/cpu-test.sh

    echo "2. Array test job"
    exec_slurm_cmd sbatch /shared/test-jobs/array-test.sh

    if exec_slurm_cmd sinfo | grep -q "gpu"; then
        echo "3. GPU test job"
        exec_slurm_cmd sbatch /shared/test-jobs/gpu-test.sh
    fi

    if [ $(exec_slurm_cmd sinfo -h | wc -l) -gt 1 ]; then
        echo "4. Multi-node test job"
        exec_slurm_cmd sbatch /shared/test-jobs/multi-node-test.sh
    fi

    echo "Test jobs submitted. Check status with: $0 status"
}

submit_ml_job() {
    local exports=""

    # Parse environment variables
    for arg in "$@"; do
        if [[ $arg == *"="* ]]; then
            exports="$exports --export=$arg"
        fi
    done

    echo "Submitting ML training job with parameters: $exports"
    exec_slurm_cmd sbatch $exports /shared/job-templates/ml-training.sh
}

submit_pipeline_job() {
    local exports=""

    # Parse environment variables
    for arg in "$@"; do
        if [[ $arg == *"="* ]]; then
            exports="$exports --export=$arg"
        fi
    done

    echo "Submitting data pipeline job with parameters: $exports"
    exec_slurm_cmd sbatch $exports /shared/job-templates/data-pipeline.sh
}

submit_hpc_job() {
    local exports=""

    # Parse environment variables
    for arg in "$@"; do
        if [[ $arg == *"="* ]]; then
            exports="$exports --export=$arg"
        fi
    done

    echo "Submitting HPC simulation job with parameters: $exports"
    exec_slurm_cmd sbatch $exports /shared/job-templates/hpc-simulation.sh
}

show_status() {
    echo "=== Cluster Status ==="
    exec_slurm_cmd sinfo
    echo ""
    echo "=== Job Queue ==="
    exec_slurm_cmd squeue
    echo ""
    echo "=== Recent Jobs ==="
    exec_slurm_cmd sacct --format=JobID,JobName,State,Start,End,Elapsed,NodeList
}

cancel_jobs() {
    if [ $# -eq 0 ]; then
        echo "Cancel all jobs? (y/N)"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            exec_slurm_cmd scancel --user=slurm
            echo "All jobs cancelled"
        fi
    else
        for jobid in "$@"; do
            exec_slurm_cmd scancel "$jobid"
            echo "Job $jobid cancelled"
        done
    fi
}

show_logs() {
    if [ $# -eq 0 ]; then
        echo "Usage: $0 logs JOBID"
        return 1
    fi

    local jobid=$1
    echo "=== Job $jobid Output ==="
    exec_slurm_cmd find /shared -name "*$jobid*" -type f -exec cat {} \;
}

# Main command handling
case "${1:-help}" in
    "submit-test")
        submit_test_jobs
        ;;
    "submit-ml")
        shift
        submit_ml_job "$@"
        ;;
    "submit-pipeline")
        shift
        submit_pipeline_job "$@"
        ;;
    "submit-hpc")
        shift
        submit_hpc_job "$@"
        ;;
    "status")
        show_status
        ;;
    "cancel")
        shift
        cancel_jobs "$@"
        ;;
    "logs")
        shift
        show_logs "$@"
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        echo "Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac
