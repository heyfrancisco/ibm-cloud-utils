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
            eval "$delete_command --id \"$resource\" -f"
            sleep 2
        done
    fi
}

# Delete Schematic Instances
echo -e "\n$separator\n🚨 Deleting Schematic Instances\n$separator"
schematic_instances=$(ibmcloud schematics workspace list -o JSON | jq -r '.workspaces[].id')
delete_resources "$schematic_instances" "Schematic instance" "ibmcloud schematics workspace delete"

# Verify no remaining Schematic instances
echo -e "\n$separator\n✅ Verification of remaining Schematic Instances\n$separator"
ibmcloud schematics workspace list
