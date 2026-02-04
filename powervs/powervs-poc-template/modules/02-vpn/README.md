# Site-to-Site VPN Module (Optional)

This module creates VPN gateway and connections for secure site-to-site connectivity.

## Module Information

- **Module Source**: `terraform-ibm-modules/site-to-site-vpn/ibm`
- **Version**: `3.0.4`
- **Purpose**: Secure connectivity to external networks

## Resources Created

- VPN Gateway
- VPN Connections
- IKE Policies
- IPSec Policies

## Dependencies

- VPC Infrastructure (vpc_id, subnet_id)

## Outputs

- `vpn_gateway_id`: VPN gateway identifier
- `vpn_connection_ids`: VPN connection identifiers

## Configuration

Set `enable_vpn = true` in terraform.tfvars to deploy this module.

*Implementation details will be added in the next phase.*
