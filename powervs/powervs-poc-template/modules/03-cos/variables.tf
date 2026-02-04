##############################################################################
# COS Module Variables
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
  description = "IBM Cloud region for bucket"
  type        = string
}

variable "cos_instance_name" {
  description = "Name for COS instance (will be prefixed)"
  type        = string
  default     = "cos"
}

variable "cos_bucket_name" {
  description = "Name for COS bucket (4-char suffix will be added)"
  type        = string
  default     = "cos-bucket"
}

variable "cos_plan" {
  description = "COS service plan"
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "cos-one-rate-plan"], var.cos_plan)
    error_message = "Plan must be 'standard' or 'cos-one-rate-plan'."
  }
}

variable "cos_storage_class" {
  description = "Storage class for bucket"
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "vault", "cold", "smart", "onerate_active"], var.cos_storage_class)
    error_message = "Invalid storage class. Must be one of: standard, vault, cold, smart, onerate_active."
  }
}

variable "kms_key_crn" {
  description = "CRN of KMS key for encryption (optional)"
  type        = string
  default     = null
}

variable "force_delete" {
  description = "Allow bucket deletion even with objects (useful for dev/test)"
  type        = bool
  default     = true
}

variable "enable_activity_tracker_read_events" {
  description = "Enable Activity Tracker for read data events"
  type        = bool
  default     = true
}

variable "enable_activity_tracker_write_events" {
  description = "Enable Activity Tracker for write data events"
  type        = bool
  default     = true
}

variable "archive_days" {
  description = "Number of days before archiving objects to Glacier (0 to disable)"
  type        = number
  default     = 90

  validation {
    condition     = var.archive_days >= 0
    error_message = "Archive days must be 0 or greater."
  }
}

variable "expire_days" {
  description = "Number of days before expiring (deleting) objects (0 to disable)"
  type        = number
  default     = 365

  validation {
    condition     = var.expire_days >= 0
    error_message = "Expire days must be 0 or greater."
  }
}

variable "abort_multipart_days" {
  description = "Number of days before aborting incomplete multipart uploads"
  type        = number
  default     = 7

  validation {
    condition     = var.abort_multipart_days >= 1
    error_message = "Abort multipart days must be at least 1."
  }
}

variable "enable_object_versioning" {
  description = "Enable object versioning"
  type        = bool
  default     = false
}

variable "enable_retention" {
  description = "Enable retention policy"
  type        = bool
  default     = false
}

variable "hard_quota_bytes" {
  description = "Hard quota in bytes (null for no quota)"
  type        = number
  default     = null
}

variable "tags" {
  description = "List of tags to apply to resources"
  type        = list(string)
  default     = []
}