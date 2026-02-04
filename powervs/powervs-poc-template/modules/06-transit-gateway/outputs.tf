##############################################################################
# Transit Gateway Module Outputs
##############################################################################

output "tg_id" {
  description = "Transit Gateway ID"
  value       = module.transit_gateway.tg_id
}

output "tg_crn" {
  description = "Transit Gateway CRN"
  value       = module.transit_gateway.tg_crn
}

output "tg_name" {
  description = "Transit Gateway name"
  value       = "${var.prefix}-${var.transit_gateway_name}"
}

output "vpc_connection_ids" {
  description = "Map of VPC connection IDs"
  value       = module.transit_gateway.vpc_conn_ids
}

output "classic_connection_ids" {
  description = "Map of classic connection IDs"
  value       = module.transit_gateway.classic_conn_ids
}

output "prefix_filter_ids" {
  description = "List of prefix filter IDs"
  value       = module.transit_gateway.filter_ids
}