##############################################################################
# PowerVS Instance Module Outputs
##############################################################################

output "pi_instance_id" {
  description = "PowerVS instance ID"
  value       = module.powervs_instance.pi_instance_id
}

output "pi_instance_name" {
  description = "PowerVS instance name"
  value       = module.powervs_instance.pi_instance_name
}

output "pi_instance_private_ips" {
  description = "List of private IP addresses"
  value       = module.powervs_instance.pi_instance_private_ips
}

output "pi_instance_primary_ip" {
  description = "Primary network interface IP"
  value       = length(module.powervs_instance.pi_instance_private_ips) > 0 ? module.powervs_instance.pi_instance_private_ips[0] : null
}

output "pi_storage_configuration" {
  description = "Storage volume details"
  value       = module.powervs_instance.pi_storage_configuration
}

output "pi_instance_details" {
  description = "Full instance details"
  value       = module.powervs_instance.pi_instance
}