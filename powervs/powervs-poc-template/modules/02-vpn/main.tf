##############################################################################
# Site-to-Site VPN Module
# 
# This module creates IBM Cloud Site-to-Site VPN connections using the
# official terraform-ibm-modules/site-to-site-vpn/ibm module.
#
# Resources created:
# - VPN connections with IKE and IPSec policies
# - Dead Peer Detection (DPD) configuration
# - Route-based VPN mode
# - Optional VPC routes for VPN traffic
##############################################################################

terraform {
  required_version = ">= 1.3.0"
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = ">= 1.49.0"
    }
  }
}

##############################################################################
# Site-to-Site VPN Module
##############################################################################

module "site_to_site_vpn" {
  source  = "terraform-ibm-modules/site-to-site-vpn/ibm"
  version = "3.0.4"

  # Use existing VPN gateway from VPC module
  create_vpn_gateway       = false
  existing_vpn_gateway_id  = var.existing_vpn_gateway_id
  resource_group_id        = var.resource_group_id

  # VPN Connections Configuration
  # Create multiple VPN connections based on input variable
  vpn_connections = [
    for idx, conn in var.vpn_connections : {
      vpn_connection_name = conn.name
      preshared_key      = conn.preshared_key
      admin_state_up     = true
      establish_mode     = "bidirectional"

      # IKE Policy Configuration
      # IKEv2 with AES-256 encryption and SHA-256 authentication
      ike_policy = {
        name                     = "${var.prefix}-ike-policy-${idx + 1}"
        authentication_algorithm = "sha256"
        encryption_algorithm     = "aes256"
        dh_group                 = 14
        ike_version              = 2
        key_lifetime             = 28800  # 8 hours
      }

      # IPSec Policy Configuration
      # AES-256 encryption with Perfect Forward Secrecy (PFS)
      ipsec_policy = {
        name                     = "${var.prefix}-ipsec-policy-${idx + 1}"
        authentication_algorithm = "sha256"
        encryption_algorithm     = "aes256"
        pfs                      = "group_14"
        key_lifetime             = 3600  # 1 hour
      }

      # Peer Gateway Configuration
      peer = {
        peer_address = conn.peer_address
        cidrs        = conn.peer_cidrs
        ike_identity = {
          type  = "ipv4_address"
          value = conn.peer_address
        }
      }

      # Local Gateway Configuration
      local = {
        cidrs = conn.local_cidrs
        ike_identities = [{
          type = "ipv4_address"
        }]
      }

      # Dead Peer Detection (DPD)
      # Monitors VPN connection health and restarts if needed
      action   = "restart"
      interval = 30   # Check every 30 seconds
      timeout  = 120  # Timeout after 120 seconds
    }
  ]

  # Optional: Create VPC routes for VPN traffic
  create_routes = var.create_vpn_routes
  vpc_id        = var.create_vpn_routes ? var.vpc_id : null
  
  routes = var.create_vpn_routes ? flatten([
    for idx, conn in var.vpn_connections : [
      for cidr in conn.peer_cidrs : {
        route_name          = "${var.prefix}-vpn-route-${idx + 1}-${replace(cidr, "/", "-")}"
        zone                = var.vpc_zone
        destination         = cidr
        next_hop            = "0.0.0.0"  # VPN gateway
        vpn_connection_name = conn.name
      }
    ]
  ]) : []

  # Tags for resource organization
  tags = var.tags
}