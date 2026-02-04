##############################################################################
# Transit Gateway Module Variables
##############################################################################

variable "resource_group_id" {
  description = "ID of the resource group"
  type        = string
}

variable "prefix" {
  description = "Prefix for naming resources"
  type        = string
}

variable "region" {
  description = "IBM Cloud region"
  type        = string
}

variable "transit_gateway_name" {
  description = "Name for Transit Gateway (will be prefixed)"
  type        = string
  default     = "tgw"
}

variable "enable_global_routing" {
  description = "Enable global routing (connects resources across regions)"
  type        = bool
  default     = false

  # Note: Global routing incurs additional charges
}

variable "vpc_id" {
  description = "VPC ID to connect to Transit Gateway"
  type        = string
}

variable "vpc_crn" {
  description = "VPC CRN for Transit Gateway connection"
  type        = string
}

variable "vpc_subnet_cidr" {
  description = "VPC subnet CIDR for prefix filtering"
  type        = string
  default     = null
}

variable "enable_prefix_filters" {
  description = "Enable prefix filtering for route control"
  type        = bool
  default     = false
}

variable "tags" {
  description = "List of tags to apply to resources"
  type        = list(string)
  default     = []
}