##############################################################################
# Cloud Object Storage Module
# 
# This module creates IBM Cloud Object Storage instance and bucket using the
# official terraform-ibm-modules/cos/ibm module.
#
# Resources created:
# - COS instance with standard plan
# - COS bucket with encryption and lifecycle policies
# - Activity tracking and monitoring
# - Optional KMS encryption
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
# Cloud Object Storage Module
##############################################################################

module "cos" {
  source  = "terraform-ibm-modules/cos/ibm"
  version = "10.5.0"

  # COS Instance Configuration
  create_cos_instance = true
  cos_instance_name   = "${var.prefix}-${var.cos_instance_name}"
  resource_group_id   = var.resource_group_id
  cos_plan            = var.cos_plan
  cos_location        = "global"
  cos_tags            = var.tags

  # Bucket Configuration
  create_cos_bucket     = true
  bucket_name           = "${var.prefix}-${var.cos_bucket_name}"
  region                = var.region
  bucket_storage_class  = var.cos_storage_class
  add_bucket_name_suffix = true  # Adds random 4-char suffix for uniqueness
  force_delete          = var.force_delete  # Allow deletion with objects (dev/test)

  # Encryption Configuration
  # Enable KMS encryption if key CRN is provided
  kms_encryption_enabled = var.kms_key_crn != null
  kms_key_crn           = var.kms_key_crn
  skip_iam_authorization_policy = var.kms_key_crn == null
  existing_kms_instance_guid    = var.kms_key_crn != null ? split(":", var.kms_key_crn)[7] : null

  # Monitoring and Activity Tracking
  # Enable metrics for usage and request monitoring
  usage_metrics_enabled   = true
  request_metrics_enabled = true
  
  # Activity Tracker for audit logging
  activity_tracker_management_events = true
  activity_tracker_read_data_events  = var.enable_activity_tracker_read_events
  activity_tracker_write_data_events = var.enable_activity_tracker_write_events

  # Lifecycle Policies
  # Archive data to Glacier after specified days
  archive_days = var.archive_days
  archive_type = var.archive_days > 0 ? "Glacier" : null
  
  # Expire (delete) data after specified days
  expire_days = var.expire_days

  # Optional Features
  object_versioning_enabled = var.enable_object_versioning
  retention_enabled         = var.enable_retention
  hard_quota                = var.hard_quota_bytes

  # Management Policy
  management_endpoint_type_for_bucket = "public"
}