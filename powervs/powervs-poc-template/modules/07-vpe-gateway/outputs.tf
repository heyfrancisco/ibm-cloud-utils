##############################################################################
# VPE Gateway Module Outputs
##############################################################################

output "vpe_gateway_crn" {
  description = "List of VPE gateway CRNs"
  value       = module.vpe_gateway.crn
}

output "vpe_ips" {
  description = "Map of VPE IP addresses by gateway name"
  value       = module.vpe_gateway.vpe_ips
}