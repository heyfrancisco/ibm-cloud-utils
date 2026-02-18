# AGENTS.md

This file provides guidance to agents when working with code in this repository.

## Project Overview

This is an **IBM Cloud PowerVS Landing Zone Template** - a comprehensive Terraform-based infrastructure-as-code solution that creates a hybrid cloud foundation connecting VPC with PowerVS workspace through Transit Gateway. The landing zone provides the infrastructure foundation only; users deploy their own LPAR instances after the workspace is ready.

### Key Technologies

- **Terraform** >= 1.3.0
- **IBM Cloud Provider** ~> 1.60
- **IBM Cloud Services**: VPC, PowerVS, Transit Gateway, Cloud Object Storage, VPN Gateway
- **IBM Cloud Terraform Modules**: Uses official registry modules directly (no local wrappers)

### Architecture Components

The landing zone deploys infrastructure in a specific order due to dependencies:

1. **VPC Infrastructure** (Module 01): Foundation network with subnets, security groups, network ACLs
2. **Site-to-Site VPN** (Module 02, Optional): Secure connectivity for external access
3. **Cloud Object Storage** (Module 03): Object storage with encryption and lifecycle policies
4. **Transit Gateway** (Module 04, Optional): Bridges VPC and PowerVS networks with local routing
5. **PowerVS Workspace** (Module 05, Optional): IBM Power Systems Virtual Server workspace with private networking

**Important**: This template creates infrastructure only. LPAR instances are deployed separately by users using IBM Cloud Console, CLI, Terraform, or API.

## Building and Running

### Prerequisites

```bash
# Required tools
terraform >= 1.3.0
ibmcloud CLI

# Required credentials
export IC_API_KEY="your-ibm-cloud-api-key"
```

### Configuration

```bash
# 1. Copy template and configure variables
cp terraform.tfvars.template terraform.tfvars
vi terraform.tfvars

# Required variables to set:
# - prefix: Unique identifier (max 20 chars)
# - resource_group_name: Target resource group
# - powervs_ssh_key_name: SSH key name
# - powervs_ssh_public_key: SSH public key content
```

### Deployment Commands

```bash
# Initialize Terraform and download providers/modules
terraform init

# Review planned changes
terraform plan

# Deploy infrastructure
terraform apply

# View outputs
terraform output

# Destroy all resources (WARNING: permanent deletion)
terraform destroy
```

### Post-Deployment

After successful deployment, users can create LPAR instances in the PowerVS workspace using:
- IBM Cloud Console
- IBM Cloud CLI: `ibmcloud pi instance-create`
- Terraform (separate configuration)
- REST API

## Development Conventions

### Resource Naming Convention

All resources follow a consistent naming pattern:
```
${var.prefix}-${resource_type}-${identifier}
```

Examples:
- VPC: `myproject-vpc`
- Subnet: `myproject-subnet-zone-1`
- PowerVS Workspace: `myproject-pvs-ws`
- Transit Gateway: `myproject-tgw`
- COS Instance: `myproject-cos`

### Module Usage Pattern

This template uses IBM Cloud Terraform modules **directly from the registry** without local module wrappers. All module configurations are in the root `main.tf` file.

**Module Versions Used:**
- `terraform-ibm-modules/landing-zone-vpc/ibm`: 8.7.0
- `terraform-ibm-modules/site-to-site-vpn/ibm`: 3.0.4
- `terraform-ibm-modules/cos/ibm`: 10.5.0
- `terraform-ibm-modules/transit-gateway/ibm`: 2.5.2
- `terraform-ibm-modules/powervs-workspace/ibm`: 4.1.2

### Variable Organization

Variables are organized by category in `variables.tf`:
- **Global Variables**: prefix, region, resource groups, tags
- **VPC Variables**: networking configuration
- **VPN Variables**: site-to-site connectivity (optional)
- **COS Variables**: storage configuration
- **PowerVS Variables**: workspace and subnet configuration
- **Transit Gateway Variables**: network connectivity

### Provider Configuration

Two provider instances are configured:
1. **Default provider**: For VPC, COS, Transit Gateway (uses `region`)
2. **PowerVS provider** (alias: `powervs`): For PowerVS resources (uses `zone`)

### Security Best Practices

When working with this codebase:

1. **Never commit sensitive data**:
   - API keys should use environment variable `IC_API_KEY`
   - `terraform.tfvars` is gitignored
   - SSH keys marked as sensitive in variables

2. **VPN Security**:
   - Preshared keys must be minimum 32 characters
   - IKEv2 is default (more secure than IKEv1)
   - Validation enforces key length requirements

3. **Encryption**:
   - COS encryption can be enabled with Key Protect/HPCS
   - KMS key CRN required when encryption enabled

4. **Network Security**:
   - Security groups follow least-privilege principle
   - Network ACLs provide additional protection
   - CIDR validation prevents invalid configurations

### File Structure

```
.
├── main.tf                      # Root module orchestration (all module calls)
├── variables.tf                 # Variable definitions with validation
├── outputs.tf                   # Aggregated outputs from all modules
├── provider.tf                  # IBM Cloud provider configuration + data sources
├── versions.tf                  # Terraform and provider version constraints
├── terraform.tfvars.template    # Variable values template with examples
└── README.md                    # Comprehensive documentation
```

### Validation Rules

The codebase includes extensive validation:
- Prefix length (1-20 chars) and format (lowercase, numbers, hyphens)
- CIDR block format validation
- Enum value validation (regions, zones, plans)
- VPN preshared key length enforcement (min 32 chars)
- PowerVS subnet count (1-3 subnets)

### Deployment Dependencies

Modules have explicit dependencies managed through `depends_on`:
- VPN depends on VPC
- Transit Gateway depends on VPC
- PowerVS Workspace depends on Transit Gateway (if enabled)

### Optional Components

Several components are optional and controlled by feature flags:
- `enable_vpn_gateway`: Enable VPN gateway and connections
- `enable_transit_gateway`: Enable Transit Gateway
- `enable_powervs`: Enable PowerVS workspace
- `enable_vpc_flow_logs`: Enable VPC flow logs
- `cos_encryption_enabled`: Enable COS encryption with KMS

### Testing Approach

When testing changes:
1. Always run `terraform plan` first to review changes
2. Test in non-production environment
3. Verify outputs after deployment
4. Check resource naming follows conventions
5. Validate network connectivity between components

### Common Customization Points

When customizing this template:
- **Network CIDRs**: Ensure no conflicts with existing networks
- **Resource Groups**: Can use separate groups per module
- **Tags**: Customize for cost tracking and organization
- **PowerVS Subnets**: Supports 1-3 subnets with dynamic configuration
- **VPN Connections**: Supports multiple site-to-site connections
- **Storage Classes**: Choose appropriate COS storage class

### Troubleshooting

Common issues and solutions:
- **API Key Issues**: Ensure `IC_API_KEY` environment variable is set
- **Region/Zone Mismatch**: Verify PowerVS zone is compatible with VPC region
- **CIDR Conflicts**: Check for overlapping network ranges
- **Module Version Issues**: Run `terraform init -upgrade` to update modules
- **Resource Group Not Found**: Verify resource group exists in account

## Important Notes

1. **No Local Module Wrappers**: This template uses registry modules directly. Previous versions may have used local wrappers, but they have been removed for simplicity.

2. **Infrastructure Only**: This is a landing zone template that creates the foundation. LPAR instances are not deployed automatically.

3. **Multi-Provider Setup**: PowerVS requires a separate provider configuration with zone-specific endpoints.

4. **State Management**: Consider using remote state storage (IBM COS or Terraform Cloud) for production deployments.

5. **Version Pinning**: For production, consider using exact versions instead of `~>` constraints.

## References

- [IBM Cloud Terraform Provider Documentation](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs)
- [IBM Cloud VPC Documentation](https://cloud.ibm.com/docs/vpc)
- [IBM Cloud PowerVS Documentation](https://cloud.ibm.com/docs/power-iaas)
- [IBM Cloud Transit Gateway Documentation](https://cloud.ibm.com/docs/transit-gateway)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)
