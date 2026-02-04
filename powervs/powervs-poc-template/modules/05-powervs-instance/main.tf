##############################################################################
# PowerVS Instance Module
# 
# This module creates IBM Cloud PowerVS Instance (LPAR) using the official
# terraform-ibm-modules/powervs-instance/ibm module.
#
# Resources created:
# - PowerVS LPAR instance
# - Network interface attached to private subnet
# - Storage volumes (boot and data)
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
# PowerVS Instance Module
##############################################################################

module "powervs_instance" {
  source  = "terraform-ibm-modules/powervs-instance/ibm"
  version = "2.8.2"

  # Workspace Configuration
  pi_workspace_guid = var.pi_workspace_guid

  # Instance Configuration
  pi_instance_name        = "${var.prefix}-${var.powervs_instance_name}"
  pi_image_id             = var.powervs_instance_image
  pi_ssh_public_key_name  = var.pi_ssh_key_name

  # Network Configuration
  # Attach instance to private subnet
  pi_networks = [
    {
      name = var.pi_subnet_name
      id   = var.pi_subnet_id
      ip   = null  # Auto-assign IP from subnet
    }
  ]

  # Compute Configuration
  # For non-SAP workloads
  pi_cpu_proc_type        = var.powervs_instance_proc_type
  pi_number_of_processors = var.powervs_instance_processors
  pi_memory_size          = var.powervs_instance_memory

  # Storage Configuration
  pi_boot_image_storage_tier = var.powervs_storage_tier

  # Data volumes
  pi_storage_config = var.powervs_storage_size > 0 ? [
    {
      name     = "${var.prefix}-data-vol"
      size     = var.powervs_storage_size
      count    = 1
      tier     = var.powervs_storage_tier
      mount    = "/data"
      pool     = null
      sharable = false
    }
  ] : []

  # Optional Settings
  pi_server_type        = null  # Auto-select based on availability
  pi_user_tags          = var.tags
  pi_pin_policy         = "none"
  pi_placement_group_id = null
  pi_user_data          = var.pi_user_data
}