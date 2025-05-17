#!/bin/bash
# Default to CONFIG_PATH env var if set, otherwise use default path
CONFIG_FILE=${CONFIG_PATH:-/app/config/config.json}
CORE_CONTRACTS_PATH=${CORE_CONTRACTS_PATH:-/app/config/core-contracts.json}

# Store dump file path if provided
DUMP_FILE=""
if [ "$1" = "--dump-path" ] && [ -n "$2" ]; then
    DUMP_FILE="$2"
fi

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
    pnpm tsx ./scripts/cli.ts "$@" || exit 1
else
    # No additional arguments provided
    echo "Running pnpm tsx ./scripts/cli.ts without arguments"
    pnpm tsx ./scripts/cli.ts || exit 1
fi

# After CLI execution, update dump file if it was provided
if [ -n "$DUMP_FILE" ] && [ -f "$DUMP_FILE" ]; then
    echo "Reading dump file $DUMP_FILE"
    CORE_CONTRACT=$(jq -r '.contracts.l2.appchain' ./contracts.json)
    if [ "$CORE_CONTRACT" == "null" ] || [ -z "$CORE_CONTRACT" ]; then
        echo "Error: Core contract address is null or empty."
        exit 1
    fi
    echo "Updating dump file with contract addresses..."
    jq -i ".starknet_contract_address = \"$CORE_CONTRACT\"" "$CORE_CONTRACTS_PATH"
fi