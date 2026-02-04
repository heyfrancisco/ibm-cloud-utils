# PowerVS Workspace Module

This module creates PowerVS workspace with private subnets and SSH keys.

## Module Information

- **Module Source**: `terraform-ibm-modules/powervs-workspace/ibm`
- **Version**: `4.1.2`
- **Purpose**: PowerVS workspace foundation

## Resources Created

- PowerVS Workspace
- Private Subnet
- SSH Key

## Dependencies

None - Independent service

## Outputs

- `pi_workspace_guid`: Workspace GUID
- `pi_workspace_id`: Workspace ID
- `pi_ssh_public_key_name`: SSH key name
- `pi_private_subnet_1`: Private subnet details

*Implementation details will be added in the next phase.*
