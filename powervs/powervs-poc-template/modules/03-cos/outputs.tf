##############################################################################
# COS Module Outputs
##############################################################################

output "cos_instance_id" {
  description = "ID of the COS instance"
  value       = module.cos.cos_instance_id
}

output "cos_instance_crn" {
  description = "CRN of the COS instance (for VPE gateway)"
  value       = module.cos.cos_instance_crn
}

output "cos_instance_guid" {
  description = "GUID of the COS instance"
  value       = module.cos.cos_instance_guid
}

output "cos_instance_name" {
  description = "Name of the COS instance"
  value       = module.cos.cos_instance_name
}

output "bucket_id" {
  description = "ID of the COS bucket"
  value       = module.cos.bucket_id
}

output "bucket_name" {
  description = "Name of the COS bucket (with suffix)"
  value       = module.cos.bucket_name
}

output "bucket_crn" {
  description = "CRN of the COS bucket"
  value       = module.cos.bucket_crn
}

output "bucket_region" {
  description = "Region of the COS bucket"
  value       = module.cos.bucket_region
}

output "s3_endpoint_public" {
  description = "Public endpoint for S3 API"
  value       = module.cos.s3_endpoint_public
}

output "s3_endpoint_private" {
  description = "Private endpoint for S3 API"
  value       = module.cos.s3_endpoint_private
}

output "s3_endpoint_direct" {
  description = "Direct endpoint for S3 API"
  value       = module.cos.s3_endpoint_direct
}

output "kms_key_crn" {
  description = "CRN of KMS key used for encryption"
  value       = var.kms_key_crn
}