##############################################################################
# PowerVS Workspace Module Outputs
##############################################################################

output "pi_workspace_id" {
  description = "PowerVS workspace ID"
  value       = module.powervs_workspace.pi_workspace_id
}

output "pi_workspace_guid" {
  description = "PowerVS workspace GUID (for instance creation)"
  value       = module.powervs_workspace.pi_workspace_guid
}

output "pi_workspace_name" {
  description = "PowerVS workspace name"
  value       = module.powervs_workspace.pi_workspace_name
}

output "pi_zone" {
  description = "PowerVS zone"
  value       = var.powervs_zone
}

output "pi_ssh_public_key" {
  description = "SSH key details"
  value       = module.powervs_workspace.pi_ssh_public_key
}

output "pi_private_subnet_1" {
  description = "Private subnet details (id, name, cidr)"
  value       = module.powervs_workspace.pi_private_subnet_1
}

output "pi_resource_group_name" {
  description = "Resource group name"
  value       = module.powervs_workspace.pi_resource_group_name
}

output "pi_transit_gateway_connection" {
  description = "Transit Gateway connection configuration (input parameter)"
  value       = var.enable_transit_gateway ? {
    enabled            = true
    transit_gateway_id = var.transit_gateway_id
  } : null
}