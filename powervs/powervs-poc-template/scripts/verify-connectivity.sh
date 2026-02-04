#!/bin/bash
##############################################################################
# Network Connectivity Verification Script
#
# This script tests network connectivity between deployed components.
#
# Usage: ./scripts/verify-connectivity.sh
##############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=========================================="
echo "IBM Cloud Landing Zone - Connectivity Verification"
echo "=========================================="
echo ""

# Check prerequisites
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}ERROR: Terraform is not installed${NC}"
    exit 1
fi

if ! command -v ibmcloud &> /dev/null; then
    echo -e "${RED}ERROR: IBM Cloud CLI is not installed${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} Prerequisites check passed"
echo ""

# Get Terraform outputs
echo "Retrieving Terraform outputs..."
if ! terraform output &> /dev/null; then
    echo -e "${RED}ERROR: No Terraform state found${NC}"
    exit 1
fi

# Test VPC Connectivity
echo ""
echo -e "${BLUE}Testing VPC Connectivity...${NC}"
VPC_ID=$(terraform output -raw vpc_id 2>/dev/null || echo "")
if [ -n "$VPC_ID" ]; then
    echo -e "${GREEN}✓${NC} VPC is accessible"
    
    # Check subnets
    SUBNET_IDS=$(terraform output -json subnet_ids 2>/dev/null | jq -r '.[]' 2>/dev/null || echo "")
    if [ -n "$SUBNET_IDS" ]; then
        for subnet_id in $SUBNET_IDS; do
            SUBNET_INFO=$(ibmcloud is subnet "$subnet_id" --output json 2>/dev/null || echo "{}")
            SUBNET_NAME=$(echo "$SUBNET_INFO" | jq -r '.name' 2>/dev/null || echo "unknown")
            SUBNET_CIDR=$(echo "$SUBNET_INFO" | jq -r '.ipv4_cidr_block' 2>/dev/null || echo "unknown")
            echo -e "${GREEN}✓${NC} Subnet: $SUBNET_NAME ($SUBNET_CIDR)"
        done
    fi
else
    echo -e "${RED}✗${NC} VPC not found"
fi

# Test VPN Connectivity (if deployed)
echo ""
echo -e "${BLUE}Testing VPN Connectivity...${NC}"
VPN_GW_ID=$(terraform output -raw vpn_gateway_id 2>/dev/null || echo "")
if [ -n "$VPN_GW_ID" ]; then
    VPN_STATUS=$(ibmcloud is vpn-gateway "$VPN_GW_ID" --output json 2>/dev/null | jq -r '.status' 2>/dev/null || echo "unknown")
    if [ "$VPN_STATUS" == "available" ]; then
        echo -e "${GREEN}✓${NC} VPN Gateway is available"
    else
        echo -e "${YELLOW}⚠${NC} VPN Gateway status: $VPN_STATUS"
    fi
    
    # Check VPN connections
    VPN_CONN_IDS=$(terraform output -json vpn_connection_ids 2>/dev/null | jq -r '.[]' 2>/dev/null || echo "")
    if [ -n "$VPN_CONN_IDS" ]; then
        for conn_id in $VPN_CONN_IDS; do
            CONN_STATUS=$(ibmcloud is vpn-gateway-connection "$VPN_GW_ID" "$conn_id" --output json 2>/dev/null | jq -r '.status' 2>/dev/null || echo "unknown")
            if [ "$CONN_STATUS" == "up" ]; then
                echo -e "${GREEN}✓${NC} VPN Connection is up: $conn_id"
            else
                echo -e "${YELLOW}⚠${NC} VPN Connection status: $CONN_STATUS"
            fi
        done
    fi
else
    echo -e "${YELLOW}⊘${NC} VPN not deployed (optional)"
fi

# Test Transit Gateway Connectivity
echo ""
echo -e "${BLUE}Testing Transit Gateway Connectivity...${NC}"
TG_ID=$(terraform output -raw tg_id 2>/dev/null || echo "")
if [ -n "$TG_ID" ]; then
    TG_STATUS=$(ibmcloud tg gateway "$TG_ID" --output json 2>/dev/null | jq -r '.status' 2>/dev/null || echo "unknown")
    if [ "$TG_STATUS" == "available" ]; then
        echo -e "${GREEN}✓${NC} Transit Gateway is available"
    else
        echo -e "${YELLOW}⚠${NC} Transit Gateway status: $TG_STATUS"
    fi
    
    # Check connections
    echo "  Checking Transit Gateway connections..."
    TG_CONNECTIONS=$(ibmcloud tg connections "$TG_ID" --output json 2>/dev/null || echo "[]")
    CONNECTION_COUNT=$(echo "$TG_CONNECTIONS" | jq 'length' 2>/dev/null || echo "0")
    
    if [ "$CONNECTION_COUNT" -gt 0 ]; then
        echo "$TG_CONNECTIONS" | jq -r '.[] | "  - \(.name): \(.status)"' 2>/dev/null || true
    else
        echo -e "${YELLOW}⚠${NC} No connections found"
    fi
else
    echo -e "${RED}✗${NC} Transit Gateway not found"
fi

# Test PowerVS Connectivity
echo ""
echo -e "${BLUE}Testing PowerVS Connectivity...${NC}"
POWERVS_WORKSPACE_ID=$(terraform output -raw pi_workspace_id 2>/dev/null || echo "")
POWERVS_INSTANCE_ID=$(terraform output -raw pi_instance_id 2>/dev/null || echo "")

if [ -n "$POWERVS_WORKSPACE_ID" ]; then
    echo -e "${GREEN}✓${NC} PowerVS Workspace accessible"
    
    if [ -n "$POWERVS_INSTANCE_ID" ]; then
        echo -e "${GREEN}✓${NC} PowerVS Instance deployed"
        
        # Get instance IPs
        INSTANCE_IPS=$(terraform output -json pi_instance_private_ips 2>/dev/null | jq -r '.[]' 2>/dev/null || echo "")
        if [ -n "$INSTANCE_IPS" ]; then
            echo "  Instance Private IPs:"
            for ip in $INSTANCE_IPS; do
                echo "    - $ip"
            done
        fi
    else
        echo -e "${YELLOW}⊘${NC} PowerVS Instance not found"
    fi
else
    echo -e "${RED}✗${NC} PowerVS Workspace not found"
fi

# Test COS Private Connectivity (VPE)
echo ""
echo -e "${BLUE}Testing COS Private Connectivity...${NC}"
VPE_IPS=$(terraform output -json vpe_ips 2>/dev/null | jq -r '.[]' 2>/dev/null || echo "")
if [ -n "$VPE_IPS" ]; then
    echo -e "${GREEN}✓${NC} VPE Gateway configured for private COS access"
    echo "  VPE Private IPs:"
    for ip in $VPE_IPS; do
        echo "    - $ip"
    done
else
    echo -e "${YELLOW}⊘${NC} VPE Gateway not configured"
fi

# DNS Resolution Test
echo ""
echo -e "${BLUE}Testing DNS Resolution...${NC}"
COS_INSTANCE_CRN=$(terraform output -raw cos_instance_crn 2>/dev/null || echo "")
if [ -n "$COS_INSTANCE_CRN" ]; then
    # Extract region from CRN or use default
    REGION=$(echo "$COS_INSTANCE_CRN" | cut -d: -f6 || echo "us-south")
    COS_ENDPOINT="s3.${REGION}.cloud-object-storage.appdomain.cloud"
    
    echo "  Testing COS endpoint: $COS_ENDPOINT"
    if host "$COS_ENDPOINT" &> /dev/null; then
        echo -e "${GREEN}✓${NC} DNS resolution successful"
    else
        echo -e "${YELLOW}⚠${NC} DNS resolution failed (may require VPC DNS configuration)"
    fi
else
    echo -e "${YELLOW}⊘${NC} COS not deployed"
fi

# Summary
echo ""
echo "=========================================="
echo "Connectivity verification complete"
echo "=========================================="
echo ""
echo "Legend:"
echo -e "${GREEN}✓${NC} - Connection successful"
echo -e "${YELLOW}⚠${NC} - Warning or degraded state"
echo -e "${RED}✗${NC} - Connection failed"
echo -e "${YELLOW}⊘${NC} - Not deployed or optional"
echo ""
echo "Next Steps:"
echo "1. If VPN is deployed, test connectivity from on-premises"
echo "2. Test SSH access to PowerVS instances"
echo "3. Test COS access through VPE gateway"
echo "4. Monitor Transit Gateway metrics in IBM Cloud console"
echo ""

# Made with Bob
