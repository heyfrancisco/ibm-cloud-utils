#!/bin/bash

separator="========================================="

# General delete function
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

# Wait for resource deletion completion
wait_for_deletion() {
    local resource_type=$1
    local resource_id=$2
    local check_command=$3
    local status

    echo "⏳ Waiting for deletion of $resource_type: $resource_id"
    while true; do
        status=$(eval "$check_command $resource_id --output json")
        if [ -z "$status" ] || [ "$status" == "null" ]; then
            echo "✅ $resource_type deleted: $resource_id"
            break
        else
            echo "   Still waiting for deletion... (sleeping 7s)"
            sleep 7
        fi
    done
}

# Delete VPN Gateways first
echo -e "\n$separator\n🚨 Deleting VPN Gateways\n$separator"
vpn_gateways=$(ibmcloud is vpn-gateways --output json | jq -r '.[].id')

if [ -z "$vpn_gateways" ]; then
    echo "✅ No VPN gateways to delete."
else
    for vpn_id in $vpn_gateways; do
        echo "🗑️ Deleting VPN gateway: $vpn_id"
        ibmcloud is vpn-gateway-delete "$vpn_id" -f
        wait_for_deletion "VPN gateway" "$vpn_id" "ibmcloud is vpn-gateway"
    done
fi

# Delete Load Balancers
echo -e "\n$separator\n🚨 Deleting Load Balancers\n$separator"
load_balancers=$(ibmcloud is load-balancers --output json | jq -r '.[].id')
delete_resources "$load_balancers" "load balancer" "ibmcloud is load-balancer-delete"

# Delete VPC Instances
echo -e "\n$separator\n🚨 Deleting VPC Instances\n$separator"
instances=$(ibmcloud is instances --output json | jq -r '.[].id')
if [ -z "$instances" ]; then
    echo "✅ No instances to delete."
else
    for instance in $instances; do
        echo "🗑️ Deleting instance: $instance"
        ibmcloud is instance-delete "$instance" -f
        wait_for_deletion "instance" "$instance" "ibmcloud is instance"
    done
fi

# Delete Block Storage Volumes (after instances are deleted)
echo -e "\n$separator\n🚨 Deleting Block Storage Volumes\n$separator"
block_volumes=$(ibmcloud is volumes --output json | jq -r '.[].id')
delete_resources "$block_volumes" "block storage volume" "ibmcloud is volume-delete"

# Delete File Storage Volumes
echo -e "\n$separator\n🚨 Deleting File Storage Volumes\n$separator"
file_volumes=$(ibmcloud is shares --output json | jq -r '.[].id')
delete_resources "$file_volumes" "file storage volume" "ibmcloud is share-delete"

# Detach Public Gateways from Subnets
echo -e "\n$separator\n🚨 Detaching Public Gateways from Subnets\n$separator"
attached_subnets=$(ibmcloud is subnets --output json | jq -c '.[] | select(.public_gateway!=null) | {id: .id}')

if [ -z "$attached_subnets" ]; then
    echo "✅ No public gateways to detach."
else
    echo "$attached_subnets" | jq -c '.' | while read -r subnet; do
        subnet_id=$(echo "$subnet" | jq -r '.id')
        echo "🔗 Detaching public gateway from subnet $subnet_id"
        ibmcloud is subnet-update "$subnet_id" --pgw ""
        sleep 2
    done
fi

# Delete Floating IPs
echo -e "\n$separator\n🚨 Deleting Floating IPs\n$separator"
fips=$(ibmcloud is floating-ips --output json | jq -r '.[].id')
delete_resources "$fips" "floating IP" "ibmcloud is floating-ip-release"

# Delete Subnets (after instances and gateways are detached)
echo -e "\n$separator\n🚨 Deleting Subnets\n$separator"
subnets=$(ibmcloud is subnets --output json | jq -r '.[].id')
if [ -z "$subnets" ]; then
    echo "✅ No subnets to delete."
else
    for subnet in $subnets; do
        echo "🗑️ Deleting subnet: $subnet"
        ibmcloud is subnet-delete "$subnet" -f
        wait_for_deletion "subnet" "$subnet" "ibmcloud is subnet"
    done
fi

# Delete Public Gateways
echo -e "\n$separator\n🚨 Deleting Public Gateways\n$separator"
gateways=$(ibmcloud is public-gateways --output json | jq -r '.[].id')
delete_resources "$gateways" "public gateway" "ibmcloud is public-gateway-delete"

# Delete Custom Images
echo -e "\n$separator\n🚨 Deleting Custom Images\n$separator"
images=$(ibmcloud is images --visibility private --output json | jq -r '.[].id')
delete_resources "$images" "custom image" "ibmcloud is image-delete"

# Delete VPCs (after all dependent resources are deleted)
echo -e "\n$separator\n🚨 Deleting VPCs\n$separator"
vpcs=$(ibmcloud is vpcs --output json | jq -r '.[].id')
if [ -z "$vpcs" ]; then
    echo "✅ No VPCs to delete."
else
    for vpc in $vpcs; do
        echo "🗑️ Deleting VPC: $vpc"
        ibmcloud is vpc-delete "$vpc" -f
        wait_for_deletion "VPC" "$vpc" "ibmcloud is vpc"
    done
fi

# Verify remaining resources
echo -e "\n$separator\n✅ Verification of remaining VPC resources\n$separator"
ibmcloud is vpcs
