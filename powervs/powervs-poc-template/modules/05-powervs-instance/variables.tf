##############################################################################
# PowerVS Instance Module Variables
##############################################################################

variable "prefix" {
  description = "Prefix for naming resources"
  type        = string
}

variable "pi_workspace_guid" {
  description = "PowerVS workspace GUID"
  type        = string
}

variable "pi_zone" {
  description = "PowerVS zone"
  type        = string
}

variable "pi_ssh_key_name" {
  description = "Name of SSH key in PowerVS workspace"
  type        = string
}

variable "pi_subnet_name" {
  description = "Name of PowerVS private subnet"
  type        = string
}

variable "pi_subnet_id" {
  description = "ID of PowerVS private subnet"
  type        = string
}

variable "powervs_instance_name" {
  description = "Name for PowerVS LPAR instance (will be prefixed)"
  type        = string
  default     = "lpar"
}

variable "powervs_instance_image" {
  description = "Image ID for PowerVS instance"
  type        = string

  # Common images (run 'ibmcloud pi images' to list available):
  # - RHEL8-SP4
  # - SLES15-SP3
  # - AIX-7200-05-05
  # - IBMi-75-01-2924-1
}

variable "powervs_instance_processors" {
  description = "Number of processors (vCPUs)"
  type        = string
  default     = "0.5"

  validation {
    condition     = can(tonumber(var.powervs_instance_processors)) && tonumber(var.powervs_instance_processors) >= 0.25
    error_message = "Processors must be at least 0.25."
  }
}

variable "powervs_instance_memory" {
  description = "Memory in GB"
  type        = string
  default     = "4"

  validation {
    condition     = can(tonumber(var.powervs_instance_memory)) && tonumber(var.powervs_instance_memory) >= 2
    error_message = "Memory must be at least 2 GB."
  }
}

variable "powervs_instance_proc_type" {
  description = "Processor type: shared, capped, or dedicated"
  type        = string
  default     = "shared"

  validation {
    condition     = contains(["shared", "capped", "dedicated"], var.powervs_instance_proc_type)
    error_message = "Processor type must be 'shared', 'capped', or 'dedicated'."
  }
}

variable "powervs_storage_tier" {
  description = "Storage tier: tier1 (high-performance) or tier3 (standard)"
  type        = string
  default     = "tier3"

  validation {
    condition     = contains(["tier1", "tier3"], var.powervs_storage_tier)
    error_message = "Storage tier must be 'tier1' or 'tier3'."
  }
}

variable "powervs_storage_size" {
  description = "Storage size in GB for data volume (0 to skip)"
  type        = number
  default     = 100

  validation {
    condition     = var.powervs_storage_size >= 0
    error_message = "Storage size must be 0 or greater."
  }
}

variable "pi_user_data" {
  description = "Cloud-init user data for instance initialization"
  type        = string
  default     = null
}

variable "tags" {
  description = "List of tags to apply to resources"
  type        = list(string)
  default     = []
}