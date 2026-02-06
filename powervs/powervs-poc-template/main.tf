##############################################################################
# IBM Cloud Landing Zone - Root Configuration
#
# This configuration uses IBM Cloud Terraform modules directly from the
# registry without local module wrappers.
#
# Deployment Order:
# 1. VPC Infrastructure (networking foundation)
# 2. Cloud Object Storage (storage layer)
# 3. Transit Gateway (network connectivity)
# 4. PowerVS Workspace (compute foundation - ready for LPAR deployment)
# 5. VPN (optional - site-to-site connectivity)
##############################################################################

##############################################################################
# Module 01: VPC Infrastructure
# Creates VPC, subnets, security groups, and VPN gateway
##############################################################################

module "vpc" {
  source  = "terraform-ibm-modules/landing-zone-vpc/ibm"
  version = "8.7.0"

  # Core VPC Configuration
  resource_group_id = data.ibm_resource_group.resource_group.id
  region            = var.region
  prefix            = var.prefix
  name              = "${var.prefix}-${var.vpc_name}"
  tags              = var.tags

  # Network Configuration
  network_cidrs = [var.vpc_cidr]

  use_public_gateways = {
    zone-1 = true
    zone-2 = false
    zone-3 = false
  }

  subnets = {
    zone-1 = [
      {
        name           = "subnet-a"
        cidr           = var.subnet_cidr
        public_gateway = var.enable_public_gateway
        acl_name       = "vpc-acl"
      }
    ]
  }

  # Network ACL Configuration
  network_acls = [
    {
      name                         = "vpc-acl"
      add_ibm_cloud_internal_rules = true
      add_vpc_connectivity_rules   = true
      prepend_ibm_rules            = true

      rules = [
        {
          name        = "allow-all-inbound"
          action      = "allow"
          direction   = "inbound"
          destination = "0.0.0.0/0"
          source      = "0.0.0.0/0"
        },
        {
          name        = "allow-all-outbound"
          action      = "allow"
          direction   = "outbound"
          destination = "0.0.0.0/0"
          source      = "0.0.0.0/0"
        }
      ]
    }
  ]

  # Security Group Configuration
  clean_default_sg_acl = var.clean_default_sg_acl

  # VPN Gateway Configuration
  vpn_gateways = var.enable_vpn_gateway ? [
    {
      name        = "${var.prefix}-vpn-gateway"
      subnet_name = "subnet-a"
      mode        = "route"
      connections = []
    }
  ] : []

  # VPC Flow Logs (optional)
  enable_vpc_flow_logs                   = var.enable_vpc_flow_logs
  create_authorization_policy_vpc_to_cos = var.enable_vpc_flow_logs
  existing_cos_instance_guid             = var.enable_vpc_flow_logs ? module.cos.cos_instance_guid : null
  existing_storage_bucket_name           = var.enable_vpc_flow_logs ? module.cos.bucket_name : null
}

##############################################################################
# Module 02: Site-to-Site VPN (Optional)
# Creates VPN connections for site-to-site connectivity
##############################################################################

module "vpn" {
  count   = var.enable_vpn_gateway && length(var.vpn_connections) > 0 ? 1 : 0
  source  = "terraform-ibm-modules/site-to-site-vpn/ibm"
  version = "3.0.4"

  # Use existing VPN gateway from VPC module
  create_vpn_gateway      = false
  existing_vpn_gateway_id = module.vpc.vpn_gateways_data[0].id
  resource_group_id       = data.ibm_resource_group.resource_group.id

  # VPN Connections Configuration
  vpn_connections = [
    for idx, conn in var.vpn_connections : {
      vpn_connection_name = conn.name
      preshared_key       = conn.preshared_key
      admin_state_up      = true
      establish_mode      = "bidirectional"

      # IKE Policy Configuration
      ike_policy = {
        name                     = "${var.prefix}-ike-policy-${idx + 1}"
        authentication_algorithm = "sha256"
        encryption_algorithm     = "aes256"
        dh_group                 = 14
        ike_version              = 2
        key_lifetime             = 28800
      }

      # IPSec Policy Configuration
      ipsec_policy = {
        name                     = "${var.prefix}-ipsec-policy-${idx + 1}"
        authentication_algorithm = "sha256"
        encryption_algorithm     = "aes256"
        pfs                      = "group_14"
        key_lifetime             = 3600
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

      # Dead Peer Detection
      action   = "restart"
      interval = 30
      timeout  = 120
    }
  ]

  # Optional: Create VPC routes for VPN traffic
  create_routes = var.create_vpn_routes
  vpc_id        = var.create_vpn_routes ? module.vpc.vpc_id : null

  routes = var.create_vpn_routes ? flatten([
    for idx, conn in var.vpn_connections : [
      for cidr in conn.peer_cidrs : {
        route_name          = "${var.prefix}-vpn-route-${idx + 1}-${replace(cidr, "/", "-")}"
        zone                = var.vpc_zone
        destination         = cidr
        next_hop            = "0.0.0.0"
        vpn_connection_name = conn.name
      }
    ]
  ]) : []

  tags = var.tags

  depends_on = [module.vpc]
}

##############################################################################
# Module 03: Cloud Object Storage
# Creates COS instance and bucket with encryption
##############################################################################

module "cos" {
  source  = "terraform-ibm-modules/cos/ibm"
  version = "10.5.0"

  # COS Instance Configuration
  create_cos_instance = true
  cos_instance_name   = "${var.prefix}-${var.cos_instance_name}"
  resource_group_id   = data.ibm_resource_group.resource_group.id
  cos_plan            = var.cos_plan
  cos_location        = "global"
  cos_tags            = var.tags

  # Bucket Configuration
  create_cos_bucket      = true
  bucket_name            = "${var.prefix}-${var.cos_bucket_name}"
  region                 = var.region
  bucket_storage_class   = var.cos_storage_class
  add_bucket_name_suffix = true
  force_delete           = var.cos_force_delete

  # Encryption Configuration
  kms_encryption_enabled        = var.kms_key_crn != null
  kms_key_crn                   = var.kms_key_crn
  skip_iam_authorization_policy = var.kms_key_crn == null
  existing_kms_instance_guid    = var.kms_key_crn != null ? split(":", var.kms_key_crn)[7] : null

  # Monitoring and Activity Tracking
  usage_metrics_enabled              = true
  request_metrics_enabled            = true
  activity_tracker_management_events = true
  activity_tracker_read_data_events  = var.cos_enable_activity_tracker_read_events
  activity_tracker_write_data_events = var.cos_enable_activity_tracker_write_events

  # Lifecycle Policies
  archive_days = var.cos_archive_days > 0 ? var.cos_archive_days : null
  archive_type = var.cos_archive_days > 0 ? "Glacier" : null
  expire_days  = var.cos_expire_days > 0 ? var.cos_expire_days : null

  # Optional Features
  object_versioning_enabled = var.cos_enable_object_versioning
  retention_enabled         = var.cos_enable_retention

  # Management Policy
  management_endpoint_type_for_bucket = "public"
}

##############################################################################
# Module 04: Transit Gateway
# Creates Transit Gateway and connects VPC
##############################################################################

module "transit_gateway" {
  count   = var.enable_transit_gateway ? 1 : 0
  source  = "terraform-ibm-modules/transit-gateway/ibm"
  version = "2.5.2"

  # Transit Gateway Configuration
  transit_gateway_name = "${var.prefix}-${var.transit_gateway_name}"
  region               = var.region
  resource_group_id    = data.ibm_resource_group.resource_group.id
  global_routing       = var.enable_global_routing

  # VPC Connection
  vpc_connections = [
    {
      vpc_id               = module.vpc.vpc_id
      vpc_crn              = module.vpc.vpc_crn
      connection_name      = "${var.prefix}-vpc-connection"
      network_type         = "vpc"
      base_connection_type = "vpc"
    }
  ]

  # Classic Infrastructure Connections (not needed)
  classic_connections_count = 0

  # Resource Tags
  resource_tags = var.tags

  depends_on = [module.vpc]
}

##############################################################################
# Module 05: PowerVS Workspace
# Creates PowerVS workspace with private subnet and SSH key
##############################################################################

module "powervs_workspace" {
  count   = var.enable_powervs ? 1 : 0
  source  = "terraform-ibm-modules/powervs-workspace/ibm"
  version = "4.1.2"

  # Provider Configuration - Use PowerVS-specific provider with zone
  providers = {
    ibm = ibm.powervs
  }

  # Workspace Configuration
  pi_workspace_name    = "${var.prefix}-powervs-workspace"
  pi_zone              = var.powervs_zone
  pi_resource_group_id = data.ibm_resource_group.resource_group.id
  pi_tags              = var.tags

  # SSH Key Configuration
  pi_ssh_public_key = {
    name  = "${var.prefix}-${var.powervs_ssh_key_name}"
    value = var.powervs_ssh_public_key
  }

  # Private Subnet Configuration
  pi_private_subnet_1 = {
    name        = "${var.prefix}-powervs-subnet"
    cidr        = var.powervs_subnet_cidr
    dns_servers = var.powervs_dns_servers
  }

  # No additional subnets needed
  pi_private_subnet_2 = null
  pi_private_subnet_3 = null

  # Transit Gateway Connection
  pi_transit_gateway_connection = var.enable_transit_gateway ? {
    enable             = true
    transit_gateway_id = module.transit_gateway[0].tg_id
    } : {
    enable             = false
    transit_gateway_id = null
  }

  depends_on = [module.transit_gateway]
}

##############################################################################
# PowerVS Instance Module Removed
# This landing zone provides the infrastructure foundation only.
# Users can deploy their own LPAR instances using the workspace created above.
##############################################################################