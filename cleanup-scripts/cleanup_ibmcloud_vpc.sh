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
        for resource in $resources; do
            echo "🗑️ Deleting $resource_name: $resource"
            eval "$delete_command $resource -f"
            sleep 2
        done
    fi
}

# Delete VPC instances
echo -e "\n$separator\n🚨 Deleting VPC Instances\n$separator"
instances=$(ibmcloud is instances --output json | jq -r '.[].id')
delete_resources "$instances" "instance" "ibmcloud is instance-delete"

# Delete Load Balancers
echo -e "\n$separator\n🚨 Deleting Load Balancers\n$separator"
load_balancers=$(ibmcloud is load-balancers --output json | jq -r '.[].id')
delete_resources "$load_balancers" "load balancer" "ibmcloud is load-balancer-delete"

# Delete Floating IPs
echo -e "\n$separator\n🚨 Deleting Floating IPs\n$separator"
fips=$(ibmcloud is floating-ips --output json | jq -r '.[].id')
delete_resources "$fips" "floating IP" "ibmcloud is floating-ip-release"

# Detach Public Gateways from Subnets
echo -e "\n$separator\n🚨 Detaching Public Gateways from Subnets\n$separator"
subnets=$(ibmcloud is subnets --output json | jq -c '.[] | select(.public_gateway!=null) | {id: .id, gateway: .public_gateway.id}')
if [ -z "$subnets" ]; then
    echo "✅ No public gateways to detach."
else
    echo "$subnets" | jq -c '.' | while read -r subnet; do
        subnet_id=$(echo "$subnet" | jq -r '.id')
        gateway_id=$(echo "$subnet" | jq -r '.gateway')
        echo "🔗 Detaching gateway $gateway_id from subnet $subnet_id"
        ibmcloud is subnet-update "$subnet_id" --pgw ""
        sleep 2
    done
fi

# Delete Public Gateways
echo -e "\n$separator\n🚨 Deleting Public Gateways\n$separator"
gateways=$(ibmcloud is public-gateways --output json | jq -r '.[].id')
delete_resources "$gateways" "public gateway" "ibmcloud is public-gateway-delete"

# Delete Subnets
echo -e "\n$separator\n🚨 Deleting Subnets\n$separator"
subnets=$(ibmcloud is subnets --output json | jq -r '.[].id')
delete_resources "$subnets" "subnet" "ibmcloud is subnet-delete"

# Delete VPCs
echo -e "\n$separator\n🚨 Deleting VPCs\n$separator"
vpcs=$(ibmcloud is vpcs --output json | jq -r '.[].id')
delete_resources "$vpcs" "VPC" "ibmcloud is vpc-delete"

# Delete Block Storage
echo -e "\n$separator\n🚨 Deleting Block Storage Instances\n$separator"
block_volumes=$(ibmcloud is volumes --output json | jq -r '.[].id')
delete_resources "$block_volumes" "block storage volume" "ibmcloud is volume-delete"

# Delete File Storage
echo -e "\n$separator\n🚨 Deleting File Storage Instances\n$separator"
file_volumes=$(ibmcloud is shares --output json | jq -r '.[].id')
delete_resources "$file_volumes" "file storage volume" "ibmcloud is share-delete"

# Delete Custom Images
echo -e "\n$separator\n🚨 Deleting Custom Images\n$separator"
images=$(ibmcloud is images --visibility private --output json | jq -r '.[].id')
delete_resources "$images" "custom image" "ibmcloud is image-delete"

# Verify no remaining resources
echo -e "\n$separator\n✅ Verification of remaining VPC resources\n$separator"
ibmcloud is vpcs
