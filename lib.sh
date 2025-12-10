#!/bin/bash

################################################################################
# lib.sh - Shared Utility Functions for Digital Ocean Scripts
#
# This library provides common utility functions used by create-server.sh and
# delete-server.sh scripts. Include this file in your scripts using:
#   source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
#
# Created: 2025-12-10
################################################################################

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

################################################################################
# Logging Functions
################################################################################

# Print an info message
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

# Print a success message
log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

# Print a warning message
log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

# Print an error message
log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

# Exit with an error message
die() {
    log_error "$@"
    exit 1
}

################################################################################
# Validation Functions
################################################################################

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if required commands are available
check_required_commands() {
    local missing_commands=()
    
    for cmd in "$@"; do
        if ! command_exists "$cmd"; then
            missing_commands+=("$cmd")
        fi
    done
    
    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        log_error "Missing required commands: ${missing_commands[*]}"
        return 1
    fi
    
    return 0
}

# Validate that a variable is not empty
require_var() {
    local var_name="$1"
    local var_value="$2"
    
    if [[ -z "$var_value" ]]; then
        die "Required variable '$var_name' is not set"
    fi
}

# Validate that a value is numeric
is_numeric() {
    [[ "$1" =~ ^[0-9]+$ ]]
}

# Validate that a value is a valid IP address
is_valid_ip() {
    local ip="$1"
    local regex='^([0-9]{1,3}\.){3}[0-9]{1,3}$'
    
    if [[ $ip =~ $regex ]]; then
        # Check if octets are valid (0-255)
        local IFS='.'
        local -a octets=($ip)
        for octet in "${octets[@]}"; do
            if (( octet > 255 )); then
                return 1
            fi
        done
        return 0
    fi
    
    return 1
}

################################################################################
# Digital Ocean API Functions
################################################################################

# Check if DO_TOKEN environment variable is set
check_do_token() {
    if [[ -z "$DO_TOKEN" ]]; then
        die "DO_TOKEN environment variable is not set. Please set your Digital Ocean API token."
    fi
    log_info "Digital Ocean API token is configured"
}

# Make a GET request to Digital Ocean API
do_api_get() {
    local endpoint="$1"
    
    require_var "endpoint" "$endpoint"
    
    curl -s -X GET \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $DO_TOKEN" \
        "https://api.digitalocean.com/v2${endpoint}"
}

# Make a POST request to Digital Ocean API
do_api_post() {
    local endpoint="$1"
    local data="$2"
    
    require_var "endpoint" "$endpoint"
    require_var "data" "$data"
    
    curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $DO_TOKEN" \
        -d "$data" \
        "https://api.digitalocean.com/v2${endpoint}"
}

# Make a DELETE request to Digital Ocean API
do_api_delete() {
    local endpoint="$1"
    
    require_var "endpoint" "$endpoint"
    
    curl -s -X DELETE \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $DO_TOKEN" \
        "https://api.digitalocean.com/v2${endpoint}"
}

# Check if a response contains an error
is_api_error() {
    local response="$1"
    
    echo "$response" | grep -q '"id":"unauthorized"'
    echo "$response" | grep -q '"id":"not_found"'
    echo "$response" | grep -q '"message":"'
}

################################################################################
# Server Management Functions
################################################################################

# Get server ID by name
get_server_id() {
    local server_name="$1"
    
    require_var "server_name" "$server_name"
    
    local response
    response=$(do_api_get "/droplets?name=$server_name")
    
    echo "$response" | grep -o '"id":[0-9]*' | head -1 | grep -o '[0-9]*'
}

# Check if server exists
server_exists() {
    local server_name="$1"
    local server_id
    
    require_var "server_name" "$server_name"
    
    server_id=$(get_server_id "$server_name")
    
    if [[ -n "$server_id" && "$server_id" =~ ^[0-9]+$ ]]; then
        return 0
    fi
    
    return 1
}

# Wait for server status with timeout
wait_for_server_status() {
    local server_id="$1"
    local target_status="$2"
    local timeout="${3:-300}" # Default 5 minutes
    local check_interval="${4:-10}" # Default 10 seconds
    local elapsed=0
    
    require_var "server_id" "$server_id"
    require_var "target_status" "$target_status"
    
    log_info "Waiting for server $server_id to reach status: $target_status"
    
    while (( elapsed < timeout )); do
        local response
        response=$(do_api_get "/droplets/$server_id")
        
        local current_status
        current_status=$(echo "$response" | grep -o '"status":"[^"]*' | grep -o '[^"]*$')
        
        if [[ "$current_status" == "$target_status" ]]; then
            log_success "Server reached status: $target_status"
            return 0
        fi
        
        log_info "Current status: $current_status (elapsed: ${elapsed}s/${timeout}s)"
        sleep "$check_interval"
        (( elapsed += check_interval ))
    done
    
    log_warn "Timeout waiting for server status $target_status after ${timeout}s"
    return 1
}

################################################################################
# Utility Functions
################################################################################

# Print a separator line
print_separator() {
    echo "================================================================================"
}

# Confirm an action with user
confirm() {
    local prompt="$1"
    local response
    
    read -p "$(echo -e ${YELLOW}${prompt}${NC}) (yes/no): " response
    
    case "$response" in
        yes|YES|y|Y) return 0 ;;
        *) return 1 ;;
    esac
}

# Get current timestamp
get_timestamp() {
    date "+%Y-%m-%d %H:%M:%S"
}

# Export functions for subshells
export -f log_info log_success log_warn log_error die
export -f command_exists check_required_commands require_var
export -f is_numeric is_valid_ip
export -f check_do_token do_api_get do_api_post do_api_delete is_api_error
export -f get_server_id server_exists wait_for_server_status
export -f print_separator confirm get_timestamp
