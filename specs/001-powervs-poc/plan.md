# Architecture Plan: PowerVS POC Template

**Plan ID**: `001-powervs-poc`  
**Created**: 2026-02-05  
**Status**: Ready for Implementation  
**Branch**: `001-powervs-poc`

## Summary

This plan defines the architecture for a reusable PowerVS POC infrastructure template deployed on IBM Cloud using Terraform. The template provisions a complete hybrid cloud environment connecting Power Systems Virtual Server (PowerVS) workspace to VPC infrastructure via Transit Gateway, with policy-based VPN for customer on-premises connectivity and Cloud Object Storage (COS) accessible via Virtual Private Endpoint (VPE). The architecture enables rapid, consistent POC deployments for multiple customers with configurable network addressing.

**Key Components:**
- PowerVS Workspace (eu-es/Madrid region)
- VPC with configurable subnet (default: 10.240.0.0/24)
- Transit Gateway for PowerVS-VPC connectivity
- Policy-based VPN Gateway for site-to-site customer connectivity
- Cloud Object Storage with VPE for private access
- PowerVS subnet (default: 10.241.0.0/24)

## Technical Context

### Cloud Provider
**IBM Cloud** - Selected for native PowerVS support and integrated hybrid cloud capabilities.

**Region**: `eu-es` (Madrid)  
**Availability Zone**: Single zone deployment (sufficient for POC)

### Infrastructure as Code Tool
**Terraform** v1.7.x or later

**Provider Versions:**
- `ibm` provider: `>= 1.63.0, < 2.0.0` (current stable: 1.63.0)
- Recommended constraint: `~> 1.63` for patch updates

### Official IBM Cloud Terraform Modules

**Core Modules (terraform-ibm-modules):**
- `terraform-ibm-modules/powervs-workspace/ibm` - PowerVS workspace provisioning
- `terraform-ibm-modules/powervs-infrastructure/ibm` - Complete PowerVS infrastructure with Transit Gateway
- `terraform-ibm-modules/transit-gateway/ibm` - Transit Gateway management
- `terraform-ibm-modules/vpc/ibm` - VPC infrastructure
- `terraform-ibm-modules/cos/ibm` - Cloud Object Storage bucket
- `terraform-ibm-modules/vpn-gateway/ibm` - VPN Gateway configuration

**Module Selection Rationale:**
- Use official IBM modules for production-ready patterns
- Modules handle complex dependencies (Transit Gateway connections, routing)
- Built-in best practices for PowerVS networking
- Simplified maintenance and updates

### Technology Stack Versions

| Component | Version | Constraint |
|-----------|---------|------------|
| Terraform | 1.7.x | >= 1.7.0 |
| IBM Provider | 1.63.0 | ~> 1.63 |
| PowerVS Workspace Module | Latest | ~> 4.0 |
| VPC Module | Latest | ~> 1.0 |
| Transit Gateway Module | Latest | ~> 2.0 |

## Principles Check

**Status**: Principles not configured - proceeding with industry best practices for IBM Cloud PowerVS deployments.

**Applied Best Practices:**
- Infrastructure as Code for repeatability
- Private connectivity (no public internet exposure)
- Configurable parameters for multi-customer use
- Resource tagging for cost tracking
- Modular design for maintainability

## Infrastructure Architecture

### Compute Resources

**PowerVS Workspace:**
- **Type**: IBM Power Systems Virtual Server workspace
- **Region**: eu-es (Madrid)
- **Purpose**: Host AIX, IBM i, and Linux workloads for POC
- **Capacity**: Supports 1-3 virtual server instances (provisioned separately)
- **Network**: Private subnet 10.241.0.0/24 (configurable)
- **Module**: `terraform-ibm-modules/powervs-workspace/ibm`

**Configuration:**
```hcl
# PowerVS workspace with configurable subnet
resource_group_id = var.resource_group_id
powervs_zone      = "mad02" # Madrid zone 2
powervs_subnet_cidr = var.powervs_subnet_cidr # default: "10.241.0.0/24"
```

**No VPC compute instances** - VPC provides networking only for this POC template.

### Data Storage

**Cloud Object Storage (COS):**
- **Service**: IBM Cloud Object Storage
- **Bucket Naming**: `{customer-id}-powervs-poc-{timestamp}` (configurable via variable)
- **Region**: eu-es (Madrid) - regional bucket
- **Access Method**: Virtual Private Endpoint (VPE) - no public access
- **Storage Class**: Standard (suitable for POC workloads)
- **Lifecycle**: Manual cleanup after POC completion (30-90 days)
- **Estimated Usage**: < 100 GB per POC
- **Module**: `terraform-ibm-modules/cos/ibm`

**Configuration:**
```hcl
bucket_name = var.cos_bucket_name # default: "{customer-id}-powervs-poc-{timestamp}"
storage_class = "standard"
region = "eu-es"
force_delete = true # Enable for POC cleanup
```

**VPE Configuration:**
- VPE Gateway in VPC connects to COS service endpoint
- Private DNS resolution for `s3.direct.eu-es.cloud-object-storage.appdomain.cloud`
- Security group allows outbound HTTPS (443) to COS endpoints

### Networking Architecture

**Network Topology:**
```
Customer On-Premises (10.x.x.x/24)
         |
         | IPsec VPN Tunnel
         |
    VPN Gateway
         |
    VPC (10.240.0.0/24)
         |
         | Transit Gateway
         |
PowerVS Workspace (10.241.0.0/24)
         |
         | VPE
         |
    Cloud Object Storage
```

**VPC Configuration:**
- **CIDR**: 10.240.0.0/24 (configurable via `var.vpc_subnet_cidr`)
- **Subnet**: Single subnet in Madrid zone
- **Address Prefix**: 10.240.0.0/24
- **Public Gateway**: None (private connectivity only)
- **Module**: `terraform-ibm-modules/vpc/ibm`

**PowerVS Network:**
- **CIDR**: 10.241.0.0/24 (configurable via `var.powervs_subnet_cidr`)
- **Type**: Private network
- **DNS**: IBM Cloud DNS servers
- **Gateway**: Transit Gateway connection

**Transit Gateway:**
- **Type**: Local (single region)
- **Connections**: 
  - PowerVS workspace connection
  - VPC connection
- **Routing**: Automatic route propagation between networks
- **Module**: `terraform-ibm-modules/transit-gateway/ibm`

**VPN Gateway:**
- **Type**: Policy-based VPN
- **Mode**: Route-based with policy enforcement
- **Encryption**: AES-256-CBC
- **Authentication**: SHA-256
- **DH Group**: Group 14 (2048-bit)
- **IKE Version**: IKEv2
- **Connections**: Single connection (customer on-premises)
- **Configuration**: Ready for customer endpoint details (public IP, pre-shared key, remote subnets)
- **Module**: `terraform-ibm-modules/vpn-gateway/ibm`

**VPN Configuration Variables:**
```hcl
# Customer provides these values at deployment
customer_vpn_peer_address = var.customer_vpn_peer_address
customer_vpn_preshared_key = var.customer_vpn_preshared_key
customer_on_prem_cidrs = var.customer_on_prem_cidrs # e.g., ["10.10.0.0/24"]
```

**Virtual Private Endpoint (VPE):**
- **Service**: Cloud Object Storage
- **VPE Gateway**: Deployed in VPC subnet
- **Target**: COS regional endpoint (eu-es)
- **DNS**: Private DNS zone for COS resolution
- **Security**: Security group restricts access to VPC and PowerVS networks

**Routing:**
- Transit Gateway automatically propagates routes between PowerVS and VPC
- VPC route table includes:
  - Local VPC routes (10.240.0.0/24)
  - PowerVS routes via Transit Gateway (10.241.0.0/24)
  - Customer on-prem routes via VPN Gateway (configured per customer)
- PowerVS routing handled by Transit Gateway connection

### Security

**Network Security:**
- **Private Connectivity**: All traffic uses IBM Cloud private backbone (no public internet)
- **Network Isolation**: Separate networks for VPC (10.240.0.0/24) and PowerVS (10.241.0.0/24)
- **VPN Encryption**: IPsec with AES-256, SHA-256, DH Group 14
- **Transit Gateway**: Encrypted connections between networks

**VPC Security Groups:**
```hcl
# VPN Gateway Security Group
- Inbound: UDP 500, 4500 from customer VPN peer IP (IKE/IPsec)
- Outbound: All to PowerVS subnet (10.241.0.0/24)
- Outbound: All to customer on-prem CIDRs

# VPE Gateway Security Group
- Inbound: HTTPS (443) from VPC subnet (10.240.0.0/24)
- Inbound: HTTPS (443) from PowerVS subnet (10.241.0.0/24)
- Outbound: HTTPS (443) to COS endpoints
```

**PowerVS Network Security:**
- Private network only (no public internet access)
- Access controlled via Transit Gateway routing
- Security managed at workspace level

**Access Control:**
- **IAM Policies**: Terraform service ID with minimum required permissions:
  - PowerVS Workspace Manager
  - VPC Infrastructure Services Editor
  - Transit Gateway Editor
  - Cloud Object Storage Writer
- **Resource Groups**: All resources in dedicated resource group per customer
- **API Keys**: Stored securely (IBM Secrets Manager or external vault)

**Encryption:**
- **In Transit**: All network traffic encrypted (VPN, Transit Gateway, VPE)
- **At Rest**: COS bucket encryption enabled by default (IBM-managed keys)
- **VPN**: AES-256-CBC encryption for site-to-site tunnel

**Secrets Management:**
- VPN pre-shared key stored as Terraform sensitive variable
- API keys for Terraform stored externally (not in code)
- Customer-specific secrets documented in deployment guide

### Environment Configuration

**Single Environment Approach:**
Each customer POC is an independent deployment with its own:
- Resource group
- Network addressing
- VPN configuration
- COS bucket

**Configuration Variables by Customer:**

| Variable | Default | Customer A Example | Customer B Example |
|----------|---------|-------------------|-------------------|
| `customer_id` | - | "acme-corp" | "globex-inc" |
| `vpc_subnet_cidr` | "10.240.0.0/24" | "10.240.0.0/24" | "10.242.0.0/24" |
| `powervs_subnet_cidr` | "10.241.0.0/24" | "10.241.0.0/24" | "10.243.0.0/24" |
| `cos_bucket_name` | "{customer-id}-powervs-poc-{timestamp}" | "acme-corp-powervs-poc-20260205" | "globex-inc-powervs-poc-20260210" |
| `customer_vpn_peer_address` | - | "203.0.113.10" | "198.51.100.20" |
| `customer_on_prem_cidrs` | [] | ["10.10.0.0/24"] | ["172.16.0.0/16"] |

**Resource Tagging:**
```hcl
tags = {
  customer_id = var.customer_id
  environment = "poc"
  project     = "powervs-poc"
  created_by  = "terraform"
  created_at  = timestamp()
  cost_center = var.cost_center # optional
}
```

**No Dev/Staging/Prod Separation:**
- Each POC is a standalone environment
- Template is reused per customer, not promoted through environments
- POC duration: 30-90 days, then teardown

### Complexity Assessment

**Complexity Level**: **Baseline** (POC/Development)

**Rationale:**
- Single availability zone deployment
- No high availability or redundancy requirements
- Minimal compute resources (networking infrastructure only)
- Standard security controls (private connectivity, VPN encryption)
- No advanced monitoring, logging, or alerting
- No backup/disaster recovery
- No auto-scaling or load balancing

**Appropriate for POC because:**
- Cost-optimized for short-term evaluation (30-90 days)
- Sufficient for demonstrating PowerVS capabilities
- Quick provisioning (< 2 hours)
- Easy teardown after POC completion
- Meets functional requirements without over-engineering

**Not Suitable for Production:**
- Single zone = no zone redundancy
- No automated backup/recovery
- Basic monitoring only
- No disaster recovery plan
- No performance optimization

### State Management

**Backend**: **IBM Cloud Object Storage (COS)**

**Configuration:**
```hcl
terraform {
  backend "s3" {
    bucket                      = "terraform-state-powervs-poc"
    key                         = "customers/${var.customer_id}/terraform.tfstate"
    region                      = "eu-es"
    endpoint                    = "s3.eu-es.cloud-object-storage.appdomain.cloud"
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
  }
}
```

**State Bucket Setup:**
- **Bucket Name**: `terraform-state-powervs-poc` (created manually once)
- **Region**: eu-es (Madrid)
- **Versioning**: Enabled (retain 30 versions)
- **Encryption**: IBM-managed keys
- **Access**: Restricted to Terraform service ID only
- **Lifecycle**: Retain state files for 1 year after POC completion

**State Organization:**
- One state file per customer: `customers/{customer-id}/terraform.tfstate`
- Separate state files prevent conflicts between customer deployments
- State locking: Not required (single operator per customer deployment)

**State Security:**
- State files contain sensitive data (VPN pre-shared keys, API keys)
- COS bucket access restricted via IAM policies
- State files encrypted at rest
- No public access to state bucket

**Backup Strategy:**
- COS versioning provides automatic state backup
- Manual backup before major changes: `terraform state pull > backup.tfstate`
- State recovery from COS versions if needed

**Alternative for Local Development:**
```hcl
# For testing only - not for customer deployments
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
```

## Project Structure

**Selected Structure**: **Option 2 - Terraform Infrastructure (Organized Files)**

**Rationale:**
- Modular organization for maintainability
- Clear separation of concerns (networking, compute, storage)
- Easy to understand and modify
- Suitable for template reuse across customers
- Supports variable customization per customer

### Directory Structure

```
pvs-poc-template/
├── README.md                          # Template overview and usage
├── main.tf                            # Root module - orchestrates all components
├── variables.tf                       # Input variables with defaults
├── outputs.tf                         # Output values (VPN config, endpoints)
├── versions.tf                        # Terraform and provider versions
├── terraform.tfvars.example           # Example variable values
├── .gitignore                         # Ignore state files, .terraform/
│
├── modules/                           # Custom wrapper modules
│   ├── powervs-workspace/            # PowerVS workspace setup
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── vpc-network/                   # VPC with subnet
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── transit-gateway/               # Transit Gateway connections
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── vpn-gateway/                   # VPN Gateway configuration
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   └── cos-storage/                   # COS bucket with VPE
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
├── examples/                          # Example deployments
│   └── customer-deployment/
│       ├── main.tf                    # Example using root module
│       ├── terraform.tfvars           # Customer-specific values
│       └── README.md
│
└── docs/                              # Documentation
    ├── architecture.md                # Architecture diagrams
    ├── deployment-guide.md            # Step-by-step deployment
    ├── customer-handoff.md            # VPN configuration guide
    └── teardown-guide.md              # Resource cleanup
```

### Key Files

**main.tf** (Root Module):
```hcl
# Orchestrates all infrastructure components
module "powervs_workspace" {
  source = "./modules/powervs-workspace"
  # ... configuration
}

module "vpc_network" {
  source = "./modules/vpc-network"
  # ... configuration
}

module "transit_gateway" {
  source = "./modules/transit-gateway"
  powervs_workspace_crn = module.powervs_workspace.crn
  vpc_id                = module.vpc_network.vpc_id
  # ... configuration
}

module "vpn_gateway" {
  source = "./modules/vpn-gateway"
  vpc_id = module.vpc_network.vpc_id
  # ... configuration
}

module "cos_storage" {
  source = "./modules/cos-storage"
  vpc_id = module.vpc_network.vpc_id
  # ... configuration
}
```

**variables.tf** (Input Variables):
```hcl
# Customer identification
variable "customer_id" {
  description = "Unique customer identifier for resource naming"
  type        = string
}

# Network configuration
variable "vpc_subnet_cidr" {
  description = "VPC subnet CIDR range"
  type        = string
  default     = "10.240.0.0/24"
}

variable "powervs_subnet_cidr" {
  description = "PowerVS subnet CIDR range"
  type        = string
  default     = "10.241.0.0/24"
}

# VPN configuration
variable "customer_vpn_peer_address" {
  description = "Customer VPN gateway public IP address"
  type        = string
}

variable "customer_vpn_preshared_key" {
  description = "VPN pre-shared key (sensitive)"
  type        = string
  sensitive   = true
}

variable "customer_on_prem_cidrs" {
  description = "Customer on-premises network CIDR ranges"
  type        = list(string)
}

# Storage configuration
variable "cos_bucket_name" {
  description = "COS bucket name"
  type        = string
  default     = "" # Generated if empty: {customer-id}-powervs-poc-{timestamp}
}
```

**outputs.tf** (Output Values):
```hcl
# VPN configuration for customer
output "vpn_gateway_public_ip" {
  description = "VPN Gateway public IP for customer configuration"
  value       = module.vpn_gateway.public_ip
}

output "vpn_connection_status" {
  description = "VPN connection status"
  value       = module.vpn_gateway.connection_status
}

# Network endpoints
output "powervs_workspace_id" {
  description = "PowerVS workspace ID"
  value       = module.powervs_workspace.workspace_id
}

output "cos_bucket_endpoint" {
  description = "COS bucket private endpoint"
  value       = module.cos_storage.private_endpoint
}

# Network information
output "vpc_subnet_cidr" {
  description = "VPC subnet CIDR"
  value       = var.vpc_subnet_cidr
}

output "powervs_subnet_cidr" {
  description = "PowerVS subnet CIDR"
  value       = var.powervs_subnet_cidr
}
```

**versions.tf** (Version Constraints):
```hcl
terraform {
  required_version = ">= 1.7.0"

  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "~> 1.63"
    }
  }

  backend "s3" {
    # COS backend configuration
  }
}

provider "ibm" {
  region = "eu-es"
  ibmcloud_api_key = var.ibmcloud_api_key
}
```

### Module Organization

Each module wraps official IBM Cloud Terraform modules with customer-specific configuration:

**modules/powervs-workspace/main.tf**:
```hcl
module "powervs_workspace" {
  source  = "terraform-ibm-modules/powervs-workspace/ibm"
  version = "~> 4.0"

  resource_group_id   = var.resource_group_id
  powervs_zone        = "mad02"
  powervs_subnet_name = "${var.customer_id}-powervs-subnet"
  powervs_subnet_cidr = var.powervs_subnet_cidr
  
  tags = var.tags
}
```

**modules/vpc-network/main.tf**:
```hcl
module "vpc" {
  source  = "terraform-ibm-modules/vpc/ibm"
  version = "~> 1.0"

  vpc_name              = "${var.customer_id}-vpc"
  resource_group_id     = var.resource_group_id
  classic_access        = false
  default_address_prefix = "manual"
  
  address_prefixes = [{
    name     = "${var.customer_id}-prefix"
    location = "eu-es-1"
    cidr     = var.vpc_subnet_cidr
  }]
  
  subnets = [{
    name            = "${var.customer_id}-subnet"
    zone            = "eu-es-1"
    cidr            = var.vpc_subnet_cidr
    public_gateway  = false
  }]
  
  tags = var.tags
}
```

### Usage Example

**examples/customer-deployment/terraform.tfvars**:
```hcl
# Customer: ACME Corporation
customer_id = "acme-corp"

# Network configuration
vpc_subnet_cidr      = "10.240.0.0/24"
powervs_subnet_cidr  = "10.241.0.0/24"

# VPN configuration (customer provides)
customer_vpn_peer_address  = "203.0.113.10"
customer_vpn_preshared_key = "SecurePreSharedKey123!"
customer_on_prem_cidrs     = ["10.10.0.0/24", "10.20.0.0/24"]

# Storage configuration
cos_bucket_name = "acme-corp-powervs-poc-20260205"

# IBM Cloud configuration
ibmcloud_api_key    = "YOUR_API_KEY_HERE" # Use environment variable
resource_group_name = "acme-corp-poc"
```

**Deployment Commands**:
```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Plan deployment
terraform plan -var-file=terraform.tfvars

# Apply infrastructure
terraform apply -var-file=terraform.tfvars

# Output VPN configuration for customer
terraform output vpn_gateway_public_ip
terraform output vpn_connection_status
```

## Implementation Notes

### Prerequisites
1. IBM Cloud account with appropriate permissions
2. Terraform 1.7.x or later installed
3. IBM Cloud CLI installed (optional, for verification)
4. Customer VPN endpoint details (public IP, pre-shared key, on-prem CIDRs)

### Deployment Steps
1. Clone template repository
2. Copy `terraform.tfvars.example` to `terraform.tfvars`
3. Fill in customer-specific values
4. Run `terraform init` to initialize providers and modules
5. Run `terraform plan` to review changes
6. Run `terraform apply` to provision infrastructure
7. Capture outputs for customer VPN configuration
8. Provide customer with VPN configuration guide

### Validation Steps
1. Verify all resources created in IBM Cloud console
2. Test network connectivity: VPC → Transit Gateway → PowerVS
3. Verify VPN gateway operational (ready for customer configuration)
4. Test COS access from VPC via VPE
5. Confirm network latency < 5ms between VPC and PowerVS
6. Validate security groups and routing tables

### Teardown Procedure
```bash
# Destroy all infrastructure
terraform destroy -var-file=terraform.tfvars

# Verify all resources removed
ibmcloud resource service-instances --output json | grep customer-id

# Clean up state file (optional)
# State retained in COS for audit purposes
```

## Cost Estimation

**Monthly Cost per Customer POC** (eu-es region):

| Component | Estimated Cost |
|-----------|---------------|
| PowerVS Workspace | $50-100 (base, no instances) |
| VPC | $0 (no compute) |
| Transit Gateway | $150-200 (local, 2 connections) |
| VPN Gateway | $100-150 (single gateway) |
| Cloud Object Storage | $5-10 (< 100 GB, minimal requests) |
| VPE Gateway | $10-20 |
| **Total** | **$315-480/month** |

**Notes:**
- Does not include PowerVS instance compute costs (customer-specific)
- Assumes minimal data transfer (< 1 TB/month)
- POC duration: 30-90 days
- Costs may vary based on actual usage

## Next Steps

1. **Review Plan**: Confirm architecture meets requirements
2. **Run `/iac.tasks`**: Break plan into implementation tasks
3. **Optional - Run `/iac.enrichplan`**: For deep research, detailed module configurations, and quickstart guide
4. **Begin Implementation**: Start with Terraform project structure
5. **Test Deployment**: Deploy first customer POC in test environment
6. **Document**: Create customer handoff documentation for VPN configuration

## References

- [IBM Cloud PowerVS Documentation](https://cloud.ibm.com/docs/power-iaas)
- [IBM Cloud Terraform Provider](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs)
- [terraform-ibm-modules GitHub](https://github.com/terraform-ibm-modules)
- [IBM Cloud VPN Gateway](https://cloud.ibm.com/docs/vpc?topic=vpc-using-vpn)
- [IBM Cloud Transit Gateway](https://cloud.ibm.com/docs/transit-gateway)