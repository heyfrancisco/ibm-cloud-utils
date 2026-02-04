# IBM Cloud Terraform Landing Zone - Implementation Plan

## Table of Contents
1. [Project Overview](#project-overview)
2. [Project Structure](#project-structure)
3. [Module Requirements](#module-requirements)
4. [Implementation Sequence](#implementation-sequence)
5. [Variable Definitions](#variable-definitions)
6. [Integration Points](#integration-points)
7. [Verification Checkpoints](#verification-checkpoints)
8. [Deployment Steps](#deployment-steps)

---

## Project Overview

This implementation plan provides a comprehensive guide for deploying an IBM Cloud Landing Zone using Terraform. The architecture creates a hybrid cloud infrastructure connecting IBM Cloud VPC with PowerVS workloads through Transit Gateway, with secure VPN access and private Cloud Object Storage connectivity.

### Architecture Components
- **VPC Infrastructure**: Foundation network with subnet, security groups, and optional VPN gateway
- **Site-to-Site VPN**: Optional secure connectivity for external access
- **Cloud Object Storage**: Object storage with encryption and private connectivity
- **PowerVS Workspace**: IBM Power Systems Virtual Server workspace with private networking
- **PowerVS Instance**: LPAR instances running on PowerVS
- **Transit Gateway**: Bridges VPC and PowerVS networks with local routing
- **VPE Gateway**: Private connectivity between VPC and cloud services (COS)

### Resource Naming Convention
All resources follow the pattern: `${var.prefix}-${resource_type}-${identifier}`

Examples:
- VPC: `${var.prefix}-vpc`
- Subnet: `${var.prefix}-subnet-zone-1`
- Security Group: `${var.prefix}-sg`
- VPN Gateway: `${var.prefix}-vpn-gateway`
- PowerVS Workspace: `${var.prefix}-powervs-workspace`
- PowerVS Instance: `${var.prefix}-powervs-lpar`
- Transit Gateway: `${var.prefix}-tgw`
- COS Instance: `${var.prefix}-cos`
- COS Bucket: `${var.prefix}-cos-bucket`
- VPE Gateway: `${var.prefix}-vpe-cos`

---

## Project Structure

```
/
├── IMPLEMENTATION_PLAN.md          # This file
├── README.md                        # Project documentation
├── provider.tf                      # IBM Cloud provider configuration
├── versions.tf                      # Terraform and provider version constraints
├── terraform.tfvars.template        # Template for variable values
├── main.tf                          # Root module orchestration
├── variables.tf                     # Root module variables
├── outputs.tf                       # Root module outputs
│
├── modules/                         # Terraform modules
│   ├── 01-vpc/                     # VPC Infrastructure
│   │   ├── main.tf                 # VPC module configuration
│   │   ├── variables.tf            # VPC variables
│   │   ├── outputs.tf              # VPC outputs
│   │   └── README.md               # VPC module documentation
│   │
│   ├── 02-vpn/                     # Site-to-Site VPN (Optional)
│   │   ├── main.tf                 # VPN module configuration
│   │   ├── variables.tf            # VPN variables
│   │   ├── outputs.tf              # VPN outputs
│   │   └── README.md               # VPN module documentation
│   │
│   ├── 03-cos/                     # Cloud Object Storage
│   │   ├── main.tf                 # COS module configuration
│   │   ├── variables.tf            # COS variables
│   │   ├── outputs.tf              # COS outputs
│   │   └── README.md               # COS module documentation
│   │
│   ├── 04-powervs-workspace/       # PowerVS Workspace
│   │   ├── main.tf                 # Workspace module configuration
│   │   ├── variables.tf            # Workspace variables
│   │   ├── outputs.tf              # Workspace outputs
│   │   └── README.md               # Workspace module documentation
│   │
│   ├── 05-powervs-instance/        # PowerVS Instance
│   │   ├── main.tf                 # Instance module configuration
│   │   ├── variables.tf            # Instance variables
│   │   ├── outputs.tf              # Instance outputs
│   │   └── README.md               # Instance module documentation
│   │
│   ├── 06-transit-gateway/         # Transit Gateway
│   │   ├── main.tf                 # Transit Gateway configuration
│   │   ├── variables.tf            # Transit Gateway variables
│   │   ├── outputs.tf              # Transit Gateway outputs
│   │   └── README.md               # Transit Gateway documentation
│   │
│   └── 07-vpe-gateway/             # VPE Gateway
│       ├── main.tf                 # VPE Gateway configuration
│       ├── variables.tf            # VPE Gateway variables
│       ├── outputs.tf              # VPE Gateway outputs
│       └── README.md               # VPE Gateway documentation
│
├── scripts/                         # Utility scripts
│   ├── verify-connectivity.sh      # Network connectivity verification
│   ├── verify-security.sh          # Security configuration verification
│   └── verify-resources.sh         # Resource deployment verification
│
└── docs/                            # Additional documentation
    ├── TROUBLESHOOTING.md          # Common issues and solutions
    └── MONITORING.md               # Monitoring and maintenance guide
```

---

## Module Requirements

### 1. VPC Infrastructure (landing-zone-vpc)
- **Module Source**: `terraform-ibm-modules/landing-zone-vpc/ibm`
- **Version**: `8.7.0`
- **Purpose**: Creates VPC with subnets, security groups, and network ACLs
- **Dependencies**: None (foundation layer)

### 2. Site-to-Site VPN (site-to-site-vpn)
- **Module Source**: `terraform-ibm-modules/site-to-site-vpn/ibm`
- **Version**: `3.0.4`
- **Purpose**: Establishes secure VPN connections to external networks
- **Dependencies**: VPC (vpc_id, subnet_id)
- **Optional**: Can be skipped if VPN connectivity is not required

### 3. Cloud Object Storage (cos)
- **Module Source**: `terraform-ibm-modules/cos/ibm`
- **Version**: `10.5.0`
- **Purpose**: Provisions COS instance and buckets with encryption
- **Dependencies**: None (independent service)

### 4. PowerVS Workspace (powervs-workspace)
- **Module Source**: `terraform-ibm-modules/powervs-workspace/ibm`
- **Version**: `4.1.2`
- **Purpose**: Creates PowerVS workspace with private subnets and SSH keys
- **Dependencies**: None (independent service)

### 5. PowerVS Instance (powervs-instance)
- **Module Source**: `terraform-ibm-modules/powervs-instance/ibm`
- **Version**: `2.8.2`
- **Purpose**: Deploys LPAR instances in PowerVS workspace
- **Dependencies**: PowerVS Workspace (workspace_guid, ssh_key, networks)

### 6. Transit Gateway (transit-gateway)
- **Module Source**: `terraform-ibm-modules/transit-gateway/ibm`
- **Version**: `2.5.2`
- **Purpose**: Connects VPC and PowerVS networks
- **Dependencies**: VPC (vpc_crn), PowerVS Workspace (workspace_id)

### 7. VPE Gateway (vpe-gateway)
- **Module Source**: `terraform-ibm-modules/vpe-gateway/ibm`
- **Version**: `4.7.12`
- **Purpose**: Provides private connectivity to cloud services
- **Dependencies**: VPC (vpc_id, subnet_zone_list), COS (instance_crn)

---

## Implementation Sequence

The modules must be deployed in the following order due to dependencies:

```
Step 1: VPC Infrastructure (landing-zone-vpc)
   ↓ outputs: vpc_id, vpc_crn, subnet_ids, subnet_zone_list, security_group_ids
   
Step 2: Site-to-Site VPN (site-to-site-vpn) [OPTIONAL]
   ↓ requires: vpc_id, subnet_id from Step 1
   ↓ outputs: vpn_gateway_id, vpn_connection_ids
   
Step 3: Cloud Object Storage (cos)
   ↓ outputs: cos_instance_id, cos_instance_crn, bucket_id
   
Step 4: PowerVS Workspace (powervs-workspace)
   ↓ outputs: pi_workspace_guid, pi_workspace_id, pi_ssh_public_key_name, pi_private_subnet_1
   
Step 5: PowerVS Instance (powervs-instance)
   ↓ requires: pi_workspace_guid, pi_ssh_public_key_name, pi_networks from Step 4
   ↓ outputs: pi_instance_id, pi_instance_private_ips
   
Step 6: Transit Gateway (transit-gateway)
   ↓ requires: vpc_crn from Step 1, pi_workspace_id from Step 4
   ↓ outputs: tg_id, tg_crn
   
Step 7: VPE Gateway (vpe-gateway)
   ↓ requires: vpc_id, subnet_zone_list from Step 1, cos_instance_crn from Step 3
   ↓ outputs: vpe_ips, crn
```

---

## Variable Definitions

### Global Variables (Required for all modules)

```hcl
# Project Configuration
variable "prefix" {
  description = "Prefix for all resource names (max 20 characters)"
  type        = string
  validation {
    condition     = length(var.prefix) <= 20
    error_message = "Prefix must be 20 characters or less"
  }
}

variable "region" {
  description = "IBM Cloud region for VPC resources"
  type        = string
  default     = "us-south"
}

variable "resource_group_id" {
  description = "Resource group ID for all resources"
  type        = string
}

variable "tags" {
  description = "List of tags for resource organization"
  type        = list(string)
  default     = ["env:dev", "project:landing-zone"]
}
```

### VPC Module Variables

```hcl
variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "vpc"
}

variable "vpc_zone" {
  description = "Availability zone for VPC resources"
  type        = string
  default     = "us-south-1"
}

variable "subnet_cidr" {
  description = "CIDR block for the subnet"
  type        = string
  default     = "10.10.10.0/24"
}

variable "enable_public_gateway" {
  description = "Enable public gateway for subnet"
  type        = bool
  default     = true
}
```

### VPN Module Variables (Optional)

```hcl
variable "enable_vpn" {
  description = "Enable VPN gateway deployment"
  type        = bool
  default     = false
}

variable "vpn_connections" {
  description = "List of VPN connections to create"
  type = list(object({
    name              = string
    peer_address      = string
    preshared_key     = string
    local_cidrs       = list(string)
    peer_cidrs        = list(string)
  }))
  default = []
}

variable "vpn_mode" {
  description = "VPN gateway mode (route or policy)"
  type        = string
  default     = "route"
}

variable "ike_version" {
  description = "IKE protocol version"
  type        = number
  default     = 2
}
```

### COS Module Variables

```hcl
variable "cos_instance_name" {
  description = "Name for COS instance"
  type        = string
}

variable "cos_plan" {
  description = "COS plan (standard or cos-one-rate-plan)"
  type        = string
  default     = "standard"
}

variable "cos_bucket_name" {
  description = "Name for COS bucket"
  type        = string
}

variable "cos_storage_class" {
  description = "Storage class for bucket (standard, vault, cold, smart)"
  type        = string
  default     = "standard"
}

variable "cos_encryption_enabled" {
  description = "Enable KMS encryption for COS bucket"
  type        = bool
  default     = true
}

variable "kms_key_crn" {
  description = "CRN of KMS key for COS encryption (optional)"
  type        = string
  default     = null
}
```

### PowerVS Workspace Variables

```hcl
variable "powervs_zone" {
  description = "PowerVS zone (e.g., dal10, us-south, etc.)"
  type        = string
  default     = "dal10"
}

variable "powervs_subnet_cidr" {
  description = "CIDR for PowerVS private subnet"
  type        = string
  default     = "192.168.100.0/24"
}

variable "powervs_dns_servers" {
  description = "Custom DNS servers for PowerVS"
  type        = list(string)
  default     = ["8.8.8.8", "8.8.4.4"]
}

variable "powervs_ssh_key_name" {
  description = "Name for PowerVS SSH key"
  type        = string
}

variable "powervs_ssh_public_key" {
  description = "Public SSH key content"
  type        = string
}
```

### PowerVS Instance Variables

```hcl
variable "powervs_instance_name" {
  description = "Name for PowerVS LPAR instance"
  type        = string
}

variable "powervs_instance_image" {
  description = "Image ID for PowerVS instance"
  type        = string
}

variable "powervs_instance_processors" {
  description = "Number of processors for PowerVS instance"
  type        = string
  default     = "0.5"
}

variable "powervs_instance_memory" {
  description = "Memory in GB for PowerVS instance"
  type        = string
  default     = "4"
}

variable "powervs_instance_proc_type" {
  description = "Processor type (shared, capped, dedicated)"
  type        = string
  default     = "shared"
}

variable "powervs_storage_tier" {
  description = "Storage tier for PowerVS (tier1 or tier3)"
  type        = string
  default     = "tier3"
}

variable "powervs_storage_size" {
  description = "Storage size in GB"
  type        = string
  default     = "100"
}
```

### Transit Gateway Variables

```hcl
variable "transit_gateway_name" {
  description = "Name for Transit Gateway"
  type        = string
}

variable "transit_gateway_location" {
  description = "Location for Transit Gateway (local or global)"
  type        = string
  default     = "local"
}

variable "enable_global_routing" {
  description = "Enable global routing for Transit Gateway"
  type        = bool
  default     = false
}
```

---

## Integration Points

### Output-to-Input Mappings

| Source Module | Output | Target Module | Input Variable |
|--------------|--------|---------------|----------------|
| **01-vpc** | vpc_id | 02-vpn | vpc_id |
| **01-vpc** | subnet_ids[0] | 02-vpn | vpn_gateway_subnet_id |
| **01-vpc** | vpc_id | 07-vpe-gateway | vpc_id |
| **01-vpc** | subnet_zone_list | 07-vpe-gateway | subnet_zone_list |
| **01-vpc** | vpc_crn | 06-transit-gateway | vpc_connections[].vpc_crn |
| **03-cos** | cos_instance_crn | 07-vpe-gateway | cloud_service_by_crn[].crn |
| **04-powervs-workspace** | pi_workspace_guid | 05-powervs-instance | pi_workspace_guid |
| **04-powervs-workspace** | pi_ssh_public_key.name | 05-powervs-instance | pi_ssh_public_key_name |
| **04-powervs-workspace** | pi_private_subnet_1 | 05-powervs-instance | pi_networks |
| **04-powervs-workspace** | pi_workspace_id | 06-transit-gateway | powervs_workspace_id |

### Critical Dependencies

1. **VPC → VPN**: VPN requires VPC ID and subnet ID
2. **VPC → VPE Gateway**: VPE requires VPC ID and subnet information
3. **VPC → Transit Gateway**: Transit Gateway requires VPC CRN
4. **PowerVS Workspace → PowerVS Instance**: Instance requires workspace GUID, SSH key, and network
5. **PowerVS Workspace → Transit Gateway**: Transit Gateway requires workspace ID
6. **COS → VPE Gateway**: VPE requires COS instance CRN for private connectivity

---

## Verification Checkpoints

### After VPC Deployment (Step 1)
- [ ] Verify VPC is created with correct CIDR range
- [ ] Verify subnet is created in the correct zone
- [ ] Verify security group has correct rules
- [ ] Verify public gateway is attached (if enabled)
- [ ] Verify all outputs are available (vpc_id, vpc_crn, subnet_ids)

### After VPN Deployment (Step 2) [If Enabled]
- [ ] Verify VPN gateway is created
- [ ] Verify VPN connections are established
- [ ] Verify IKE and IPSec policies are configured
- [ ] Test connectivity through VPN tunnel
- [ ] Verify routing is working correctly

### After COS Deployment (Step 3)
- [ ] Verify COS instance is created
- [ ] Verify bucket is created with correct storage class
- [ ] Verify encryption is enabled (if configured)
- [ ] Test object upload and download
- [ ] Verify COS instance CRN is available

### After PowerVS Workspace Deployment (Step 4)
- [ ] Verify workspace is created in correct zone
- [ ] Verify SSH key is imported
- [ ] Verify private subnet is created with correct CIDR
- [ ] Verify DNS servers are configured
- [ ] Verify all outputs are available (workspace_guid, workspace_id)

### After PowerVS Instance Deployment (Step 5)
- [ ] Verify LPAR instance is created
- [ ] Verify instance is attached to correct network
- [ ] Verify storage is attached with correct tier
- [ ] Verify instance is in running state
- [ ] Test SSH connectivity to instance

### After Transit Gateway Deployment (Step 6)
- [ ] Verify Transit Gateway is created
- [ ] Verify VPC connection is established
- [ ] Verify PowerVS connection is established
- [ ] Test connectivity between VPC and PowerVS
- [ ] Verify routing tables are correct

### After VPE Gateway Deployment (Step 7)
- [ ] Verify VPE gateway is created
- [ ] Verify service binding to COS is successful
- [ ] Verify private IPs are assigned
- [ ] Test private connectivity to COS
- [ ] Verify DNS resolution for COS endpoints

---

## Deployment Steps

### Prerequisites
1. Install Terraform (>= 1.3.0)
2. Install IBM Cloud CLI
3. Obtain IBM Cloud API key with appropriate permissions
4. Create or identify resource group
5. Generate SSH key pair for instance access

### Step-by-Step Deployment

#### 1. Initialize Project
```bash
# Clone or create project directory
mkdir ibm-cloud-landing-zone
cd ibm-cloud-landing-zone

# Copy terraform.tfvars.template to terraform.tfvars
cp terraform.tfvars.template terraform.tfvars

# Edit terraform.tfvars with your values
vi terraform.tfvars
```

#### 2. Configure IBM Cloud Provider
```bash
# Set IBM Cloud API key
export IC_API_KEY="your-api-key-here"

# Verify IBM Cloud CLI access
ibmcloud login --apikey $IC_API_KEY
ibmcloud target -r us-south
```

#### 3. Initialize Terraform
```bash
terraform init
```

#### 4. Validate Configuration
```bash
terraform validate
```

#### 5. Plan Deployment
```bash
terraform plan -out=tfplan
```

#### 6. Review Plan
- Review all resources to be created
- Verify resource names follow naming convention
- Verify CIDR ranges don't conflict
- Verify module versions are correct

#### 7. Apply Configuration
```bash
terraform apply tfplan
```

#### 8. Verify Deployment
```bash
# Run verification scripts
./scripts/verify-resources.sh
./scripts/verify-connectivity.sh
./scripts/verify-security.sh
```

#### 9. Document Outputs
```bash
# Save outputs for reference
terraform output > deployment-outputs.txt
```

### Post-Deployment Tasks

1. **Test Connectivity**
   - VPC to PowerVS communication
   - VPN connectivity (if enabled)
   - Private COS access through VPE

2. **Security Validation**
   - Review security group rules
   - Verify network ACL rules
   - Test access controls

3. **Documentation**
   - Document all resource IDs
   - Document IP addresses and CIDRs
   - Update network diagrams

4. **Monitoring Setup**
   - Configure IBM Cloud Monitoring
   - Set up Activity Tracker
   - Configure alerts

### Cleanup/Teardown

To destroy all resources:
```bash
# Destroy in reverse order
terraform destroy
```

**Important**: Ensure all data is backed up before destroying resources.

---

## Best Practices

1. **State Management**
   - Use remote state backend (IBM Cloud Object Storage)
   - Enable state locking
   - Regular state backups

2. **Security**
   - Never commit terraform.tfvars to version control
   - Use IBM Cloud Secrets Manager for sensitive values
   - Rotate API keys regularly
   - Enable encryption at rest and in transit

3. **Cost Management**
   - Tag all resources appropriately
   - Monitor costs regularly
   - Use appropriate instance sizes
   - Clean up unused resources

4. **Change Management**
   - Always run `terraform plan` before apply
   - Review changes carefully
   - Test in non-production first
   - Document all changes

5. **Disaster Recovery**
   - Regular backups of Terraform state
   - Document recovery procedures
   - Test recovery process
   - Maintain infrastructure as code in version control

---

## Next Steps

After completing this implementation plan:

1. Review the generated project structure
2. Customize variables in terraform.tfvars
3. Implement each module following the sequence
4. Test each component after deployment
5. Document any customizations or deviations
6. Set up monitoring and alerting
7. Create runbooks for common operations

---

## Support and Troubleshooting

For issues during deployment:
1. Check `docs/TROUBLESHOOTING.md` for common issues
2. Review Terraform logs: `TF_LOG=DEBUG terraform apply`
3. Verify IBM Cloud service status
4. Check resource quotas and limits
5. Review IBM Cloud documentation for specific services

---

## References

- [IBM Cloud Terraform Provider Documentation](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs)
- [IBM Cloud VPC Documentation](https://cloud.ibm.com/docs/vpc)
- [IBM Cloud PowerVS Documentation](https://cloud.ibm.com/docs/power-iaas)
- [IBM Cloud Transit Gateway Documentation](https://cloud.ibm.com/docs/transit-gateway)
- [IBM Cloud Object Storage Documentation](https://cloud.ibm.com/docs/cloud-object-storage)

---

*Last Updated: 2026-02-04*
*Version: 1.0.0*