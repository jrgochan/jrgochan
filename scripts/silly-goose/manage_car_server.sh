#!/bin/bash

# Load configuration from JSON files
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit

SSH_CONFIG_FILE="$SCRIPT_DIR/config/ssh_config.json"
SCRIPT_CONFIG_FILE="$SCRIPT_DIR/config/script_config.json"
MESSAGES_FILE="$SCRIPT_DIR/config/messages_en.json"

# Function to read JSON values
function read_json() {
  echo $(jq -r ".$1" $2)
}

# Function to read messages from I18n JSON
function get_message() {
  jq -r ".messages.$1" $MESSAGES_FILE
}

# Load SSH configuration
SERVER_USER=$(read_json "server_user" $SSH_CONFIG_FILE)
SERVER_ADDRESSES=$(jq -r ".server_addresses[]" $SSH_CONFIG_FILE)

# Load script configuration
REPO_DIR=$(read_json "repo_dir" $SCRIPT_CONFIG_FILE)
REMOTE_SCRIPT_DIR=$(read_json "remote_script_dir" $SCRIPT_CONFIG_FILE | sed "s@\\\$HOME@/home/$SERVER_USER@")
REMOTE_LOG_DIR=$(read_json "remote_log_dir" $SCRIPT_CONFIG_FILE | sed "s@\\\$HOME@/home/$SERVER_USER@")
LOCAL_LOG_DIR=$(read_json "local_log_dir" $SCRIPT_CONFIG_FILE)
SCRIPT_NAME=$(read_json "script_name" $SCRIPT_CONFIG_FILE)
PHONE_NUMBER=$(read_json "phone_number" $SCRIPT_CONFIG_FILE)
EMAIL=$(read_json "email" $SCRIPT_CONFIG_FILE)
CONTAINER_NAME=$(read_json "container_name" $SCRIPT_CONFIG_FILE)

DATE=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$LOCAL_LOG_DIR/execution_$DATE.log"
ERROR_LOG_FILE="$LOCAL_LOG_DIR/error_$DATE.log"

# Ensure the logs directory exists locally
mkdir -p "$LOCAL_LOG_DIR"

# Ensure GITHUB_BRANCH is set
GITHUB_BRANCH="${GITHUB_BRANCH:-main}"

# Step 1: Ensure script is run from the base of the git repo
cd "$(git rev-parse --show-toplevel)" || exit

# Step 2: Check if the local repository is in sync with GitHub
git fetch origin $GITHUB_BRANCH
LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse "origin/$GITHUB_BRANCH")
BASE=$(git merge-base @ "origin/$GITHUB_BRANCH")

if [ -z "$LOCAL" ] || [ -z "$REMOTE" ] || [ -z "$BASE" ]; then
    echo "Git repository is not properly set up or is missing commits. Exiting." | tee -a "$LOG_FILE"
    exit 1
fi

if [ "$LOCAL" = "$REMOTE" ]; then
    echo "$(get_message "repo_in_sync")" | tee -a "$LOG_FILE"
elif [ "$LOCAL" = "$BASE" ]; then
    echo "$(get_message "repo_behind")" | tee -a "$LOG_FILE"
    read -p "Do you want to continue running the script on the server (y/n)? " -n 1 -r
    echo    # move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
elif [ "$REMOTE" = "$BASE" ]; then
    echo "$(get_message "repo_ahead")" | tee -a "$LOG_FILE"
    read -p "Do you want to continue running the script on the server (y/n)? " -n 1 -r
    echo    # move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo "$(get_message "repo_diverged")" | tee -a "$LOG_FILE"
    read -p "Do you want to continue running the script on the server (y/n)? " -n 1 -r
    echo    # move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Step 3: Try to connect to one of the server addresses
CONNECTED_SERVER=""
for SERVER_ADDRESS in $SERVER_ADDRESSES; do
    echo "$(get_message "ssh_connecting" | sed "s/{server}/$SERVER_ADDRESS/")" | tee -a $LOG_FILE
    ssh -q -o ConnectTimeout=5 $SERVER_USER@$SERVER_ADDRESS exit
    if [ $? -eq 0 ]; then
        CONNECTED_SERVER=$SERVER_ADDRESS
        echo "$(get_message "ssh_connected" | sed "s/{server}/$CONNECTED_SERVER/")" | tee -a $LOG_FILE
        break
    fi
done

if [ -z "$CONNECTED_SERVER" ]; then
    echo "$(get_message "ssh_failed")" | tee -a $LOG_FILE
    exit 1
fi

# Step 4: Create the remote directories if they don't exist
ssh $SERVER_USER@$CONNECTED_SERVER "mkdir -p $REMOTE_SCRIPT_DIR $REMOTE_LOG_DIR"

# Step 5: Prepare the script content to be run on the remote server
cat << EOF > $SCRIPT_NAME
#!/bin/bash

# Variables
LOG_FILE="$REMOTE_LOG_DIR/execution_$DATE.log"
ERROR_LOG_FILE="$REMOTE_LOG_DIR/error_$DATE.log"

# Ensure directories exist on the remote server
mkdir -p $REMOTE_SCRIPT_DIR
mkdir -p $REMOTE_LOG_DIR

# Check if Dockerfile exists
if [ ! -f "$REMOTE_SCRIPT_DIR/Dockerfile" ]; then
    echo "Dockerfile not found in $REMOTE_SCRIPT_DIR. Exiting." | tee -a \$LOG_FILE
    exit 1
fi

# Validate container name
if [[ ! "$CONTAINER_NAME" =~ ^[a-zA-Z0-9][a-zA-Z0-9_.-]*$ ]]; then
    echo "Invalid container name: $CONTAINER_NAME. Exiting." | tee -a \$LOG_FILE
    exit 1
fi

{
    echo "Starting remote script execution at \$(date)"
    podman build -t $CONTAINER_NAME .
    podman run -d --name $CONTAINER_NAME $CONTAINER_NAME
    echo "Remote script executed successfully."
} >> \$LOG_FILE 2>> \$ERROR_LOG_FILE

# Clean up the script file if successful
if [ \$? -eq 0 ]; then
    rm -f $REMOTE_SCRIPT_DIR/$SCRIPT_NAME
else
    echo "Script execution failed. Logs are saved at \$LOG_FILE and \$ERROR_LOG_FILE."
    exit 1
fi
EOF

# Step 6: Transfer and execute the script on the flux-server
scp -q $SCRIPT_NAME $SERVER_USER@$CONNECTED_SERVER:"$REMOTE_SCRIPT_DIR/" 2>> $ERROR_LOG_FILE
ssh $SERVER_USER@$CONNECTED_SERVER "bash $REMOTE_SCRIPT_DIR/$SCRIPT_NAME" 2>> $ERROR_LOG_FILE

# Step 7: Check if the SSH command was successful
if [ $? -eq 0 ]; then
    echo "$(get_message "execution_success")" | tee -a $LOG_FILE
    rm -f $SCRIPT_NAME  # Clean up the local script file
else
    echo "$(get_message "execution_failure")" | tee -a $LOG_FILE
    echo "$(get_message "error_notify" | sed "s@{local_log_dir}@$LOCAL_LOG_DIR@; s@{remote_log_dir}@$REMOTE_LOG_DIR@")" | tee -a $LOG_FILE
    echo "Subject: Script Execution Error" | sendmail -v "$PHONE_NUMBER@$EMAIL" < $ERROR_LOG_FILE
    exit 1
fi

# Step 8: Clean up local script file
rm -f $SCRIPT_NAME

