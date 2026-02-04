##############################################################################
# VPE Gateway Module Outputs
##############################################################################

output "vpe_gateway_id" {
  description = "VPE gateway ID"
  value       = module.vpe_gateway.vpe_id
}

output "vpe_gateway_crn" {
  description = "VPE gateway CRN"
  value       = module.vpe_gateway.vpe_crn
}

output "vpe_gateway_name" {
  description = "VPE gateway name"
  value       = module.vpe_gateway.vpe_name
}

output "vpe_ips" {
  description = "List of VPE IP addresses"
  value       = module.vpe_gateway.vpe_ips
}

output "endpoint_gateway_targets" {
  description = "VPE endpoint gateway targets"
  value       = module.vpe_gateway.endpoint_gateway_targets
}

output "vpe_gateway_details" {
  description = "Full VPE gateway details"
  value       = module.vpe_gateway.vpe_gateway
}