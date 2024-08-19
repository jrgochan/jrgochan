#!/bin/sh

# Determine the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" >/dev/null 2>&1 && pwd)"
REPOSITORY_DIR="$(dirname "$SCRIPT_DIR")"

# Load environment variables from the env_vars.sh in the scripts directory within the repository
ENV_VARS_FILE="$SCRIPT_DIR/env_vars.sh"
if [ -f "$ENV_VARS_FILE" ]; then
    . "$ENV_VARS_FILE"
else
    echo "Environment variables file ($ENV_VARS_FILE) not found. Using default settings."
    # Default environment variables if the file is not found
    REPO_URL_BASE="git@github.com"
    REPO_URL_PATH="jrgochan/jrgochan"
    REPO_URL_EXTENSION="git"
    CODE_DIR="$HOME/code"
    GITHUB_DIR="$CODE_DIR/github.com"
    CLONE_DIR="$GITHUB_DIR/$REPO_URL_PATH"
fi

# Check if git is installed
if ! command -v git >/dev/null 2>&1; then
    echo "Git is not installed. Please install Git and rerun this script."
    exit 1
fi

# Check if the script is being called recursively
if [ "$USER_SCRIPT_RUNNING" = "true" ]; then
    echo "Script is already running. Exiting to prevent recursion."
    exit 0
fi

# Create the GitHub directory if it doesn't exist
if [ ! -d "$GITHUB_DIR" ]; then
    mkdir -p "$GITHUB_DIR"
fi

# Clone the repository
if [ -d "$CLONE_DIR" ]; then
    echo "Directory $CLONE_DIR already exists. Pulling the latest changes..."
    cd "$CLONE_DIR" || exit 1
    git pull origin main
else
    echo "Cloning repository $REPO_URL_BASE:$REPO_URL_PATH.$REPO_URL_EXTENSION to $CLONE_DIR..."
    git clone "$REPO_URL_BASE:$REPO_URL_PATH.$REPO_URL_EXTENSION" "$CLONE_DIR"
fi

# Check if the clone was successful
if [ ! -d "$CLONE_DIR" ]; then
    echo "Failed to clone the repository. Exiting."
    exit 1
fi

# Navigate to the repository directory
cd "$CLONE_DIR" || exit 1

# Check if the start.sh script exists and is executable
START_SCRIPT="./scripts/start.sh"
if [ ! -x "$START_SCRIPT" ]; then
    echo "The script $START_SCRIPT does not exist or is not executable. Exiting."
    exit 1
fi

# Set a flag to prevent recursion
export USER_SCRIPT_RUNNING="true"

# Execute the start script
echo "Executing $START_SCRIPT..."
sh "$START_SCRIPT"

# Check if the script executed successfully
if [ $? -eq 0 ]; then
    echo "Setup completed successfully."
else
    echo "There was an error executing $START_SCRIPT."
    exit 1
fi

# Unset the recursion flag
unset USER_SCRIPT_RUNNING

