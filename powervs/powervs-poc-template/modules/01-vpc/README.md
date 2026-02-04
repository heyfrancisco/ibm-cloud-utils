# VPC Infrastructure Module

This module creates the VPC infrastructure including subnets, security groups, and network ACLs.

## Module Information

- **Module Source**: `terraform-ibm-modules/landing-zone-vpc/ibm`
- **Version**: `8.7.0`
- **Purpose**: Foundation network layer for the landing zone

## Resources Created

- VPC with address prefixes
- Subnet in specified availability zone
- Security groups with rules
- Network ACLs
- Public gateway (optional)

## Dependencies

None - This is the foundation layer

## Outputs

- `vpc_id`: VPC identifier
- `vpc_crn`: VPC Cloud Resource Name
- `subnet_ids`: List of subnet IDs
- `subnet_zone_list`: Subnet zone mapping
- `security_group_ids`: Security group IDs

## Next Steps

After VPC deployment:
1. Deploy VPN module (optional)
2. Deploy COS module
3. Deploy PowerVS workspace
4. Deploy Transit Gateway
5. Deploy VPE Gateway

## Configuration Files

- `main.tf`: Module configuration
- `variables.tf`: Input variables
- `outputs.tf`: Output definitions

*Implementation details will be added in the next phase.*