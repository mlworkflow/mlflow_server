#!/bin/bash

echo "Script started. Current user: $(whoami)"
echo "Attempting to initialize Conda from /home/azureuser/miniconda3/"

# Path to your Conda installation (for user azureuser)
CONDA_INSTALL_PATH="/home/azureuser/miniconda3"
CONDA_SH_PATH="${CONDA_INSTALL_PATH}/etc/profile.d/conda.sh"

if [ -f "${CONDA_SH_PATH}" ]; then
    echo "Found conda.sh at ${CONDA_SH_PATH}. Sourcing it..."
    # The dot . is an alias for the source command
    . "${CONDA_SH_PATH}"
    SOURCE_STATUS=$?
    if [ $SOURCE_STATUS -ne 0 ]; then
        echo "Error: Sourcing ${CONDA_SH_PATH} failed with status $SOURCE_STATUS. Conda might not be properly initialized."
        exit 1 # Exit if sourcing fails
    else
        echo "Sourcing ${CONDA_SH_PATH} seems to have succeeded."
    fi
else
    echo "Error: conda.sh not found at ${CONDA_SH_PATH}."
    echo "Please verify that Conda is installed at ${CONDA_INSTALL_PATH} for the 'azureuser'."
    exit 1
fi

# After sourcing, check if conda command is truly available
if ! command -v conda &> /dev/null; then
    echo "Error: 'conda' command is STILL NOT FOUND even after attempting to source ${CONDA_SH_PATH}."
    echo "This could indicate a problem with the Conda installation itself at ${CONDA_INSTALL_PATH}, or permissions."
    echo "Current PATH: $PATH"
    # As a diagnostic, check if the conda executable exists where expected
    if [ -x "${CONDA_INSTALL_PATH}/bin/conda" ]; then
         echo "Executable ${CONDA_INSTALL_PATH}/bin/conda exists."
    else
         echo "Executable ${CONDA_INSTALL_PATH}/bin/conda DOES NOT EXIST or is not executable."
    fi
    exit 1
else
    echo "'conda' command is now available."
    echo "conda location: $(which conda)"
    echo "conda version: $(conda --version)"
fi

echo "Attempting to activate conda environment 'py311_env'..."
conda activate py311_env
ACTIVATION_STATUS=$?

if [ $ACTIVATION_STATUS -ne 0 ]; then
    echo "Error: Failed to activate conda environment 'py311_env'. Status: $ACTIVATION_STATUS"
    echo "Available conda environments:"
    conda info --envs # This will list environments within /home/azureuser/miniconda3
    exit 1
else
    echo "Successfully activated conda environment 'py311_env'."
    echo "Current active environment: $CONDA_DEFAULT_ENV"
    echo "Python path: $(which python)"
fi

if ! command -v mlflow &> /dev/null; then
    echo "Error: mlflow command could not be found after attempting to activate 'py311_env'."
    echo "Please ensure mlflow is installed in the 'py311_env' environment (within the Conda at ${CONDA_INSTALL_PATH})."
    exit 1
else
    echo "mlflow command found at: $(which mlflow)"
fi

echo "Starting MLflow server..."
# Define where MLflow data should reside.
# Using an absolute path within azureuser's home directory is a good option,
# assuming the script has necessary permissions if it runs as a different user (e.g., root).
# If "Run Command" runs as root, root will need write access to /home/azureuser/mlflow_data.
# Alternatively, use a system path like /var/mlflow_data or /opt/mlflow_data if root should own the files.
MLFLOW_DATA_DIR="/home/azureuser/mlflow_data"
mkdir -p "${MLFLOW_DATA_DIR}" # Ensure the directory exists
cd "${MLFLOW_DATA_DIR}"
echo "Changed working directory to $(pwd) for MLflow server."

mlflow server \
  --backend-store-uri sqlite:///mlflow.db \
  --default-artifact-root ./mlruns \
  --host 0.0.0.0 \
  --port 5000

echo "MLflow server command executed."
