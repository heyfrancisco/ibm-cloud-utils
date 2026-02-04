# IBM Cloud SCC Workload Protection POC (Terraform)

This configuration provisions a minimal IBM Cloud environment to test Secure Cloud Connect Workload Protection (SCC WP):
- VPC with manual address prefix, subnet, and basic security group rules (SSH 22, RDP 3389, outbound allow).
- One Linux and one Windows VSI, each with a floating IP and the provided SSH key.
- An SCC Workload Protection instance using the IBM Cloud catalog module.

State is stored locally in `terraform.tfstate`.

## Prerequisites
- Terraform 1.5+ installed locally.
- IBM Cloud account with an API key that can create VPC infrastructure, floating IPs, and SCC WP instances in the target region.
- Existing IBM Cloud resource group (referenced by name).
- Existing VPC SSH key in the target region (referenced by name).
- Valid image names available in the target region (e.g., `ibm-ubuntu-22-04-3-minimal-amd64-1`, `ibm-windows-server-2022-full-standard-amd64-12`).

## Configuration
Create a tfvars file (keep it out of version control). Example skeleton:

```json
{
  "ibmcloud_api_key": "REPLACE_ME",
  "region": "eu-es",
  "resource_group_name": "my-resource-group",
  "prefix": "sccwp-demo",
  "tags": ["env:sccwp-demo"],
  "ssh_key_name": "my-ssh-key",
  "linux_image_name": "ibm-ubuntu-22-04-3-minimal-amd64-1",
  "windows_image_name": "ibm-windows-server-2022-full-standard-amd64-12",
  "instance_profile": "cxf-2x4",
  "vpc_cidr": "10.10.0.0/16",
  "subnet_cidr": "10.10.10.0/24",
  "zone": "eu-es-1",
  "sccwp_service_plan": "graduated-tier"
}
```

Key variables:
- `ibmcloud_api_key` (required) – IBM Cloud API key; do not commit to git.
- `region`, `zone` – IBM Cloud region/zone for all resources.
- `resource_group_name` – Existing resource group name.
- `ssh_key_name` – Existing VPC SSH key name in the chosen region.
- `linux_image_name`, `windows_image_name` – Existing image names in the region.
- `instance_profile` – VSI profile (defaults to `nxf-2x2` if not overridden).
- `sccwp_service_plan` – SCC WP plan (default `graduated-tier`).

## Usage
From `infra/`:

```bash
terraform init
terraform plan -var-file=./my.tfvars.json
terraform apply -var-file=./my.tfvars.json
```

If you prefer environment variables, export `TF_VAR_ibmcloud_api_key` instead of placing the API key in the tfvars file.

## Outputs
After `apply`, Terraform prints:
- `vpc_id`, `subnet_id`, `security_group_id`
- `linux_public_ip`, `windows_public_ip`
- `linux_private_ip`, `windows_private_ip`
- `ssh_key_name`

## Cleanup
Destroy the environment when finished to avoid ongoing charges:

```bash
terraform destroy -var-file=./my.tfvars.json
```
