##############################################################################
# VPE Gateway Module
# 
# This module creates IBM Cloud Virtual Private Endpoint (VPE) Gateway using
# the official terraform-ibm-modules/vpe-gateway/ibm module.
#
# Resources created:
# - VPE gateway for Cloud Object Storage
# - Reserved IP configuration
# - Security group binding
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
# VPE Gateway Module
##############################################################################

module "vpe_gateway" {
  source  = "terraform-ibm-modules/vpe-gateway/ibm"
  version = "4.7.12"

  # VPE Gateway Configuration
  resource_group_id = var.resource_group_id
  vpc_id            = var.vpc_id
  vpc_name          = var.vpc_name
  prefix            = var.prefix

  # Cloud Service Connection
  # Connect to Cloud Object Storage via private endpoint
  cloud_service_by_crn = [{
    crn = var.cos_instance_crn
  }]

  # Subnet Configuration
  # Attach VPE gateway to VPC subnet
  subnet_zone_list = var.subnet_zone_list

  # Security Group Configuration
  # Use existing security group from VPC
  security_group_ids = var.security_group_ids

  # Optional: Reserve specific IPs for VPE
  reserved_ips = var.reserve_ips ? {
    (var.subnet_zone_list[0].id) = {
      name = "${var.prefix}-vpe-ip-1"
    }
  } : {}
}