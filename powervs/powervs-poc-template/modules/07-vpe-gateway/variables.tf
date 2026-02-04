##############################################################################
# VPE Gateway Module Variables
##############################################################################

variable "resource_group_id" {
  description = "ID of the resource group"
  type        = string
}

variable "prefix" {
  description = "Prefix for naming resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where VPE gateway will be created"
  type        = string
}

variable "vpc_name" {
  description = "VPC name"
  type        = string
}

variable "vpe_gateway_name" {
  description = "Name for VPE gateway (will be prefixed)"
  type        = string
  default     = "cos-vpe"
}

variable "cos_instance_crn" {
  description = "CRN of Cloud Object Storage instance"
  type        = string
}

variable "subnet_zone_list" {
  description = "List of subnet details for VPE gateway attachment"
  type = list(object({
    name = string
    id   = string
    cidr = string
    zone = string
  }))
}

variable "security_group_ids" {
  description = "List of security group IDs to attach to VPE gateway"
  type        = list(string)
}

variable "reserve_ips" {
  description = "Reserve specific IPs for VPE gateway"
  type        = bool
  default     = false
}

variable "tags" {
  description = "List of tags to apply to resources"
  type        = list(string)
  default     = []
}