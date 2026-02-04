# VPE Gateway Module

This module creates VPE Gateway for private connectivity to cloud services.

## Module Information

- **Module Source**: `terraform-ibm-modules/vpe-gateway/ibm`
- **Version**: `4.7.12`
- **Purpose**: Private connectivity to COS

## Resources Created

- VPE Gateway
- Service bindings

## Dependencies

- VPC Infrastructure (vpc_id, subnet_zone_list)
- COS (instance_crn)

## Outputs

- `vpe_ips`: VPE private IPs
- `crn`: VPE Gateway CRN

*Implementation details will be added in the next phase.*
