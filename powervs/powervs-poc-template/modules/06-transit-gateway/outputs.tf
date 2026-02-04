##############################################################################
# Transit Gateway Module Outputs
##############################################################################

output "tg_id" {
  description = "Transit Gateway ID"
  value       = module.transit_gateway.transit_gateway_id
}

output "tg_crn" {
  description = "Transit Gateway CRN"
  value       = module.transit_gateway.transit_gateway_crn
}

output "tg_name" {
  description = "Transit Gateway name"
  value       = module.transit_gateway.transit_gateway_name
}

output "vpc_connection_ids" {
  description = "List of VPC connection IDs"
  value       = module.transit_gateway.vpc_connection_ids
}

output "transit_gateway_details" {
  description = "Full Transit Gateway details"
  value       = module.transit_gateway.transit_gateway
}