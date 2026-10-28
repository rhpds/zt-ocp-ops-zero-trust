#!/bin/bash
# Inject environment variables into antora.yml for Showroom workshop

set -e

ANTORA_YML="/showroom/repo/content/antora.yml"

if [ ! -f "$ANTORA_YML" ]; then
    echo "ERROR: antora.yml not found at $ANTORA_YML"
    exit 1
fi

echo "Injecting environment variables into $ANTORA_YML"

# Create a backup
cp "$ANTORA_YML" "${ANTORA_YML}.bak"

# Read environment variables from /user_data/ if available
if [ -d "/user_data" ]; then
    echo "Reading environment variables from /user_data/"

    # Source all environment variable files
    for env_file in /user_data/*.env 2>/dev/null; do
        if [ -f "$env_file" ]; then
            echo "Sourcing $env_file"
            set -a
            source "$env_file"
            set +a
        fi
    done
fi

# Inject asciidoc attributes section if it doesn't exist
if ! grep -q "^  attributes:" "$ANTORA_YML"; then
    # Add attributes section before the start-page line
    sed -i '/^  start_page:/i\  attributes:' "$ANTORA_YML"
fi

# Common workshop variables to inject
VARS_TO_INJECT=(
    "GUID"
    "ADMIN_PASSWORD"
    "BASTION_FQDN"
    "API_URL"
    "MASTER_URL"
    "MODULE_ENABLE_ZTWIM"
)

# Inject each variable if it exists in the environment
for var in "${VARS_TO_INJECT[@]}"; do
    value="${!var}"
    if [ -n "$value" ]; then
        # Check if attribute already exists
        if grep -q "^    $var:" "$ANTORA_YML"; then
            # Update existing attribute
            sed -i "s|^    $var:.*|    $var: '$value'|" "$ANTORA_YML"
        else
            # Add new attribute after the attributes: line
            sed -i "/^  attributes:/a\    $var: '$value'" "$ANTORA_YML"
        fi
        echo "Injected $var"
    fi
done

echo "Environment variable injection complete"
