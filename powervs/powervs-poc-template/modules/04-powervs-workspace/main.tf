##############################################################################
# PowerVS Workspace Module
# 
# This module creates IBM Cloud PowerVS Workspace using the official
# terraform-ibm-modules/powervs-workspace/ibm module.
#
# Resources created:
# - PowerVS workspace in specified zone
# - Private subnet with custom DNS
# - SSH key for instance access
# - Optional Transit Gateway connection
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
# PowerVS Workspace Module
##############################################################################

module "powervs_workspace" {
  source  = "terraform-ibm-modules/powervs-workspace/ibm"
  version = "4.1.2"

  # Workspace Configuration
  pi_workspace_name     = "${var.prefix}-powervs-workspace"
  pi_zone               = var.powervs_zone
  pi_resource_group_id  = var.resource_group_id
  pi_tags               = var.tags

  # SSH Key Configuration
  # Create SSH key for PowerVS instance access
  pi_ssh_public_key = {
    name  = "${var.prefix}-${var.powervs_ssh_key_name}"
    value = var.powervs_ssh_public_key
  }

  # Private Subnet Configuration
  # Create private subnet with advertisement to Transit Gateway
  pi_private_subnet_1 = {
    name      = "${var.prefix}-powervs-subnet"
    cidr      = var.powervs_subnet_cidr
    dns_servers = var.powervs_dns_servers
  }

  # No additional subnets needed
  pi_private_subnet_2 = null
  pi_private_subnet_3 = null

  # Transit Gateway Connection
  # This will be configured after Transit Gateway is created
  pi_transit_gateway_connection = var.enable_transit_gateway ? {
    enable             = true
    transit_gateway_id = var.transit_gateway_id
  } : {
    enable             = false
    transit_gateway_id = null
  }
}