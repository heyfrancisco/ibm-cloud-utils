##############################################################################
# VPC Module Variables
##############################################################################

variable "resource_group_id" {
  description = "ID of the resource group where VPC resources will be created"
  type        = string
}

variable "region" {
  description = "IBM Cloud region where VPC will be created"
  type        = string
}

variable "prefix" {
  description = "Prefix for naming resources"
  type        = string

  validation {
    condition     = can(regex("^[a-z][-a-z0-9]*$", var.prefix))
    error_message = "Prefix must start with a lowercase letter and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "vpc_name" {
  description = "Name for the VPC (will be prefixed)"
  type        = string
  default     = "vpc"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC address prefix"
  type        = string
  default     = "10.10.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "Must be a valid CIDR block."
  }
}

variable "subnet_cidr" {
  description = "CIDR block for the subnet"
  type        = string
  default     = "10.10.10.0/24"

  validation {
    condition     = can(cidrhost(var.subnet_cidr, 0))
    error_message = "Must be a valid CIDR block."
  }
}

variable "vpc_zone" {
  description = "Availability zone for VPC resources (e.g., us-south-1)"
  type        = string
}

variable "enable_public_gateway" {
  description = "Enable public gateway for internet access"
  type        = bool
  default     = true
}

variable "enable_vpn_gateway" {
  description = "Enable VPN gateway for site-to-site connectivity"
  type        = bool
  default     = false
}

variable "clean_default_sg_acl" {
  description = "Remove default security group and ACL rules for better security"
  type        = bool
  default     = true
}

variable "enable_vpc_flow_logs" {
  description = "Enable VPC flow logs for audit and troubleshooting"
  type        = bool
  default     = false
}

variable "cos_instance_guid" {
  description = "GUID of COS instance for flow logs (required if enable_vpc_flow_logs is true)"
  type        = string
  default     = null
}

variable "flow_logs_bucket_name" {
  description = "Name of COS bucket for flow logs (required if enable_vpc_flow_logs is true)"
  type        = string
  default     = null
}

variable "tags" {
  description = "List of tags to apply to resources"
  type        = list(string)
  default     = []
}