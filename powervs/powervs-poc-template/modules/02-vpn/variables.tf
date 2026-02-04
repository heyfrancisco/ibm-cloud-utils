##############################################################################
# VPN Module Variables
##############################################################################

variable "resource_group_id" {
  description = "ID of the resource group"
  type        = string
}

variable "prefix" {
  description = "Prefix for naming resources"
  type        = string
}

variable "existing_vpn_gateway_id" {
  description = "ID of existing VPN gateway from VPC module"
  type        = string
}

variable "vpn_connections" {
  description = "List of VPN connections to create"
  type = list(object({
    name          = string
    peer_address  = string
    preshared_key = string
    local_cidrs   = list(string)
    peer_cidrs    = list(string)
  }))
  default = []

  validation {
    condition     = alltrue([for conn in var.vpn_connections : length(conn.preshared_key) >= 32])
    error_message = "Pre-shared keys must be at least 32 characters long for security."
  }

  validation {
    condition     = alltrue([for conn in var.vpn_connections : can(regex("^[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}$", conn.peer_address))])
    error_message = "Peer address must be a valid IPv4 address."
  }
}

variable "create_vpn_routes" {
  description = "Create VPC routes for VPN traffic"
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "VPC ID for creating routes (required if create_vpn_routes is true)"
  type        = string
  default     = null
}

variable "vpc_zone" {
  description = "VPC zone for route creation"
  type        = string
  default     = null
}

variable "tags" {
  description = "List of tags to apply to resources"
  type        = list(string)
  default     = []
}