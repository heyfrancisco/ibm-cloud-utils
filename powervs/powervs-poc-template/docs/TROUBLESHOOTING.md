# PowerVS POC Template - Troubleshooting Guide

This guide provides solutions to common issues encountered during deployment and operation of the IBM Cloud Landing Zone.

## Table of Contents

1. [General Issues](#general-issues)
2. [VPC Issues](#vpc-issues)
3. [VPN Issues](#vpn-issues)
4. [PowerVS Issues](#powervs-issues)
5. [Transit Gateway Issues](#transit-gateway-issues)
6. [COS Issues](#cos-issues)
7. [VPE Gateway Issues](#vpe-gateway-issues)
8. [Terraform Issues](#terraform-issues)

---

## General Issues

### API Key Authentication Failures

**Symptoms:**
- `Error: authentication failed` messages
- Unable to connect to IBM Cloud

**Solutions:**
1. Verify API key is set correctly:
   ```bash
   echo $IC_API_KEY
   ```

2. Test API key:
   ```bash
   ibmcloud login --apikey $IC_API_KEY
   ```

3. Ensure API key has required permissions:
   - Editor role on resource group
   - Service access for VPC, PowerVS, COS, Transit Gateway

4. Generate new API key if needed:
   ```bash
   ibmcloud iam api-key-create landing-zone-key -d "Landing Zone deployment"
   ```

### Resource Quota Exceeded

**Symptoms:**
- `Error: quota exceeded` messages
- Resources fail to create

**Solutions:**
1. Check current quotas:
   ```bash
   ibmcloud is quotas
   ```

2. Request quota increase through IBM Cloud support

3. Clean up unused resources:
   ```bash
   # List all VPCs
   ibmcloud is vpcs
   
   # List all PowerVS workspaces
   ibmcloud pi service-list
   ```

### Region/Zone Availability Issues

**Symptoms:**
- Resources unavailable in selected region/zone
- `Error: service not available in region`

**Solutions:**
1. Verify region availability:
   ```bash
   ibmcloud regions
   ```

2. Check PowerVS zone availability:
   ```bash
   ibmcloud pi service-list
   ```

3. Update `region` and `powervs_zone` variables in terraform.tfvars

---

## VPC Issues

### VPC Creation Failures

**Symptoms:**
- VPC fails to create
- Timeout errors during VPC creation

**Solutions:**
1. Verify resource group exists:
   ```bash
   ibmcloud resource groups
   ```

2. Check for naming conflicts:
   ```bash
   ibmcloud is vpcs | grep <prefix>
   ```

3. Ensure CIDR range is valid and doesn't conflict:
   - Use private IP ranges (10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16)
   - Avoid overlapping with existing networks

4. Review Terraform logs:
   ```bash
   TF_LOG=DEBUG terraform apply
   ```

### Subnet Creation Issues

**Symptoms:**
- Subnet fails to create
- CIDR range errors

**Solutions:**
1. Verify CIDR is within VPC range
2. Ensure CIDR doesn't overlap with existing subnets
3. Check zone availability:
   ```bash
   ibmcloud is zones us-south
   ```

4. Verify subnet size is appropriate (minimum /28)

### Security Group Rule Conflicts

**Symptoms:**
- Unable to connect to resources
- Security group rules not working as expected

**Solutions:**
1. Review security group rules:
   ```bash
   ibmcloud is security-group <sg-id>
   ```

2. Verify rule priorities and directions (inbound/outbound)

3. Check for conflicting rules:
   - Ensure allow rules aren't overridden by deny rules
   - Verify CIDR ranges are correct

4. Test connectivity:
   ```bash
   # From within VPC
   nc -zv <target-ip> <port>
   ```

---

## VPN Issues

### VPN Gateway Creation Failures

**Symptoms:**
- VPN gateway fails to create
- Subnet association errors

**Solutions:**
1. Verify subnet exists and is in correct zone
2. Ensure only one VPN gateway per subnet
3. Check for sufficient IP addresses in subnet
4. Review VPN gateway mode (route vs policy)

### VPN Connection Not Establishing

**Symptoms:**
- VPN status shows "down"
- No traffic flowing through tunnel

**Solutions:**
1. Verify peer gateway is reachable:
   ```bash
   ping <peer-gateway-ip>
   ```

2. Check preshared key matches on both sides

3. Verify IKE and IPSec policies match peer configuration:
   - IKE version (1 or 2)
   - Authentication algorithm
   - Encryption algorithm
   - DH group

4. Check firewall rules on peer side allow:
   - UDP port 500 (IKE)
   - UDP port 4500 (NAT-T)
   - ESP protocol (IP protocol 50)

5. Review VPN connection logs:
   ```bash
   ibmcloud is vpn-gateway-connection <gateway-id> <connection-id>
   ```

### VPN Tunnel Flapping

**Symptoms:**
- VPN connection alternates between up and down
- Intermittent connectivity

**Solutions:**
1. Enable Dead Peer Detection (DPD):
   - Set appropriate timeout values
   - Configure action on timeout

2. Check for network instability:
   - Verify peer gateway stability
   - Check for packet loss

3. Review MTU settings:
   - Reduce MTU if fragmentation issues
   - Typical VPN MTU: 1400-1450 bytes

4. Verify NAT-T is working if behind NAT

---

## PowerVS Issues

### Workspace Creation Failures

**Symptoms:**
- PowerVS workspace fails to create
- Zone availability errors

**Solutions:**
1. Verify PowerVS zone is correct:
   ```bash
   ibmcloud pi service-list
   ```

2. Check zone capacity:
   - Some zones may have limited capacity
   - Try alternative zone in same region

3. Ensure resource group has permissions

4. Verify naming conventions are followed

### Instance Creation Failures

**Symptoms:**
- LPAR instance fails to create
- Image not found errors

**Solutions:**
1. List available images:
   ```bash
   ibmcloud pi images --json
   ```

2. Verify image name/ID is correct in terraform.tfvars

3. Check processor and memory requirements:
   - Minimum: 0.25 cores, 2GB RAM
   - Ensure values are valid for selected system type

4. Verify storage tier availability:
   - tier1: High performance (may have limited availability)
   - tier3: Standard (generally available)

5. Check SSH key is imported:
   ```bash
   ibmcloud pi keys
   ```

### Instance Connectivity Issues

**Symptoms:**
- Cannot SSH to PowerVS instance
- Network connectivity problems

**Solutions:**
1. Verify instance is running:
   ```bash
   ibmcloud pi instances
   ```

2. Check private IP assignment:
   ```bash
   terraform output pi_instance_private_ips
   ```

3. Verify Transit Gateway connection is established

4. Test from VPC instance (if available):
   ```bash
   ping <powervs-instance-ip>
   ssh -i <private-key> root@<powervs-instance-ip>
   ```

5. Check PowerVS subnet configuration:
   - DNS servers configured
   - Gateway configured
   - CIDR range correct

---

## Transit Gateway Issues

### Gateway Creation Failures

**Symptoms:**
- Transit Gateway fails to create
- Location errors

**Solutions:**
1. Verify location setting (local or global):
   - Use "local" for same-region connectivity
   - Use "global" for cross-region

2. Check resource group permissions

3. Ensure unique naming

4. Review global routing requirements

### Connection Failures

**Symptoms:**
- VPC or PowerVS connection fails
- Status shows "failed" or "pending"

**Solutions:**
1. Verify VPC CRN is correct:
   ```bash
   terraform output vpc_crn
   ```

2. Check PowerVS workspace ID:
   ```bash
   terraform output pi_workspace_id
   ```

3. Ensure resources are in compatible regions/zones

4. Review connection status:
   ```bash
   ibmcloud tg connections <gateway-id>
   ```

5. Check for network overlaps:
   - VPC CIDR: 10.10.10.0/24
   - PowerVS CIDR: 192.168.100.0/24
   - Ensure no conflicts

### Routing Issues

**Symptoms:**
- Traffic not flowing between VPC and PowerVS
- Connectivity tests fail

**Solutions:**
1. Verify Transit Gateway status is "available":
   ```bash
   ibmcloud tg gateway <gateway-id>
   ```

2. Check connection status for both VPC and PowerVS

3. Verify routing tables:
   - VPC routes should include PowerVS CIDR
   - PowerVS should route to VPC CIDR

4. Test connectivity from both sides:
   ```bash
   # From VPC
   ping <powervs-ip>
   
   # From PowerVS
   ping <vpc-ip>
   ```

5. Check security groups and ACLs allow traffic

---

## COS Issues

### Instance Creation Failures

**Symptoms:**
- COS instance fails to create
- Plan errors

**Solutions:**
1. Verify COS plan is valid:
   - "standard"
   - "cos-one-rate-plan"

2. Check resource group permissions

3. Ensure unique instance name

4. Review region availability

### Bucket Creation Failures

**Symptoms:**
- Bucket fails to create
- Naming conflicts

**Solutions:**
1. Verify bucket name is globally unique:
   - Must be DNS-compliant
   - Lowercase letters, numbers, hyphens only
   - 3-63 characters

2. Check storage class is valid:
   - standard, vault, cold, smart

3. Verify region/location is correct

4. Review encryption configuration if enabled

### Encryption Issues

**Symptoms:**
- Encryption fails to enable
- KMS key errors

**Solutions:**
1. Verify KMS key CRN is correct

2. Ensure COS service has authorization to use KMS key:
   ```bash
   ibmcloud iam authorization-policy-create \
     cloud-object-storage kms Reader \
     --source-service-instance-id <cos-instance-id> \
     --target-service-instance-id <kms-instance-id>
   ```

3. Check KMS key is active and not deleted

4. Verify region compatibility between COS and KMS

---

## VPE Gateway Issues

### Gateway Creation Failures

**Symptoms:**
- VPE gateway fails to create
- Subnet errors

**Solutions:**
1. Verify VPC and subnets exist

2. Check subnet has available IP addresses

3. Ensure service endpoint is supported in region

4. Review security group configuration

### Service Binding Failures

**Symptoms:**
- Cannot bind to COS service
- CRN errors

**Solutions:**
1. Verify COS instance CRN is correct:
   ```bash
   terraform output cos_instance_crn
   ```

2. Ensure COS instance exists and is active

3. Check VPE gateway is in same region as COS

4. Review IAM permissions for service binding

### Connectivity Issues

**Symptoms:**
- Cannot access COS through private endpoint
- DNS resolution fails

**Solutions:**
1. Verify VPE gateway IPs are assigned:
   ```bash
   terraform output vpe_ips
   ```

2. Check DNS resolution:
   ```bash
   nslookup s3.us-south.cloud-object-storage.appdomain.cloud
   ```

3. Verify security groups allow HTTPS (443) traffic

4. Test connectivity:
   ```bash
   curl -I https://s3.us-south.cloud-object-storage.appdomain.cloud
   ```

5. Ensure VPC DNS resolver is configured correctly

---

## Terraform Issues

### State Lock Errors

**Symptoms:**
- `Error: state locked` messages
- Cannot run terraform commands

**Solutions:**
1. Wait for other operations to complete

2. Force unlock if operation failed:
   ```bash
   terraform force-unlock <lock-id>
   ```

3. Use remote state with locking for team environments

### Module Version Conflicts

**Symptoms:**
- Module version errors
- Incompatible provider versions

**Solutions:**
1. Update provider versions:
   ```bash
   terraform init -upgrade
   ```

2. Review module version constraints in versions.tf

3. Check module compatibility with provider version

4. Pin specific versions for stability

### Resource Import Issues

**Symptoms:**
- Need to import existing resources
- State conflicts

**Solutions:**
1. Import existing resource:
   ```bash
   terraform import <resource-type>.<name> <resource-id>
   ```

2. Update state to match configuration:
   ```bash
   terraform refresh
   ```

3. Review state file for conflicts:
   ```bash
   terraform state list
   terraform state show <resource>
   ```

---

## Getting Additional Help

### IBM Cloud Support

1. Open support case in IBM Cloud console
2. Provide:
   - Detailed error messages
   - Terraform logs (TF_LOG=DEBUG)
   - Resource IDs
   - Steps to reproduce

### Community Resources

- [IBM Cloud Documentation](https://cloud.ibm.com/docs)
- [Terraform IBM Provider Issues](https://github.com/IBM-Cloud/terraform-provider-ibm/issues)
- [IBM Cloud Community](https://community.ibm.com/community/user/cloud/home)

### Diagnostic Commands

```bash
# Terraform debugging
TF_LOG=DEBUG terraform apply

# IBM Cloud CLI debugging
ibmcloud config --check-version false
ibmcloud plugin list

# Network diagnostics
traceroute <target-ip>
mtr <target-ip>
tcpdump -i any host <target-ip>

# Resource inspection
terraform show
terraform state list
terraform output
```

---

*Last Updated: 2026-02-04*