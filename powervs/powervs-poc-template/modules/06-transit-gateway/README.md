# Transit Gateway Module

This module creates Transit Gateway to connect VPC and PowerVS networks.

## Module Information

- **Module Source**: `terraform-ibm-modules/transit-gateway/ibm`
- **Version**: `2.5.2`
- **Purpose**: Network connectivity between VPC and PowerVS

## Resources Created

- Transit Gateway
- VPC Connection
- PowerVS Connection

## Dependencies

- VPC Infrastructure (vpc_crn)
- PowerVS Workspace (workspace_id)

## Outputs

- `tg_id`: Transit Gateway identifier
- `tg_crn`: Transit Gateway CRN

*Implementation details will be added in the next phase.*
