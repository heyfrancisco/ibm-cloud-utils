##############################################################################
# PowerVS Workspace Module Variables
##############################################################################

variable "resource_group_id" {
  description = "ID of the resource group"
  type        = string
}

variable "prefix" {
  description = "Prefix for naming resources"
  type        = string
}

variable "powervs_zone" {
  description = "PowerVS zone (e.g., dal10, lon04, fra04)"
  type        = string

  validation {
    condition     = can(regex("^[a-z]{3}[0-9]{2}$", var.powervs_zone))
    error_message = "PowerVS zone must be in format like 'dal10', 'lon04', etc."
  }
}

variable "powervs_subnet_cidr" {
  description = "CIDR for PowerVS private subnet"
  type        = string
  default     = "192.168.100.0/24"

  validation {
    condition     = can(cidrhost(var.powervs_subnet_cidr, 0))
    error_message = "Must be a valid CIDR block."
  }
}

variable "powervs_dns_servers" {
  description = "DNS servers for PowerVS subnet"
  type        = list(string)
  default     = ["9.9.9.9", "1.1.1.1"]
}

variable "powervs_ssh_key_name" {
  description = "Name for PowerVS SSH key"
  type        = string
  default     = "ssh-key"
}

variable "powervs_ssh_public_key" {
  description = "Public SSH key content for PowerVS instances"
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^ssh-(rsa|ed25519|ecdsa)", var.powervs_ssh_public_key))
    error_message = "Must be a valid SSH public key starting with ssh-rsa, ssh-ed25519, or ssh-ecdsa."
  }
}

variable "enable_transit_gateway" {
  description = "Enable Transit Gateway connection"
  type        = bool
  default     = false
}

variable "transit_gateway_id" {
  description = "Transit Gateway ID (required if enable_transit_gateway is true)"
  type        = string
  default     = null
}

variable "custom_image_1" {
  description = "Custom image to import from COS"
  type = object({
    name       = string
    source_url = string
  })
  default = null
}

variable "tags" {
  description = "List of tags to apply to resources"
  type        = list(string)
  default     = []
}