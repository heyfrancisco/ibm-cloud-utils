##############################################################################
# VPN Module Outputs
##############################################################################

output "vpn_gateway_id" {
  description = "ID of the VPN gateway"
  value       = var.existing_vpn_gateway_id
}

output "vpn_connection_ids" {
  description = "Map of VPN connection names to IDs"
  value       = module.site_to_site_vpn.vpn_gateway_connection_ids
}

output "vpn_connection_details" {
  description = "Full details of VPN connections"
  value       = module.site_to_site_vpn.vpn_connection_policies
}

output "vpn_connection_statuses" {
  description = "Status of each VPN connection"
  value       = module.site_to_site_vpn.vpn_gateway_connection_statuses
}

output "vpn_connection_modes" {
  description = "VPN connection modes (policy or route)"
  value       = module.site_to_site_vpn.vpn_gateway_connection_modes
}

output "vpn_status_reasons" {
  description = "Status reasons for VPN connections"
  value       = module.site_to_site_vpn.vpn_status_reasons
}

output "vpn_routes" {
  description = "VPN routes created"
  value       = module.site_to_site_vpn.vpn_routes
}