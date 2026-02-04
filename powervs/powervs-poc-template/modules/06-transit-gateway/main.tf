##############################################################################
# Transit Gateway Module
# 
# This module creates IBM Cloud Transit Gateway using the official
# terraform-ibm-modules/transit-gateway/ibm module.
#
# Resources created:
# - Transit Gateway with local or global routing
# - VPC connection
# - Optional prefix filters for route control
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
# Transit Gateway Module
##############################################################################

module "transit_gateway" {
  source  = "terraform-ibm-modules/transit-gateway/ibm"
  version = "2.5.2"

  # Transit Gateway Configuration
  transit_gateway_name = "${var.prefix}-${var.transit_gateway_name}"
  region               = var.region
  resource_group_id    = var.resource_group_id
  global_routing       = var.enable_global_routing

  # VPC Connection
  # Connect VPC to Transit Gateway for routing
  vpc_connections = [
    {
      vpc_id                = var.vpc_id
      vpc_crn               = var.vpc_crn
      connection_name       = "${var.prefix}-vpc-connection"
      network_type          = "vpc"
      base_connection_type  = "vpc"
    }
  ]

  # Classic Infrastructure Connections (not needed)
  classic_connections_count = 0

  # Resource Tags
  resource_tags = var.tags
}