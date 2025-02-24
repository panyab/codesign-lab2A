#!/bin/bash

#SBATCH --job-name=Lab2A_a2p1                     # Job name
#SBATCH --ntasks=1
#SBATCH -N1                             # Number of nodes and cores per node required
#SBATCH --exclusive
#SBATCH --mem-per-cpu=4G                 # Memory per core
#SBATCH -t10:00:00                       # Duration of the job
#SBATCH --mail-type=BEGIN,END,FAIL       # Mail preferences
#SBATCH --mail-user=pbhinder3@gatech.edu # E-mail address for notifications

module load anaconda3                    # Load module dependencies

bash dse_a2_part1.sh
echo "SLURM job submitted!"