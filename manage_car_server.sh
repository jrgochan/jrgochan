#!/bin/bash

# Variables
LOG_FILE="/home/jrgochan/code/github.com/jrgochan/jrgochan/scripts/aws/development/logs/execution_20240821_190901.log"
ERROR_LOG_FILE="/home/jrgochan/code/github.com/jrgochan/jrgochan/scripts/aws/development/logs/error_20240821_190901.log"

# Ensure directories exist on the remote server
mkdir -p /home/jrgochan/code/github.com/jrgochan/jrgochan/
mkdir -p /home/jrgochan/code/github.com/jrgochan/jrgochan/scripts/aws/development/logs

# Check if Dockerfile exists
if [ ! -f "/home/jrgochan/code/github.com/jrgochan/jrgochan//Dockerfile" ]; then
    echo "Dockerfile not found in /home/jrgochan/code/github.com/jrgochan/jrgochan/. Exiting." | tee -a $LOG_FILE
    exit 1
fi

# Validate container name
if [[ ! "docker.io/library/alpine" =~ ^[a-zA-Z0-9][a-zA-Z0-9_.-]*$ ]]; then
    echo "Invalid container name: docker.io/library/alpine. Exiting." | tee -a $LOG_FILE
    exit 1
fi

{
    echo "Starting remote script execution at $(date)"
    podman build -t docker.io/library/alpine .
    podman run -d --name docker.io/library/alpine docker.io/library/alpine
    echo "Remote script executed successfully."
} >> $LOG_FILE 2>> $ERROR_LOG_FILE

# Clean up the script file if successful
if [ $? -eq 0 ]; then
    rm -f /home/jrgochan/code/github.com/jrgochan/jrgochan//manage_car_server.sh
else
    echo "Script execution failed. Logs are saved at $LOG_FILE and $ERROR_LOG_FILE."
    exit 1
fi
