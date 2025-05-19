#!/bin/bash
# Default to CONFIG_PATH env var if set, otherwise use default path
CONFIG_FILE=${CONFIG_PATH:-/app/config/config.json}
CORE_CONTRACTS_PATH=${CORE_CONTRACTS_PATH:-/app/config/core-contracts.json}

# Debug all arguments
echo "All arguments received: $*"

# Store dump file path if provided
DUMP_FILE=""
for arg in "$@"; do
    echo "Processing argument: $arg"
    if [ "$arg" = "--dump-path" ]; then
        next_is_dump=true
    elif [ "$next_is_dump" = true ]; then
        DUMP_FILE="$arg"
        next_is_dump=false
    fi
done

echo "CONFIG_FILE: $CONFIG_FILE"
echo "CORE_CONTRACTS_PATH: $CORE_CONTRACTS_PATH"
echo "DUMP_FILE: $DUMP_FILE"

# Check if config file exists
if [ -f "$CONFIG_FILE" ]; then
    echo "Loading configuration from $CONFIG_FILE"
    
    # Determine file type and process accordingly
    if [[ "$CONFIG_FILE" == *.json ]]; then
        # Process JSON format
        export $(jq -r 'to_entries | map("\(.key)=\(.value|tostring)") | .[]' "$CONFIG_FILE")
    elif [[ "$CONFIG_FILE" == *.env ]]; then
        # Process .env format
        export $(grep -v '^#' "$CONFIG_FILE" | xargs)
    elif [[ "$CONFIG_FILE" == *.yaml ]] || [[ "$CONFIG_FILE" == *.yml ]]; then
        # Process YAML format (requires yq)
        export $(yq eval -o=json '.' "$CONFIG_FILE" | jq -r 'to_entries | map("\(.key)=\(.value|tostring)") | .[]')
    else
        # Try to detect file type by content
        echo "Warning: Unable to determine config file format for $CONFIG_FILE"
    fi
else
    echo "Warning: Config file not found at $CONFIG_FILE"
fi

# Run the CLI command
if [ $# -gt 0 ]; then
    echo "Running my-application-command with provided arguments"
    pnpm tsx ./scripts/cli.ts "$@" || {
        echo "CLI command failed, but continuing with file updates..."
    }
else
    # No additional arguments provided
    echo "Running pnpm tsx ./scripts/cli.ts without arguments"
    pnpm tsx ./scripts/cli.ts || {
        echo "CLI command failed, but continuing with file updates..."
    }
fi

echo "CLI command completed, proceeding with file updates..."

# After CLI execution, update dump file if it was provided
if [ -n "$DUMP_FILE" ] && [ -f "$DUMP_FILE" ]; then
    echo "Reading dump file $DUMP_FILE"
    echo "Current directory: $(pwd)"
    echo "Directory contents: $(ls -la)"
    echo "Core contracts path: $CORE_CONTRACTS_PATH"
    echo "Directory of core contracts: $(dirname "$CORE_CONTRACTS_PATH")"
    echo "Directory contents of config: $(ls -la /app/config/)"
    
    echo "Reading this contract address from $DUMP_FILE"
    CORE_CONTRACT=$(jq -r '.contracts.l2.appchain' "$DUMP_FILE")
    if [ "$CORE_CONTRACT" == "null" ] || [ -z "$CORE_CONTRACT" ]; then
        echo "Error: Core contract address is null or empty."
        exit 1
    fi
    echo "Found contract address: $CORE_CONTRACT"
    
    # Create the core contracts file if it doesn't exist
    if [ ! -f "$CORE_CONTRACTS_PATH" ]; then
        echo "Creating core contracts file at $CORE_CONTRACTS_PATH"
        mkdir -p "$(dirname "$CORE_CONTRACTS_PATH")"
        echo "{}" > "$CORE_CONTRACTS_PATH"
        echo "Created file. Contents: $(cat "$CORE_CONTRACTS_PATH")"
    fi
    
    # Update the file with the contract address
    echo "Updating core contracts file with address: $CORE_CONTRACT"
    jq ".starknet_contract_address = \"$CORE_CONTRACT\"" "$CORE_CONTRACTS_PATH" > "$CORE_CONTRACTS_PATH.tmp" && mv "$CORE_CONTRACTS_PATH.tmp" "$CORE_CONTRACTS_PATH"

    echo "Updated file. Contents: $(cat "$CORE_CONTRACTS_PATH")"
    echo "Core contracts file updated successfully at $CORE_CONTRACTS_PATH"
else
    echo "Dump file not found or not provided: $DUMP_FILE"
    echo "Current directory: $(pwd)"
    echo "Directory contents: $(ls -la)"
fi