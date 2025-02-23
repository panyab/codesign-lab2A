#!/bin/bash

#SBATCH -=job_name=Lab2A                     # Job name
#SBATCH --ntasks=1
#SBATCH -N1                             # Number of nodes and cores per node required
#SBATCH --exclusive
#SBATCH --mem-per-cpu=4G                 # Memory per core
#SBATCH -t10:00:00                       # Duration of the job
#SBATCH --mail-type=BEGIN,END,FAIL       # Mail preferences
#SBATCH --mail-user=pbhinder3@gatech.edu # E-mail address for notifications

module load anaconda3                    # Load module dependencies
conda activate hml_lab2

echo "Submitting SLURM job..."
bash run_sim.sh
echo "SLURM job submitted!"