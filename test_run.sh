module load anaconda3                    # Load module dependencies
conda activate hml_lab2

echo "Submitting SLURM job..."
bash run_sim.sh
echo "SLURM job submitted!"