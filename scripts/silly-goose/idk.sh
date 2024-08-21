#!/bin/bash

# Variables
LOG_FILE="/home/jrgochan/code/github.com/jrgochan/jrgochan/scripts/aws/development/logs/execution_20240821_173629.log"
ERROR_LOG_FILE="/home/jrgochan/code/github.com/jrgochan/jrgochan/scripts/aws/development/logs/error_20240821_173629.log"

# Ensure directories exist on the remote server
mkdir -p /home/jrgochan/code/github.com/jrgochan/jrgochan/scripts/aws/development/production
mkdir -p /home/jrgochan/code/github.com/jrgochan/jrgochan/scripts/aws/development/logs

{
    echo "Starting remote script execution at $(date)"
    podman build -t docker.io/library/alpine .
    podman run -d --name docker.io/library/alpine docker.io/library/alpine
    echo "Remote script executed successfully."
} >> $LOG_FILE 2>> $ERROR_LOG_FILE

# Clean up the script file if successful
if [ $? -eq 0 ]; then
    rm -f /home/jrgochan/code/github.com/jrgochan/jrgochan/scripts/aws/development/production/remote_script.sh
else
    echo "Script execution failed. Logs are saved at $LOG_FILE and $ERROR_LOG_FILE."
    exit 1
fi
