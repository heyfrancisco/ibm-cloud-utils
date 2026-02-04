# IBM Cloud Terraform Landing Zone

A comprehensive Terraform-based landing zone for IBM Cloud that creates a hybrid cloud infrastructure connecting VPC with PowerVS workloads through Transit Gateway, with secure VPN access and private Cloud Object Storage connectivity.

## 🏗️ Architecture Overview

This landing zone deploys the following components:

- **VPC Infrastructure**: Foundation network with subnets, security groups, and network ACLs
- **Site-to-Site VPN** (Optional): Secure connectivity for external access
- **Cloud Object Storage**: Object storage with encryption and private connectivity
- **PowerVS Workspace**: IBM Power Systems Virtual Server workspace with private networking
- **PowerVS Instance**: LPAR instances running on PowerVS
- **Transit Gateway**: Bridges VPC and PowerVS networks with local routing
- **VPE Gateway**: Private connectivity between VPC and cloud services (COS)

```
┌─────────────────────────────────────────────────────────────────┐
│                        IBM Cloud Account                        │
│                                                                 │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                    VPC (Single Region)                     │ │
│  │  ┌──────────────┐      ┌─────────────────┐                 │ │
│  │  │   Subnet     │      │  Security Group │                 │ │
│  │  │  (1 Zone)    │      │  - SSH (22)     │                 │ │
│  │  │              │      │  - HTTPS (443)  │                 │ │
│  │  └──────────────┘      └─────────────────┘                 │ │
│  │         │              ┌─────────────────┐                 │ │
│  │         └──────────────│  VPN Gateway    │                 │ │
│  │                        │  (Site-to-Site) │                 │ │
│  │                        └─────────────────┘                 │ │
│  └─────────────────────────────────┼──────────────────────────┘ │
│                    ┌───────────────┴───────────────┐            │
│                    │    Transit Gateway (Local)    │            │
│                    └───────────────┬───────────────┘            │
│  ┌─────────────────────────────────┼──────────────────────────┐ │
│  │              PowerVS Workspace  │                          │ │
│  │  ┌──────────────────┐    ┌─────┴──────────┐                │ │
│  │  │  Private Subnet  │    │  PowerVS LPAR  │                │ │
│  │  └──────────────────┘    └────────────────┘                │ │
│  └────────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │              Cloud Object Storage (COS)                    │ │
│  │              ┌─────────┴─────────┐                         │ │
│  │              │  VPE Gateway      │                         │ │
│  │              │  (Private Access) │                         │ │
│  │              └───────────────────┘                         │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
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
- `resource_group_id`: Target resource group ID
- `powervs_ssh_key_name`: SSH key name
- `powervs_ssh_public_key`: SSH public key content
- `powervs_instance_image`: PowerVS instance image

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
├── main.tf                          # Root module (to be created)
├── outputs.tf                       # Root outputs (to be created)
│
├── modules/                         # Terraform modules
│   ├── 01-vpc/                        # VPC Infrastructure
│   ├── 02-vpn/                        # Site-to-Site VPN (Optional)
│   ├── 03-cos/                        # Cloud Object Storage
│   ├── 04-powervs-workspace/          # PowerVS Workspace
│   ├── 05-powervs-instance/           # PowerVS Instance
│   ├── 06-transit-gateway/            # Transit Gateway
│   └── 07-vpe-gateway/                # VPE Gateway
│
├── scripts/                         # Utility scripts
│   ├── verify-connectivity.sh         # Network connectivity tests
│   ├── verify-security.sh             # Security validation
│   └── verify-resources.sh            # Resource verification
│
└── docs/                            # Additional documentation
    ├── TROUBLESHOOTING.md             # Common issues and solutions
    ├── MONITORING.md                  # Monitoring and maintenance
    └── IMPLEMENTATION_PLAN.md         # Detailed implementation guide

```

## 🔧 Configuration

### Deployment Order

Modules are deployed in the following order due to dependencies:

1. **VPC Infrastructure** → Provides network foundation
2. **Site-to-Site VPN** (Optional) → Requires VPC
3. **Cloud Object Storage** → Independent service
4. **PowerVS Workspace** → Independent service
5. **PowerVS Instance** → Requires workspace
6. **Transit Gateway** → Requires VPC and PowerVS workspace
7. **VPE Gateway** → Requires VPC and COS

### Resource Naming

All resources follow the naming convention:
```
${var.prefix}-${resource_type}-${identifier}
```

Examples:
- VPC: `myproject-vpc`
- Subnet: `myproject-subnet-zone-1`
- PowerVS Instance: `myproject-powervs-lpar`
- Transit Gateway: `myproject-tgw`

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