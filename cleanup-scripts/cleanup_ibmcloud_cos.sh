#!/bin/bash

# Visual separators
separator="========================================="

# Function to handle resource deletion
delete_resources() {
    local resources="$1"
    local resource_name="$2"
    local delete_command="$3"

    if [ -z "$resources" ]; then
        echo "✅ No $resource_name to delete."
    else
        echo "$resources" | while IFS= read -r resource; do
            echo "🗑️ Deleting $resource_name: $resource"
            eval "$delete_command \"$resource\" --force --recursive"
            sleep 2
        done
    fi
}

# Delete COS Service Instances
echo -e "\n$separator\n🚨 Deleting COS Service Instances\n$separator"
cos_instances=$(ibmcloud resource service-instances --service-name cloud-object-storage --output json | jq -r '.[].name')
delete_resources "$cos_instances" "COS service instance" "ibmcloud resource service-instance-delete"

# Verify no remaining COS resources
echo -e "\n$separator\n✅ Verification of remaining COS Service Instances\n$separator"
ibmcloud resource service-instances --service-name cloud-object-storage