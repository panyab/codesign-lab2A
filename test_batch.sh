#!/bin/bash

#SBATCH -Lab2A                          # Job name
#SBATCH --ntasks=1
#SBATCH -N1 --ntasks-per-node=50         # Number of nodes and cores per node required
#SBATCH --mem-per-cpu=4G                 # Memory per core
#SBATCH -t12:00:00                       # Duration of the job
#SBATCH --mail-type=BEGIN,END,FAIL       # Mail preferences
#SBATCH --mail-user=pbhinder3@gatech.edu # E-mail address for notifications
#SBATCH --licenses=none

echo "Submitted SLURM job..."