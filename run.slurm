#!/bin/bash
#SBATCH --job-name=run
#SBATCH --output=run.log
#SBATCH --error=run.err
#SBATCH --nodes=3
#SBATCH --ntasks=3
#SBATCH --ntasks-per-node=1
#SBATCH --time=02:00:00
#SBATCH --partition=debug

# Define the case directory
CASE_DIR="/mnt/simulations/re200"

# Step 1-3: Run blockMesh, surfaceFeatureExtract, and decomposePar together, with logs
    apptainer exec /mnt/shared/pmi2-openfoam2412-apptainer.sif \
    bash -lc "source /usr/lib/openfoam/openfoam2412/etc/bashrc && blockMesh 2>&1 | tee blockMesh.log && surfaceFeatureExtract 2>&1 | tee surfaceFeatureExtract.log && decomposePar -force 2>&1 | tee decomposePar.log"

# Step 4: Run snappyHexMesh in parallel, with logs
srun --mpi=pmi2 --nodes=3 --ntasks=3 --ntasks-per-node=1 \
    apptainer exec /mnt/shared/pmi2-openfoam2412-apptainer.sif \
    bash -lc "source /usr/lib/openfoam/openfoam2412/etc/bashrc && snappyHexMesh 2>&1 | tee snappyHexMesh.log"

# Step 5: Check the mesh for errors, with logs
    apptainer exec /mnt/shared/pmi2-openfoam2412-apptainer.sif \
    bash -lc "source /usr/lib/openfoam/openfoam2412/etc/bashrc && checkMesh 2>&1 | tee checkMesh.log"

# Step 6: Reconstruct the mesh, with logs
    apptainer exec /mnt/shared/pmi2-openfoam2412-apptainer.sif \
    bash -lc "source /usr/lib/openfoam/openfoam2412/etc/bashrc && reconstructParMesh -constant 2>&1 | tee reconstructParMesh.log"

# Step 7: Clean up processor directories, with logs
    apptainer exec /mnt/shared/pmi2-openfoam2412-apptainer.sif \
    bash -lc "rm -rf processor* 2>&1 | tee removeProcessors.log"

# Step 8: Re-decompose the mesh after cleaning up processor directories, with logs
srun --mpi=pmi2 --nodes=3 --ntasks=3 --ntasks-per-node=1 \
    apptainer exec /mnt/shared/pmi2-openfoam2412-apptainer.sif \
    bash -lc "source /usr/lib/openfoam/openfoam2412/etc/bashrc && decomposePar -force 2>&1 | tee reDecomposePar.log"

# Step 9: Run pimpleFoam solver in parallel, with logs
srun --mpi=pmi2 --nodes=3 --ntasks=3 --ntasks-per-node=1 \
    apptainer exec /mnt/shared/pmi2-openfoam2412-apptainer.sif \
    bash -lc "source /usr/lib/openfoam/openfoam2412/etc/bashrc && pimpleFoam 2>&1 | tee pimpleFoam.log"
