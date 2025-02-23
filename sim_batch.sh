#!/bin/bash

#SBATCH -Lab2A                          # Job name
#SBATCH --ntasks=1
#SBATCH -N1 --ntasks-per-node=50         # Number of nodes and cores per node required
#SBATCH --mem-per-cpu=4G                 # Memory per core
#SBATCH -t12:00:00                       # Duration of the job
#SBATCH -oReport-%j.out                  # Combined output and error messages file
#SBATCH --mail-type=BEGIN,END,FAIL       # Mail preferences
#SBATCH --mail-user=pbhinder3@gatech.edu # E-mail address for notifications
# cd $SLURM_SUBMIT_DIR                     # Change to working directory

module load anaconda3                    # Load module dependencies
conda activate hml_lab2

echo "Submitting SLURM job..."
bash run_sim.sh
echo "SLURM job submitted!"