##############################################################################
# VPN Module Outputs
##############################################################################

output "vpn_gateway_id" {
  description = "ID of the VPN gateway"
  value       = var.existing_vpn_gateway_id
}

output "vpn_connection_ids" {
  description = "Map of VPN connection names to IDs"
  value       = { for conn in module.site_to_site_vpn.vpn_connection : conn.name => conn.id }
}

output "vpn_connection_details" {
  description = "Full details of VPN connections"
  value       = module.site_to_site_vpn.vpn_connection
}

output "vpn_connection_statuses" {
  description = "Status of each VPN connection"
  value       = { for conn in module.site_to_site_vpn.vpn_connection : conn.name => conn.status }
}

output "ike_policy_ids" {
  description = "IDs of IKE policies created"
  value       = [for conn in module.site_to_site_vpn.vpn_connection : conn.ike_policy]
}

output "ipsec_policy_ids" {
  description = "IDs of IPSec policies created"
  value       = [for conn in module.site_to_site_vpn.vpn_connection : conn.ipsec_policy]
}

output "vpn_routes" {
  description = "VPN routes created"
  value       = var.create_vpn_routes ? module.site_to_site_vpn.routes : []
}