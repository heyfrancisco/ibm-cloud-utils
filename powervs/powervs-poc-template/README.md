# IBM Cloud - PowerVS Landing Zone Template

A comprehensive Terraform-based landing zone for IBM Cloud that creates a hybrid cloud infrastructure foundation connecting VPC with PowerVS workspace through Transit Gateway, with secure VPN access and private Cloud Object Storage connectivity.

**This landing zone provides the infrastructure foundation only.** Users can deploy their own LPAR instances after the workspace is ready.

## 🏗️ Architecture Overview

This landing zone deploys the following components:

- **Module 01: VPC Infrastructure**: Foundation network with subnets, security groups, and network ACLs
- **Module 02: Site-to-Site VPN** (Optional): Secure connectivity for external access (deployed after VPC)
- **Module 03: Cloud Object Storage**: Object storage with encryption
- **Module 04: Transit Gateway** (Optional): Bridges VPC and PowerVS networks with local routing
- **Module 05: PowerVS Workspace** (Optional): IBM Power Systems Virtual Server workspace with private networking (ready for LPAR deployment)

```
┌─────────────────────────────────────────────────────────────────┐
│                             IBM Cloud                           │
│                                                                 │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                    VPC (Single Region)                     │ │
│  │  ┌──────────────┐      ┌─────────────────┐                 │ │
│  │  │   Subnet     │      │  Security Group │                 │ │
│  │  │  (1 Zone)    │      │  - SSH (22)     │                 │ │
│  │  │              │      │  - HTTPS (443)  │                 │ │
│  │  └──────────────┘      └─────────────────┘                 │ │
│  │         │              ┌─────────────────┐                 │ │     ┌─────────┐
│  │         └──────────────│  VPN Gateway    │──────────────────────── │ ON-PREM │
│  │                        │  (Optional)     │                 │ │     └─────────┘
│  │                        └─────────────────┘                 │ │
│  └─────────────────────────────────┼──────────────────────────┘ │
│                    ┌───────────────┴───────────────┐            │
│                    │  Transit Gateway (Optional)   │            │
│                    └───────────────┬───────────────┘            │
│  ┌─────────────────────────────────┼──────────────────────────┐ │
│  │        PowerVS Workspace (Optional)                        │ │
│  │  ┌──────────────────┐                                      │ │
│  │  │  Private Subnet  │                                      │ │
│  │  │                  │                                      │ │
│  │  │  + SSH Key       │                                      │ │
│  │  └──────────────────┘                                      │ │
│  └────────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │              Cloud Object Storage (COS)                    │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘

Note: This landing zone creates the infrastructure foundation.
      VPN, Transit Gateway, and PowerVS Workspace are optional components.
      VPN is deployed after VPC but before COS.
      Users can deploy LPAR instances using the workspace after deployment.
```

## 📋 Prerequisites

Before you begin, ensure you have:

1. **IBM Cloud Account**
   - Active IBM Cloud account with appropriate permissions
   - Resource group created or identified
   - Sufficient quota for VPC, PowerVS, and other services

2. **IBM Cloud API Key**
   - API key with permissions to create resources
   - Set as environment variable: `export IC_API_KEY="your-api-key"`

3. **Tools Installed**
   - Terraform >= 1.3.0 ([Download](https://www.terraform.io/downloads))
   - IBM Cloud CLI ([Install](https://cloud.ibm.com/docs/cli))
   - SSH key pair for instance access

4. **Network Planning**
   - VPC CIDR range (default: 10.10.10.0/24)
   - PowerVS subnet CIDR (default: 192.168.100.0/24)
   - Ensure no conflicts with existing networks

## 🚀 Quick Start

### 1. Clone or Download

```bash
# If using git
git clone <repository-url>
cd ibm-cloud-landing-zone

# Or download and extract the files
```

### 2. Configure Variables

```bash
# Copy the template
cp terraform.tfvars.template terraform.tfvars

# Edit with your values
vi terraform.tfvars
```

**Required Variables:**
- `prefix`: Unique identifier for resources (max 20 chars)
- `resource_group_name`: Target resource group name
- `powervs_ssh_key_name`: SSH key name for PowerVS workspace
- `powervs_ssh_public_key`: SSH public key content for PowerVS workspace

### 3. Set IBM Cloud API Key

```bash
export IC_API_KEY="your-ibm-cloud-api-key"
```

### 4. Initialize Terraform

```bash
terraform init
```

### 5. Review the Plan

```bash
terraform plan
```

Review the output carefully to ensure all resources are configured correctly.

### 6. Deploy

```bash
terraform apply
```

Type `yes` when prompted to confirm the deployment.

### 7. Verify Deployment

```bash
# View outputs
terraform output
```

## 📁 Project Structure

```
.
├── README.md                        # This file
├── provider.tf                      # IBM Cloud provider configuration
├── versions.tf                      # Terraform and provider versions
├── variables.tf                     # Variable definitions
├── terraform.tfvars.template        # Variable values template
├── main.tf                          # Root module orchestration (uses registry modules)
├── outputs.tf                       # Root outputs
│
└── docs/                            # Additional documentation
    ├── IMPLEMENTATION_PLAN.md         # Detailed implementation guide
    ├── TROUBLESHOOTING.md             # Common issues and solutions
    └── MONITORING.md                  # Monitoring and maintenance

```

**Note:** This template uses IBM Cloud Terraform modules directly from the registry without local module wrappers. All module configurations are in the root `main.tf` file.

## 🔧 Configuration

### Deployment Order

Modules are deployed in the following order due to dependencies:

1. **Module 01: VPC Infrastructure** → Provides network foundation
2. **Module 02: Site-to-Site VPN** (Optional) → Secure connectivity for external access (requires VPC)
3. **Module 03: Cloud Object Storage** → Independent service
4. **Module 04: Transit Gateway** (Optional) → Requires VPC
5. **Module 05: PowerVS Workspace** (Optional) → Requires Transit Gateway (if enabled)

**Note:** After deployment, users can create LPAR instances in the PowerVS workspace using:
- IBM Cloud Console
- IBM Cloud CLI: `ibmcloud pi instance-create`
- Terraform (separate configuration)
- REST API

### Resource Naming

All resources follow the naming convention:
```
${var.prefix}-${resource_type}-${identifier}
```

Examples:
- VPC: `myproject-vpc`
- Subnet: `myproject-subnet-zone-1`
- PowerVS Workspace: `myproject-pvs-ws`
- Transit Gateway: `myproject-tgw`
- COS Instance: `myproject-cos`

## 📖 Detailed Documentation

- **[docs/IMPLEMENTATION_PLAN.md](docs/IMPLEMENTATION_PLAN.md)**: Complete implementation guide with step-by-step instructions
- **[docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)**: Common issues and solutions
- **[docs/MONITORING.md](docs/MONITORING.md)**: Monitoring and maintenance guide

## 🔐 Security Best Practices

1. **API Key Management**
   - Never commit API keys to version control
   - Use environment variables or secrets management
   - Rotate keys regularly

2. **SSH Keys**
   - Use strong SSH keys (RSA 4096-bit or ED25519)
   - Protect private keys with passphrases
   - Rotate keys periodically

3. **VPN Configuration**
   - Use strong preshared keys (minimum 32 characters)
   - Enable IKEv2 for better security
   - Restrict peer CIDR ranges

4. **Encryption**
   - Enable encryption for COS buckets
   - Use Key Protect or HPCS for key management
   - Enable encryption in transit

5. **Network Security**
   - Follow principle of least privilege for security groups
   - Use network ACLs for additional protection
   - Regularly review and audit rules

## 🗑️ Cleanup

To destroy all resources:

```bash
# Review what will be destroyed
terraform plan -destroy

# Destroy resources
terraform destroy
```

**⚠️ Warning**: This will permanently delete all resources. Ensure you have backups of any important data.

## 📚 Additional Resources

- [IBM Cloud Documentation](https://cloud.ibm.com/docs)
- [IBM Cloud VPC](https://cloud.ibm.com/docs/vpc)
- [IBM Cloud PowerVS](https://cloud.ibm.com/docs/power-iaas)
- [IBM Cloud Transit Gateway](https://cloud.ibm.com/docs/transit-gateway)
- [Terraform IBM Cloud Provider](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs)