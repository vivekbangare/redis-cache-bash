#!/bin/bash

# Log file
LOG_FILE="redis_script.log"

# Function to log messages
log() {
    local message=$1
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $message" >> "$LOG_FILE"
}

# Function to display help message
display_help() {
    echo "Usage: $0 [OPTION]"
    echo "Script to interact with Redis server"
    echo
    echo "Options:"
    echo "  --help, -h      Display this help message"
    echo
    echo "Commands:"
    echo "  -a, --add KEY VALUE    Add a new key-value pair to the Redis server"
    echo "  -g, --get KEY          Retrieve the value of a key from the Redis server"
    echo "  -m, --modify KEY VALUE Modify an existing key-value pair on the Redis server"
    echo "  -d, --delete KEY       Delete a key-value pair from the Redis server"
    echo "  -db, --delete-bulk KEY Remove keys matching a pattern from Redis"
    echo "  -s, --server SERVER    Specify the Redis server (default: localhost)"
    echo "  -p, --port PORT        Specify the Redis server port (default: 6379)"
    echo "  Exit:                  Exits the script"
    echo
    echo "Examples:"
    echo "  $0 --add mykey myvalue"
    echo "  $0 --get mykey"
    echo "  $0 --modify mykey newvalue"
    echo "  $0 --delete mykey"
    exit 0
}

# Function to test the connection to Redis
test_redis_connection() {
    local test_result=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" -a "$REDIS_PASSWORD" PING)

    if [ "$test_result" != "PONG" ]; then
        echo "Failed to connect to Redis server. Please check your connection settings."
        exit 1
    fi
}

# Default values
SERVER="localhost"
PORT="6379"

# Check for help option
if [[ $1 == "--help" || $1 == "-h" ]]; then
    display_help
fi

# Prompt for Redis server details
read -p "Enter Redis host [localhost]: " REDIS_HOST
REDIS_HOST=${REDIS_HOST:-localhost}

read -p "Enter Redis port [6379]: " REDIS_PORT
REDIS_PORT=${REDIS_PORT:-6379}

read -sp "Enter Redis password: " REDIS_PASSWORD
REDIS_PASSWORD=${REDIS_PASSWORD}

# Test the connection to Redis
test_redis_connection

# Function to connect to Redis and perform operations
redis_cli() {
    if [ -z "$REDIS_PASSWORD" ]; then
        redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" "$@"
    else
        redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" -a "$REDIS_PASSWORD" --no-auth-warning "$@"
    fi
}

# Function to delete a key-value pair
delete_data() {
    local key=$1
    local value=$(redis_cli GET "$key")

    echo "Dry run: Key '$key' with value '$value' will be deleted"
    read -p "Are you sure you want to delete this data? (yes/no): " choice
    case $choice in
        yes|YES|y|Y)
            redis_cli DEL "$key"
            echo "Data removed. Key: $key, Value: $value"
            log "Removed data | key: $key"
            ;;
        *)
            echo "Deletion canceled."
            ;;
    esac
}

# Function to delete keys in bulk
delete_bulk() {
    local pattern=$1
    keys=$(redis_cli KEYS "$pattern")
    if [ -z "$keys" ]; then
        echo "No keys found for pattern: $pattern"
        log "No keys found for pattern: $pattern"
        return
    fi

    if [ "$DRY_RUN" = true ]; then
        echo "Dry run: Keys matching pattern '$pattern' will be deleted:"
        for key in $keys; do
            value=$(redis_cli GET "$key")
            echo "  Key: $key, Value: $value"
        done
    else
        # Convert keys to array
        keys_array=($keys)

        # Delete keys in bulk
        redis_cli DEL "${keys_array[@]}"
        echo "Deleted keys matching pattern: $pattern"
        log "Deleted keys matching pattern: $pattern"
    fi
}
# Main loop
while true; do
    echo "Choose an option:"
    echo "1) Add data"
    echo "2) Get data"
    echo "3) Modify data"
    echo "4) Remove data"
    echo "5) Remove data in bulk"
    echo "6) Get all data"
    echo "7) Exit"
    read -p "Enter your choice: " choice

    case $choice in
        1)
            read -p "Enter key: " key
            read -p "Enter value: " value
            redis_cli SET "$key" "$value"
            echo "Data added."
            log "Added data | key: $key, value: $value"
            ;;
        2)
            read -p "Enter key to retrieve: " key
            value=$(redis_cli GET "$key")
            echo "Value of '$key': $value"
            log "Retrieved data | key: $key, value: $value"
            ;;
        3)
            read -p "Enter key to modify: " key
            read -p "Enter new value: " value
            redis_cli SET "$key" "$value"
            echo "Data modified."
            log "Modified data | key: $key, new value: $value"
            ;;
        4)
            read -p "Enter key to remove: " key
            delete_data "$key"
            ;;
        5)
            read -p "Enter pattern to delete keys (e.g., user:*): " pattern
            delete_bulk "$pattern"
            ;;
        6)
            # Retrieve all keys
            keys=$(redis-cli KEYS "*")

            # Iterate over each key and retrieve its value
            for key in $keys; do
                value=$(redis-cli GET "$key")
                echo "Key: $key, Value: $value"
            done
            ;;
        7)
            echo "Exiting..."
            log "Exited script"
            break
            ;;
        *)
            echo "Invalid option. Please try again."
            log "Invalid option selected"
            ;;
    esac
done
