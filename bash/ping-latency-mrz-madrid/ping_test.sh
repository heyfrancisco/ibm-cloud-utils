#!/bin/bash

# Define a function to perform ping and extract relevant information
ping_and_log() {
    local destination=$1
    local label=$2
    echo "Starting ping from Lisbon to $label..."
    echo -e "\nFrom Lisbon to $label"
    ping -c 15 $destination 2>&1 | egrep "round"
    echo "Ping to $label completed."
}

# Main logging function
log_performance() {
    local log_file="lisboa.log"
    echo "Starting log performance check..."
    {
        date
        ping_and_log "s3.eu-es.cloud-object-storage.appdomain.cloud" "Madrid"
        ping_and_log "s3.eu-de.cloud-object-storage.appdomain.cloud" "Frankfurt"
        echo -e "\n"
    } >> "$log_file"
    
    echo "Log performance check completed and saved to $log_file."
}

# Call the main function to execute the script
log_performance
