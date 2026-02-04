##############################################################################
# VPC Infrastructure Module
# 
# This module creates IBM Cloud VPC infrastructure using the official
# terraform-ibm-modules/landing-zone-vpc/ibm module.
#
# Resources created:
# - VPC with address prefixes
# - Subnets across availability zones
# - Security groups with custom rules
# - Network ACLs
# - Public gateways for internet access
# - VPN gateway for site-to-site connectivity
##############################################################################

terraform {
  required_version = ">= 1.3.0"
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = ">= 1.49.0"
    }
  }
}

##############################################################################
# VPC Module
##############################################################################

module "landing_zone_vpc" {
  source  = "terraform-ibm-modules/landing-zone-vpc/ibm"
  version = "8.7.0"

  # Core VPC Configuration
  resource_group_id = var.resource_group_id
  region            = var.region
  prefix            = var.prefix
  name              = "${var.prefix}-${var.vpc_name}"
  tags              = var.tags

  # Network Configuration
  # Create VPC with single subnet in one availability zone
  network_cidrs = [var.vpc_cidr]
  
  subnets = {
    zone-1 = [
      {
        name           = "subnet-a"
        cidr           = var.subnet_cidr
        public_gateway = var.enable_public_gateway
        acl_name       = "vpc-acl"
      }
    ]
  }

  # Network ACL Configuration
  network_acls = [
    {
      name              = "vpc-acl"
      add_ibm_cloud_internal_rules = true
      add_vpc_connectivity_rules   = true
      prepend_ibm_rules            = true
      
      rules = [
        {
          name        = "allow-all-inbound"
          action      = "allow"
          direction   = "inbound"
          destination = "0.0.0.0/0"
          source      = "0.0.0.0/0"
        },
        {
          name        = "allow-all-outbound"
          action      = "allow"
          direction   = "outbound"
          destination = "0.0.0.0/0"
          source      = "0.0.0.0/0"
        }
      ]
    }
  ]

  # Security Group Configuration
  security_group_rules = [
    {
      name      = "allow-inbound-ssh"
      direction = "inbound"
      remote    = "0.0.0.0/0"
      tcp = {
        port_min = 22
        port_max = 22
      }
    },
    {
      name      = "allow-inbound-https"
      direction = "inbound"
      remote    = "0.0.0.0/0"
      tcp = {
        port_min = 443
        port_max = 443
      }
    },
    {
      name      = "allow-outbound-all"
      direction = "outbound"
      remote    = "0.0.0.0/0"
    }
  ]

  # VPN Gateway Configuration
  # Creates a route-based VPN gateway attached to the subnet
  vpn_gateways = var.enable_vpn_gateway ? [
    {
      name        = "${var.prefix}-vpn-gateway"
      subnet_name = "subnet-a"
      mode        = "route"
      connections = []
    }
  ] : []

  # Security Best Practices
  # Remove permissive default security group and ACL rules
  clean_default_sg_acl = var.clean_default_sg_acl

  # VPC Flow Logs (optional, can be enabled for audit and troubleshooting)
  enable_vpc_flow_logs = var.enable_vpc_flow_logs
  create_authorization_policy_vpc_to_cos = var.enable_vpc_flow_logs
  existing_cos_instance_guid = var.enable_vpc_flow_logs ? var.cos_instance_guid : null
  existing_storage_bucket_name = var.enable_vpc_flow_logs ? var.flow_logs_bucket_name : null
}