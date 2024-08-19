#!/bin/sh

# Check if git is installed
if ! command -v git >/dev/null 2>&1; then
    echo "Git is not installed. Please install Git and rerun this script."
    exit 1
fi

# Define the repository URL and clone path
REPO_URL_BASE="git@github.com"
REPO_URL_PATH="jrgochan/jrgochan"
REPO_URL_EXTENSION="git"
REPO_URL="$REPO_URL_BASE:$REPO_URL_PATH.$REPO_URL_EXTENSION"
CODE_DIR="$HOME/code"
GITHUB_DIR="$CODE_DIR/github.com"
CLONE_DIR="$GITHUB_DIR/$REPO_URL_PATH"

# Clone the repository
if [ -d "$CLONE_DIR" ]; then
    echo "Directory $CLONE_DIR already exists. Pulling the latest changes..."
    cd "$CLONE_DIR" || exit 1
    git pull origin main
else
    echo "Cloning repository $REPO_URL to $CLONE_DIR..."
    git clone "$REPO_URL" "$CLONE_DIR"
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

# Set a flag file to prevent multiple executions
FLAG_FILE="/tmp/jrgochan_start_flag"

if [ ! -f "$FLAG_FILE" ]; then
    # Execute the start script
    echo "Executing $START_SCRIPT..."
    sh "$START_SCRIPT"
    touch "$FLAG_FILE"
else
    echo "$START_SCRIPT has already been executed. Exiting."
fi

# Check if the script executed successfully
if [ $? -eq 0 ]; then
    echo "Setup completed successfully."
else
    echo "There was an error executing $START_SCRIPT."
    exit 1
fi


#!/bin/sh

# Check if git is installed
if ! command -v git >/dev/null 2>&1; then
    echo "Git is not installed. Please install Git and rerun this script."
    exit 1
fi

# Define the repository URL and clone path
REPO_URL="git@github.com:jrgochan/jrgochan.git"
CLONE_DIR="$HOME/code/github.com/jrgochan/jrgochan"

# Clone the repository
if [ -d "$CLONE_DIR" ]; then
    echo "Directory $CLONE_DIR already exists. Pulling the latest changes..."
    cd "$CLONE_DIR" || exit 1
    git pull origin main
else
    echo "Cloning repository $REPO_URL to $CLONE_DIR..."
    git clone "$REPO_URL" "$CLONE_DIR"
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

