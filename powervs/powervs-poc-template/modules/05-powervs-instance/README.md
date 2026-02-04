# PowerVS Instance Module

This module creates PowerVS LPAR instances.

## Module Information

- **Module Source**: `terraform-ibm-modules/powervs-instance/ibm`
- **Version**: `2.8.2`
- **Purpose**: PowerVS compute instances

## Resources Created

- PowerVS LPAR Instance
- Storage volumes

## Dependencies

- PowerVS Workspace (workspace_guid, ssh_key, networks)

## Outputs

- `pi_instance_id`: Instance identifier
- `pi_instance_private_ips`: Instance private IPs

*Implementation details will be added in the next phase.*
