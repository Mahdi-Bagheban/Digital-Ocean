#!/bin/bash

# Source the library functions
source "$(dirname "$0")/lib.sh"

# Script to delete a DigitalOcean droplet
# This script uses the shared library for common functions

main() {
    local droplet_id="$1"
    
    # Validate input
    if [[ -z "$droplet_id" ]]; then
        log_error "Usage: $0 <droplet_id>"
        exit 1
    fi
    
    # Check if API token is set
    if [[ -z "$DO_API_TOKEN" ]]; then
        log_error "DO_API_TOKEN environment variable is not set"
        exit 1
    fi
    
    log_info "Attempting to delete droplet with ID: $droplet_id"
    
    # Delete the droplet
    local response=$(curl -s -X DELETE \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $DO_API_TOKEN" \
        "https://api.digitalocean.com/v2/droplets/$droplet_id")
    
    # Check if deletion was successful (DigitalOcean returns 204 No Content on success)
    local http_code=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $DO_API_TOKEN" \
        "https://api.digitalocean.com/v2/droplets/$droplet_id")
    
    if [[ "$http_code" == "204" ]]; then
        log_success "Droplet $droplet_id deleted successfully"
        exit 0
    else
        log_error "Failed to delete droplet. HTTP Status: $http_code"
        log_error "Response: $response"
        exit 1
    fi
}

# Run main function with all arguments
main "$@"
