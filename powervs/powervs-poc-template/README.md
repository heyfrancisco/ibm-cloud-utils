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

### VPN Policy Customization

The VPN gateway supports customization of IKE (Internet Key Exchange) and IPSec policies to meet specific security requirements or compliance needs. When VPN is enabled, a **shared IKE policy and IPSec policy** are created and applied to all VPN connections. If not specified, secure default values are used.

#### IKE Policy Configuration

| Variable | Description | Default | Valid Options |
|----------|-------------|---------|---------------|
| `ike_authentication_algorithm` | IKE authentication algorithm | `sha256` | `sha256`, `sha384`, `sha512` |
| `ike_encryption_algorithm` | IKE encryption algorithm | `aes256` | `aes128`, `aes192`, `aes256` |
| `ike_dh_group` | Diffie-Hellman group for key exchange | `14` | `14`, `15`, `16`, `17`, `18`, `19`, `20`, `21`, `22`, `23`, `24`, `31` |
| `ike_key_lifetime` | IKE key lifetime in seconds | `28800` | `300`-`86400` |

#### IPSec Policy Configuration

| Variable | Description | Default | Valid Options |
|----------|-------------|---------|---------------|
| `ipsec_authentication_algorithm` | IPSec authentication algorithm | `sha256` | `sha256`, `sha384`, `sha512`, `disabled` |
| `ipsec_encryption_algorithm` | IPSec encryption algorithm | `aes256` | `aes128`, `aes192`, `aes256`, `aes128gcm16`, `aes192gcm16`, `aes256gcm16` |
| `ipsec_pfs` | Perfect Forward Secrecy group | `group_14` | `disabled`, `group_2`, `group_5`, `group_14` |
| `ipsec_key_lifetime` | IPSec key lifetime in seconds | `3600` | `300`-`86400` |

#### Configuration Examples

**Using default policies (recommended for most use cases):**
```hcl
# In terraform.tfvars
enable_vpn_gateway = true

vpn_connections = [
  {
    name          = "office-to-cloud"
    peer_address  = "203.0.113.10"
    preshared_key = "your-secure-32-character-key-here"
    local_cidrs   = ["10.10.10.0/24"]
    peer_cidrs    = ["192.168.1.0/24"]
  }
]

# Policies will use secure defaults:
# IKE: sha256, aes256, DH group 14, 28800s lifetime
# IPSec: sha256, aes256, group_14 PFS, 3600s lifetime
```

**Custom stronger encryption for high-security environments:**
```hcl
# In terraform.tfvars
enable_vpn_gateway = true

# IKE Policy - Stronger settings
ike_authentication_algorithm = "sha384"
ike_encryption_algorithm     = "aes256"
ike_dh_group                 = 19
ike_key_lifetime             = 14400

# IPSec Policy - Stronger settings with GCM
ipsec_authentication_algorithm = "sha384"
ipsec_encryption_algorithm     = "aes256gcm16"
ipsec_pfs                      = "group_14"
ipsec_key_lifetime             = 7200

vpn_connections = [
  {
    name          = "datacenter-to-cloud"
    peer_address  = "198.51.100.20"
    preshared_key = "another-secure-32-character-key"
    local_cidrs   = ["10.10.10.0/24"]
    peer_cidrs    = ["172.16.0.0/16"]
  }
]
```

**Multiple VPN connections sharing the same policies:**
```hcl
# In terraform.tfvars
enable_vpn_gateway = true

# Single shared policy configuration
ike_authentication_algorithm = "sha256"
ike_encryption_algorithm     = "aes256"
ike_dh_group                 = 14
ike_key_lifetime             = 28800

ipsec_authentication_algorithm = "sha256"
ipsec_encryption_algorithm     = "aes256"
ipsec_pfs                      = "group_14"
ipsec_key_lifetime             = 3600

# Multiple connections use the same policies
vpn_connections = [
  {
    name          = "office-to-cloud"
    peer_address  = "203.0.113.10"
    preshared_key = "first-secure-32-character-key-here"
    local_cidrs   = ["10.10.10.0/24"]
    peer_cidrs    = ["192.168.1.0/24"]
  },
  {
    name          = "datacenter-to-cloud"
    peer_address  = "198.51.100.20"
    preshared_key = "second-secure-32-character-key-here"
    local_cidrs   = ["10.10.10.0/24"]
    peer_cidrs    = ["172.16.0.0/16"]
  }
]
```

#### Security Recommendations

- **Authentication Algorithms**: Use SHA256 or higher (SHA384, SHA512) for production environments. SHA256 provides good security with reasonable performance.

- **Encryption Algorithms**:
  - AES256 provides strong encryption for most use cases
  - GCM modes (e.g., `aes256gcm16`) offer better performance with authenticated encryption
  - GCM modes combine encryption and authentication in a single operation

- **Diffie-Hellman Groups**:
  - Use group 14 (2048-bit) or higher for adequate security
  - Groups 19-24 (elliptic curve groups) provide stronger security with better performance
  - Group 31 is also available for specific requirements

- **Key Lifetimes**:
  - Shorter lifetimes (e.g., 3600-7200 seconds) provide better security through more frequent key rotation
  - Longer lifetimes reduce overhead but may increase risk if keys are compromised
  - Balance security needs with performance requirements

- **Perfect Forward Secrecy (PFS)**:
  - Always enable PFS (group_14 recommended) to ensure session keys cannot be compromised even if long-term keys are
  - PFS ensures that past communications remain secure even if future keys are compromised
  - Only disable PFS if required for compatibility with legacy systems

- **Preshared Keys**:
  - Must be at least 32 characters (enforced by validation)
  - Use strong, randomly generated keys
  - Never reuse keys across different connections
  - Store keys securely (use environment variables or secrets management)

#### Important Notes

- **Shared Policies**: All VPN connections in this deployment share the same IKE and IPSec policies. If you need different policies for different connections, deploy separate landing zones or use the IBM Cloud Console/CLI to create custom policies.

- **Policy Compatibility**: Ensure your on-premises VPN gateway supports the chosen algorithms and settings. Mismatched policies will prevent VPN tunnel establishment.

- **IKE Version**: This template uses IKEv2 by default, which is more secure and efficient than IKEv1. Ensure your peer gateway supports IKEv2.

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