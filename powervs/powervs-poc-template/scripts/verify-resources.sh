#!/bin/bash
##############################################################################
# Resource Verification Script
#
# This script verifies that all deployed resources exist and are in the
# expected state.
#
# Usage: ./scripts/verify-resources.sh
##############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "IBM Cloud Landing Zone - Resource Verification"
echo "=========================================="
echo ""

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}ERROR: Terraform is not installed${NC}"
    exit 1
fi

# Check if IBM Cloud CLI is installed
if ! command -v ibmcloud &> /dev/null; then
    echo -e "${RED}ERROR: IBM Cloud CLI is not installed${NC}"
    exit 1
fi

# Check if logged in to IBM Cloud
if ! ibmcloud target &> /dev/null; then
    echo -e "${RED}ERROR: Not logged in to IBM Cloud${NC}"
    echo "Run: ibmcloud login --apikey \$IC_API_KEY"
    exit 1
fi

echo -e "${GREEN}✓${NC} Prerequisites check passed"
echo ""

# Get Terraform outputs
echo "Retrieving Terraform outputs..."
if ! terraform output &> /dev/null; then
    echo -e "${RED}ERROR: No Terraform state found${NC}"
    echo "Run 'terraform apply' first"
    exit 1
fi

# Verify VPC
echo ""
echo "Verifying VPC resources..."
VPC_ID=$(terraform output -raw vpc_id 2>/dev/null || echo "")
if [ -n "$VPC_ID" ]; then
    if ibmcloud is vpc "$VPC_ID" &> /dev/null; then
        echo -e "${GREEN}✓${NC} VPC exists: $VPC_ID"
    else
        echo -e "${RED}✗${NC} VPC not found: $VPC_ID"
    fi
else
    echo -e "${YELLOW}⊘${NC} VPC ID not found in outputs"
fi

# Verify Subnets
SUBNET_IDS=$(terraform output -json subnet_ids 2>/dev/null | jq -r '.[]' 2>/dev/null || echo "")
if [ -n "$SUBNET_IDS" ]; then
    for subnet_id in $SUBNET_IDS; do
        if ibmcloud is subnet "$subnet_id" &> /dev/null; then
            echo -e "${GREEN}✓${NC} Subnet exists: $subnet_id"
        else
            echo -e "${RED}✗${NC} Subnet not found: $subnet_id"
        fi
    done
else
    echo -e "${YELLOW}⊘${NC} No subnets found in outputs"
fi

# Verify Security Groups
SG_IDS=$(terraform output -json security_group_ids 2>/dev/null | jq -r '.[]' 2>/dev/null || echo "")
if [ -n "$SG_IDS" ]; then
    for sg_id in $SG_IDS; do
        if ibmcloud is security-group "$sg_id" &> /dev/null; then
            echo -e "${GREEN}✓${NC} Security Group exists: $sg_id"
        else
            echo -e "${RED}✗${NC} Security Group not found: $sg_id"
        fi
    done
else
    echo -e "${YELLOW}⊘${NC} No security groups found in outputs"
fi

# Verify VPN Gateway (if deployed)
echo ""
echo "Verifying VPN resources..."
VPN_GW_ID=$(terraform output -raw vpn_gateway_id 2>/dev/null || echo "")
if [ -n "$VPN_GW_ID" ]; then
    if ibmcloud is vpn-gateway "$VPN_GW_ID" &> /dev/null; then
        echo -e "${GREEN}✓${NC} VPN Gateway exists: $VPN_GW_ID"
    else
        echo -e "${RED}✗${NC} VPN Gateway not found: $VPN_GW_ID"
    fi
else
    echo -e "${YELLOW}⊘${NC} VPN Gateway not deployed (optional)"
fi

# Verify COS Instance
echo ""
echo "Verifying Cloud Object Storage..."
COS_INSTANCE_ID=$(terraform output -raw cos_instance_id 2>/dev/null || echo "")
if [ -n "$COS_INSTANCE_ID" ]; then
    if ibmcloud resource service-instance "$COS_INSTANCE_ID" &> /dev/null; then
        echo -e "${GREEN}✓${NC} COS Instance exists: $COS_INSTANCE_ID"
    else
        echo -e "${RED}✗${NC} COS Instance not found: $COS_INSTANCE_ID"
    fi
else
    echo -e "${YELLOW}⊘${NC} COS Instance ID not found in outputs"
fi

# Verify PowerVS Workspace
echo ""
echo "Verifying PowerVS resources..."
POWERVS_WORKSPACE_ID=$(terraform output -raw pi_workspace_id 2>/dev/null || echo "")
if [ -n "$POWERVS_WORKSPACE_ID" ]; then
    echo -e "${GREEN}✓${NC} PowerVS Workspace ID found: $POWERVS_WORKSPACE_ID"
    # Note: PowerVS CLI commands require workspace context
else
    echo -e "${YELLOW}⊘${NC} PowerVS Workspace ID not found in outputs"
fi

# Verify PowerVS Instance
POWERVS_INSTANCE_ID=$(terraform output -raw pi_instance_id 2>/dev/null || echo "")
if [ -n "$POWERVS_INSTANCE_ID" ]; then
    echo -e "${GREEN}✓${NC} PowerVS Instance ID found: $POWERVS_INSTANCE_ID"
else
    echo -e "${YELLOW}⊘${NC} PowerVS Instance ID not found in outputs"
fi

# Verify Transit Gateway
echo ""
echo "Verifying Transit Gateway..."
TG_ID=$(terraform output -raw tg_id 2>/dev/null || echo "")
if [ -n "$TG_ID" ]; then
    if ibmcloud tg gateway "$TG_ID" &> /dev/null; then
        echo -e "${GREEN}✓${NC} Transit Gateway exists: $TG_ID"
    else
        echo -e "${RED}✗${NC} Transit Gateway not found: $TG_ID"
    fi
else
    echo -e "${YELLOW}⊘${NC} Transit Gateway ID not found in outputs"
fi

# Verify VPE Gateway
echo ""
echo "Verifying VPE Gateway..."
VPE_IPS=$(terraform output -json vpe_ips 2>/dev/null | jq -r '.[]' 2>/dev/null || echo "")
if [ -n "$VPE_IPS" ]; then
    echo -e "${GREEN}✓${NC} VPE Gateway IPs found"
    for ip in $VPE_IPS; do
        echo "  - $ip"
    done
else
    echo -e "${YELLOW}⊘${NC} VPE Gateway IPs not found in outputs"
fi

echo ""
echo "=========================================="
echo "Resource verification complete"
echo "=========================================="
echo ""
echo "Legend:"
echo -e "${GREEN}✓${NC} - Resource exists and is accessible"
echo -e "${RED}✗${NC} - Resource not found or inaccessible"
echo -e "${YELLOW}⊘${NC} - Resource not deployed or optional"
echo ""

# Made with Bob
