#!/bin/sh

# Load configuration from JSON files
SSH_CONFIG_FILE="config/ssh_config.json"
SCRIPT_CONFIG_FILE="config/script_config.json"
MESSAGES_FILE="config/messages_en.json"

# Function to read JSON values using `awk` for POSIX compliance
read_json() {
  awk -v key="$1" 'BEGIN {FS="""} $2 == key {getline; print $4}' "$2"
}

# Function to read messages from I18n JSON
get_message() {
  awk -v key="$1" 'BEGIN {FS="""} $2 == key {getline; getline; getline; print $4}' "$MESSAGES_FILE"
}

# Load SSH configuration
SERVER_USER=$(read_json "server_user" "$SSH_CONFIG_FILE")
SERVER_ADDRESSES=$(awk -F'["]' '/server_addresses/ {getline; while ($0 !~ /^\]/) {gsub(/,|"/,""); print $2; getline}}' "$SSH_CONFIG_FILE")

# Load script configuration
REPO_DIR=$(read_json "repo_dir" "$SCRIPT_CONFIG_FILE")
REMOTE_SCRIPT_DIR=$(read_json "remote_script_dir" "$SCRIPT_CONFIG_FILE")
REMOTE_LOG_DIR=$(read_json "remote_log_dir" "$SCRIPT_CONFIG_FILE")
LOCAL_LOG_DIR=$(read_json "local_log_dir" "$SCRIPT_CONFIG_FILE")
SCRIPT_NAME=$(read_json "script_name" "$SCRIPT_CONFIG_FILE")
PHONE_NUMBER=$(read_json "phone_number" "$SCRIPT_CONFIG_FILE")
EMAIL=$(read_json "email" "$SCRIPT_CONFIG_FILE")

DATE=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$LOCAL_LOG_DIR/execution_$DATE.log"
ERROR_LOG_FILE="$LOCAL_LOG_DIR/error_$DATE.log"

# Step 1: Ensure script is run from the base of the git repo
cd "$(git rev-parse --show-toplevel)" || exit 1

# Step 2: Check if the local repository is in sync with GitHub
git fetch origin "$GITHUB_BRANCH"
LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse "origin/$GITHUB_BRANCH")
BASE=$(git merge-base @ "origin/$GITHUB_BRANCH")

if [ "$LOCAL" = "$REMOTE" ]; then
    echo "$(get_message "repo_in_sync")" | tee -a "$LOG_FILE"
elif [ "$LOCAL" = "$BASE" ]; then
    echo "$(get_message "repo_behind")" | tee -a "$LOG_FILE"
    printf "Do you want to continue running the script on the server (y/n)? "
    read REPLY
    if [ "$REPLY" != "y" ] && [ "$REPLY" != "Y" ]; then
        exit 1
    fi
elif [ "$REMOTE" = "$BASE" ]; then
    echo "$(get_message "repo_ahead")" | tee -a "$LOG_FILE"
    printf "Do you want to continue running the script on the server (y/n)? "
    read REPLY
    if [ "$REPLY" != "y" ] && [ "$REPLY" != "Y" ]; then
        exit 1
    fi
else
    echo "$(get_message "repo_diverged")" | tee -a "$LOG_FILE"
    printf "Do you want to continue running the script on the server (y/n)? "
    read REPLY
    if [ "$REPLY" != "y" ] && [ "$REPLY" != "Y" ]; then
        exit 1
    fi
fi

# Step 3: Try to connect to one of the server addresses
CONNECTED_SERVER=""
for SERVER_ADDRESS in $SERVER_ADDRESSES; do
    echo "$(get_message "ssh_connecting" | awk -v server="$SERVER_ADDRESS" '{gsub(/{server}/, server); print}')" | tee -a "$LOG_FILE"
    if ssh -q -o ConnectTimeout=5 "$SERVER_USER@$SERVER_ADDRESS" exit; then
        CONNECTED_SERVER=$SERVER_ADDRESS
        echo "$(get_message "ssh_connected" | awk -v server="$CONNECTED_SERVER" '{gsub(/{server}/, server); print}')" | tee -a "$LOG_FILE"
        break
    fi
done

if [ -z "$CONNECTED_SERVER" ]; then
    echo "$(get_message "ssh_failed")" | tee -a "$LOG_FILE"
    exit 1
fi

# Step 4: Prepare the script content to be run on the remote server
cat << EOF > "$SCRIPT_NAME"
#!/bin/sh

# Variables
LOG_FILE="$REMOTE_LOG_DIR/execution_$DATE.log"
ERROR_LOG_FILE="$REMOTE_LOG_DIR/error_$DATE.log"

# Ensure directories exist
mkdir -p "$REMOTE_SCRIPT_DIR"
mkdir -p "$REMOTE_LOG_DIR"

{
    echo "Starting remote script execution at \$(date)"
    # Your script logic here, for example:
    # podman build -t $CONTAINER_NAME .
    # podman run -d --name $CONTAINER_NAME $CONTAINER_NAME
    echo "Remote script executed successfully."
} >> \$LOG_FILE 2>> \$ERROR_LOG_FILE

# Clean up the script file if successful
if [ \$? -eq 0 ]; then
    rm -f "$REMOTE_SCRIPT_DIR/$SCRIPT_NAME"
else
    echo "Script execution failed. Logs are saved at \$LOG_FILE and \$ERROR_LOG_FILE."
    exit 1
fi
EOF

# Step 5: Transfer and execute the script on the flux-server
scp -q "$SCRIPT_NAME" "$SERVER_USER@$CONNECTED_SERVER:$REMOTE_SCRIPT_DIR/" 2>> "$ERROR_LOG_FILE"
ssh "$SERVER_USER@$CONNECTED_SERVER" "sh $REMOTE_SCRIPT_DIR/$SCRIPT_NAME" 2>> "$ERROR_LOG_FILE"

# Step 6: Check if the SSH command was successful
if [ $? -eq 0 ]; then
    echo "$(get_message "execution_success")" | tee -a "$LOG_FILE"
    rm -f "$SCRIPT_NAME"  # Clean up the local script file
else
    echo "$(get_message "execution_failure")" | tee -a "$LOG_FILE"
    echo "$(get_message "error_notify" | awk -v local_log_dir="$LOCAL_LOG_DIR" -v remote_log_dir="$REMOTE_LOG_DIR" '{gsub(/{local_log_dir}/, local_log_dir); gsub(/{remote_log_dir}/, remote_log_dir); print}')" | tee -a "$LOG_FILE"
    echo "Subject: Script Execution Error" | sendmail -v "$PHONE_NUMBER@$EMAIL" < "$ERROR_LOG_FILE"
    exit 1
fi

# Step 7: Clean up local script file
rm -f "$SCRIPT_NAME"
