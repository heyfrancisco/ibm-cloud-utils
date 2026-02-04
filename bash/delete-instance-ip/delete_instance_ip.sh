#!/bin/bash

function delete_instance_ip() {
	vsi_id=$(ibmcloud is instance --output json |
		jq -r '.[] | select(.primary_network_interface.primary_ip.address == "'"$1"'") | . id')
	if [ -z "$vsi_id" ]; then
		echo "❌ Error: No Virtual Server found with IP Address: $1"
		return 1
	fi
	echo "Found Virtual Server ID: $vsi_id"
	echo "Deleting VSI $vsi_id"
	ibmcloud is instance-delete $vsi_id --force
	echo "✅ VSI $vsi_id deletion initiated."
}
