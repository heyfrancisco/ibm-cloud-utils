##############################################################################
# VPC Module Outputs
##############################################################################

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.landing_zone_vpc.vpc_id
}

output "vpc_crn" {
  description = "CRN of the VPC"
  value       = module.landing_zone_vpc.vpc_crn
}

output "vpc_name" {
  description = "Name of the VPC"
  value       = module.landing_zone_vpc.vpc_name
}

output "subnet_ids" {
  description = "Map of subnet names to IDs"
  value       = module.landing_zone_vpc.subnet_ids
}

output "subnet_zone_list" {
  description = "List of subnet details including zone information"
  value       = module.landing_zone_vpc.subnet_zone_list
}

output "security_group_details" {
  description = "Details of security group"
  value       = module.landing_zone_vpc.security_group_details
}

output "network_acls" {
  description = "List of shortnames and IDs of network ACLs"
  value       = module.landing_zone_vpc.network_acls
}

output "public_gateways" {
  description = "Map of public gateways by zone"
  value       = module.landing_zone_vpc.public_gateways
}

output "vpn_gateways_data" {
  description = "List of VPN gateway details"
  value       = module.landing_zone_vpc.vpn_gateways_data
}

output "vpn_gateway_public_ips" {
  description = "Public IPs of VPN gateways"
  value       = try([for gw in module.landing_zone_vpc.vpn_gateways_data : gw.public_ip_address], [])
}