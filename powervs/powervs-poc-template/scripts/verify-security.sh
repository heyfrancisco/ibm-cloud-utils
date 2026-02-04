#!/bin/bash
##############################################################################
# Security Configuration Verification Script
#
# This script verifies security configurations including security groups,
# network ACLs, encryption, and access controls.
#
# Usage: ./scripts/verify-security.sh
##############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=========================================="
echo "IBM Cloud Landing Zone - Security Verification"
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

# Verify Security Groups
echo ""
echo -e "${BLUE}Verifying Security Groups...${NC}"
SG_IDS=$(terraform output -json security_group_ids 2>/dev/null | jq -r '.[]' 2>/dev/null || echo "")

if [ -n "$SG_IDS" ]; then
    for sg_id in $SG_IDS; do
        SG_INFO=$(ibmcloud is security-group "$sg_id" --output json 2>/dev/null || echo "{}")
        SG_NAME=$(echo "$SG_INFO" | jq -r '.name' 2>/dev/null || echo "unknown")
        
        echo ""
        echo "Security Group: $SG_NAME ($sg_id)"
        
        # Check inbound rules
        INBOUND_RULES=$(echo "$SG_INFO" | jq -r '.rules[] | select(.direction=="inbound") | "  \(.protocol):\(.port_min)-\(.port_max) from \(.remote.cidr_block // .remote.address // "any")"' 2>/dev/null || echo "")
        if [ -n "$INBOUND_RULES" ]; then
            echo "  Inbound Rules:"
            echo "$INBOUND_RULES"
        else
            echo -e "${YELLOW}⚠${NC} No inbound rules configured"
        fi
        
        # Check outbound rules
        OUTBOUND_RULES=$(echo "$SG_INFO" | jq -r '.rules[] | select(.direction=="outbound") | "  \(.protocol):\(.port_min)-\(.port_max) to \(.remote.cidr_block // .remote.address // "any")"' 2>/dev/null || echo "")
        if [ -n "$OUTBOUND_RULES" ]; then
            echo "  Outbound Rules:"
            echo "$OUTBOUND_RULES"
        else
            echo -e "${YELLOW}⚠${NC} No outbound rules configured"
        fi
    done
    echo -e "${GREEN}✓${NC} Security groups configured"
else
    echo -e "${RED}✗${NC} No security groups found"
fi

# Verify Network ACLs
echo ""
echo -e "${BLUE}Verifying Network ACLs...${NC}"
VPC_ID=$(terraform output -raw vpc_id 2>/dev/null || echo "")

if [ -n "$VPC_ID" ]; then
    ACLS=$(ibmcloud is network-acls --output json 2>/dev/null | jq -r --arg vpc "$VPC_ID" '.[] | select(.vpc.id==$vpc) | .id' 2>/dev/null || echo "")
    
    if [ -n "$ACLS" ]; then
        for acl_id in $ACLS; do
            ACL_INFO=$(ibmcloud is network-acl "$acl_id" --output json 2>/dev/null || echo "{}")
            ACL_NAME=$(echo "$ACL_INFO" | jq -r '.name' 2>/dev/null || echo "unknown")
            
            echo ""
            echo "Network ACL: $ACL_NAME ($acl_id)"
            
            # Check rules
            RULE_COUNT=$(echo "$ACL_INFO" | jq '.rules | length' 2>/dev/null || echo "0")
            echo "  Total Rules: $RULE_COUNT"
            
            if [ "$RULE_COUNT" -gt 0 ]; then
                echo -e "${GREEN}✓${NC} ACL rules configured"
            else
                echo -e "${YELLOW}⚠${NC} No ACL rules configured"
            fi
        done
    else
        echo -e "${YELLOW}⊘${NC} Using default network ACL"
    fi
else
    echo -e "${RED}✗${NC} VPC not found"
fi

# Verify VPN Security (if deployed)
echo ""
echo -e "${BLUE}Verifying VPN Security...${NC}"
VPN_GW_ID=$(terraform output -raw vpn_gateway_id 2>/dev/null || echo "")

if [ -n "$VPN_GW_ID" ]; then
    VPN_CONN_IDS=$(terraform output -json vpn_connection_ids 2>/dev/null | jq -r '.[]' 2>/dev/null || echo "")
    
    if [ -n "$VPN_CONN_IDS" ]; then
        for conn_id in $VPN_CONN_IDS; do
            CONN_INFO=$(ibmcloud is vpn-gateway-connection "$VPN_GW_ID" "$conn_id" --output json 2>/dev/null || echo "{}")
            CONN_NAME=$(echo "$CONN_INFO" | jq -r '.name' 2>/dev/null || echo "unknown")
            
            echo ""
            echo "VPN Connection: $CONN_NAME"
            
            # Check IKE policy
            IKE_VERSION=$(echo "$CONN_INFO" | jq -r '.ike_policy.ike_version' 2>/dev/null || echo "unknown")
            IKE_AUTH=$(echo "$CONN_INFO" | jq -r '.ike_policy.authentication_algorithm' 2>/dev/null || echo "unknown")
            IKE_ENCRYPT=$(echo "$CONN_INFO" | jq -r '.ike_policy.encryption_algorithm' 2>/dev/null || echo "unknown")
            
            echo "  IKE Policy:"
            echo "    Version: $IKE_VERSION"
            echo "    Authentication: $IKE_AUTH"
            echo "    Encryption: $IKE_ENCRYPT"
            
            if [ "$IKE_VERSION" == "2" ]; then
                echo -e "${GREEN}✓${NC} Using IKEv2 (recommended)"
            else
                echo -e "${YELLOW}⚠${NC} Using IKEv1 (consider upgrading to IKEv2)"
            fi
            
            # Check IPSec policy
            IPSEC_AUTH=$(echo "$CONN_INFO" | jq -r '.ipsec_policy.authentication_algorithm' 2>/dev/null || echo "unknown")
            IPSEC_ENCRYPT=$(echo "$CONN_INFO" | jq -r '.ipsec_policy.encryption_algorithm' 2>/dev/null || echo "unknown")
            
            echo "  IPSec Policy:"
            echo "    Authentication: $IPSEC_AUTH"
            echo "    Encryption: $IPSEC_ENCRYPT"
        done
        echo -e "${GREEN}✓${NC} VPN security configured"
    fi
else
    echo -e "${YELLOW}⊘${NC} VPN not deployed (optional)"
fi

# Verify COS Encryption
echo ""
echo -e "${BLUE}Verifying COS Encryption...${NC}"
COS_INSTANCE_ID=$(terraform output -raw cos_instance_id 2>/dev/null || echo "")

if [ -n "$COS_INSTANCE_ID" ]; then
    # Check if encryption is enabled
    ENCRYPTION_ENABLED=$(terraform output -raw cos_encryption_enabled 2>/dev/null || echo "false")
    
    if [ "$ENCRYPTION_ENABLED" == "true" ]; then
        echo -e "${GREEN}✓${NC} COS encryption enabled"
        
        KMS_KEY_CRN=$(terraform output -raw kms_key_crn 2>/dev/null || echo "")
        if [ -n "$KMS_KEY_CRN" ] && [ "$KMS_KEY_CRN" != "null" ]; then
            echo "  KMS Key: $KMS_KEY_CRN"
            echo -e "${GREEN}✓${NC} Using customer-managed encryption key"
        else
            echo -e "${YELLOW}⚠${NC} Using IBM-managed encryption (consider customer-managed keys)"
        fi
    else
        echo -e "${YELLOW}⚠${NC} COS encryption not enabled (recommended for production)"
    fi
else
    echo -e "${YELLOW}⊘${NC} COS not deployed"
fi

# Verify PowerVS SSH Keys
echo ""
echo -e "${BLUE}Verifying PowerVS SSH Keys...${NC}"
POWERVS_SSH_KEY=$(terraform output -raw pi_ssh_public_key_name 2>/dev/null || echo "")

if [ -n "$POWERVS_SSH_KEY" ]; then
    echo -e "${GREEN}✓${NC} SSH key configured: $POWERVS_SSH_KEY"
    echo "  Ensure private key is securely stored"
else
    echo -e "${YELLOW}⊘${NC} PowerVS SSH key not found"
fi

# Check for public gateways
echo ""
echo -e "${BLUE}Verifying Public Gateway Configuration...${NC}"
PUBLIC_GW_ENABLED=$(terraform output -raw enable_public_gateway 2>/dev/null || echo "false")

if [ "$PUBLIC_GW_ENABLED" == "true" ]; then
    echo -e "${YELLOW}⚠${NC} Public gateway enabled"
    echo "  Review if public internet access is required"
    echo "  Consider using VPN or Direct Link for production"
else
    echo -e "${GREEN}✓${NC} Public gateway disabled (more secure)"
fi

# Security Recommendations
echo ""
echo "=========================================="
echo "Security verification complete"
echo "=========================================="
echo ""
echo "Security Recommendations:"
echo ""
echo "1. Security Groups:"
echo "   - Follow principle of least privilege"
echo "   - Restrict source IPs to known ranges"
echo "   - Regularly review and audit rules"
echo ""
echo "2. VPN (if deployed):"
echo "   - Use IKEv2 for better security"
echo "   - Use strong preshared keys (32+ characters)"
echo "   - Enable Dead Peer Detection"
echo ""
echo "3. Encryption:"
echo "   - Enable encryption for COS buckets"
echo "   - Use customer-managed keys (Key Protect/HPCS)"
echo "   - Enable encryption in transit"
echo ""
echo "4. Access Control:"
echo "   - Use IAM policies for fine-grained access"
echo "   - Enable MFA for user accounts"
echo "   - Rotate credentials regularly"
echo ""
echo "5. Monitoring:"
echo "   - Enable Activity Tracker"
echo "   - Set up security alerts"
echo "   - Review logs regularly"
echo ""
echo "6. Network Isolation:"
echo "   - Use private endpoints where possible"
echo "   - Minimize public internet exposure"
echo "   - Implement network segmentation"
echo ""

# Made with Bob
