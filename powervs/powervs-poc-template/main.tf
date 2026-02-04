##############################################################################
# IBM Cloud Landing Zone - Root Configuration
#
# This is the main orchestration file that calls all infrastructure modules
# in the correct order with proper dependencies.
#
# Deployment Order:
# 1. VPC Infrastructure (networking foundation)
# 2. Cloud Object Storage (storage layer)
# 3. Transit Gateway (network connectivity)
# 4. VPE Gateway (private endpoints)
# 5. PowerVS Workspace (compute foundation)
# 6. PowerVS Instance (workload)
# 7. VPN (optional - site-to-site connectivity)
##############################################################################

##############################################################################
# Module 01: VPC Infrastructure
# Creates VPC, subnets, security groups, and VPN gateway
##############################################################################

module "vpc" {
  source = "./modules/01-vpc"

  # Core Configuration
  resource_group_id = var.resource_group_id
  region            = var.region
  prefix            = var.prefix
  tags              = var.tags

  # VPC Configuration
  vpc_name       = var.vpc_name
  vpc_cidr       = var.vpc_cidr
  subnet_cidr    = var.subnet_cidr
  vpc_zone       = var.vpc_zone

  # Gateway Configuration
  enable_public_gateway = var.enable_public_gateway
  enable_vpn_gateway    = var.enable_vpn_gateway

  # Security Configuration
  clean_default_sg_acl = var.clean_default_sg_acl

  # Flow Logs (optional)
  enable_vpc_flow_logs  = var.enable_vpc_flow_logs
  cos_instance_guid     = var.enable_vpc_flow_logs ? module.cos.cos_instance_guid : null
  flow_logs_bucket_name = var.enable_vpc_flow_logs ? module.cos.bucket_name : null
}

##############################################################################
# Module 02: Site-to-Site VPN (Optional)
# Creates VPN connections for site-to-site connectivity
##############################################################################

module "vpn" {
  count  = var.enable_vpn_gateway && length(var.vpn_connections) > 0 ? 1 : 0
  source = "./modules/02-vpn"

  # Core Configuration
  resource_group_id = var.resource_group_id
  prefix            = var.prefix
  tags              = var.tags

  # VPN Configuration
  existing_vpn_gateway_id = module.vpc.vpn_gateways_data[0].id
  vpn_connections         = var.vpn_connections

  # Route Configuration
  create_vpn_routes = var.create_vpn_routes
  vpc_id            = var.create_vpn_routes ? module.vpc.vpc_id : null
  vpc_zone          = var.create_vpn_routes ? var.vpc_zone : null

  depends_on = [module.vpc]
}

##############################################################################
# Module 03: Cloud Object Storage
# Creates COS instance and bucket with encryption
##############################################################################

module "cos" {
  source = "./modules/03-cos"

  # Core Configuration
  resource_group_id = var.resource_group_id
  region            = var.region
  prefix            = var.prefix
  tags              = var.tags

  # COS Configuration
  cos_instance_name = var.cos_instance_name
  cos_bucket_name   = var.cos_bucket_name
  cos_plan          = var.cos_plan
  cos_storage_class = var.cos_storage_class

  # Encryption
  kms_key_crn = var.kms_key_crn

  # Lifecycle Policies
  archive_days        = var.cos_archive_days
  expire_days         = var.cos_expire_days
  abort_multipart_days = var.cos_abort_multipart_days

  # Optional Features
  enable_object_versioning              = var.cos_enable_object_versioning
  enable_retention                      = var.cos_enable_retention
  enable_activity_tracker_read_events   = var.cos_enable_activity_tracker_read_events
  enable_activity_tracker_write_events  = var.cos_enable_activity_tracker_write_events
  force_delete                          = var.cos_force_delete
}

##############################################################################
# Module 04: Transit Gateway
# Creates Transit Gateway and connects VPC
##############################################################################

module "transit_gateway" {
  count  = var.enable_transit_gateway ? 1 : 0
  source = "./modules/06-transit-gateway"

  # Core Configuration
  resource_group_id = var.resource_group_id
  region            = var.region
  prefix            = var.prefix
  tags              = var.tags

  # Transit Gateway Configuration
  transit_gateway_name  = var.transit_gateway_name
  enable_global_routing = var.enable_global_routing

  # VPC Connection
  vpc_id          = module.vpc.vpc_id
  vpc_crn         = module.vpc.vpc_crn
  vpc_subnet_cidr = var.subnet_cidr

  # Prefix Filters
  enable_prefix_filters = var.enable_prefix_filters

  depends_on = [module.vpc]
}

##############################################################################
# Module 05: VPE Gateway
# Creates VPE gateway for private COS access
##############################################################################

module "vpe_gateway" {
  count  = var.enable_vpe_gateway ? 1 : 0
  source = "./modules/07-vpe-gateway"

  # Core Configuration
  resource_group_id = var.resource_group_id
  prefix            = var.prefix
  tags              = var.tags

  # VPC Configuration
  vpc_id   = module.vpc.vpc_id
  vpc_name = module.vpc.vpc_name

  # VPE Configuration
  vpe_gateway_name   = var.vpe_gateway_name
  cos_instance_crn   = module.cos.cos_instance_crn
  subnet_zone_list   = module.vpc.subnet_zone_list
  security_group_ids = [module.vpc.security_group_details[0].id]
  reserve_ips        = var.vpe_reserve_ips

  depends_on = [module.vpc, module.cos]
}

##############################################################################
# Module 06: PowerVS Workspace
# Creates PowerVS workspace with private subnet and SSH key
##############################################################################

module "powervs_workspace" {
  count  = var.enable_powervs ? 1 : 0
  source = "./modules/04-powervs-workspace"

  # Core Configuration
  resource_group_id = var.resource_group_id
  prefix            = var.prefix
  tags              = var.tags

  # PowerVS Configuration
  powervs_zone        = var.powervs_zone
  powervs_subnet_cidr = var.powervs_subnet_cidr
  powervs_dns_servers = var.powervs_dns_servers

  # SSH Key
  powervs_ssh_key_name   = var.powervs_ssh_key_name
  powervs_ssh_public_key = var.powervs_ssh_public_key

  # Transit Gateway Connection
  enable_transit_gateway = var.enable_transit_gateway
  transit_gateway_id     = var.enable_transit_gateway ? module.transit_gateway[0].tg_id : null

  # Custom Image
  custom_image_1 = var.powervs_custom_image_1

  depends_on = [module.transit_gateway]
}

##############################################################################
# Module 07: PowerVS Instance
# Creates PowerVS LPAR instance with storage
##############################################################################

module "powervs_instance" {
  count  = var.enable_powervs && var.enable_powervs_instance ? 1 : 0
  source = "./modules/05-powervs-instance"

  # Core Configuration
  prefix = var.prefix
  tags   = var.tags

  # Workspace Configuration
  pi_workspace_guid = module.powervs_workspace[0].pi_workspace_guid
  pi_zone           = var.powervs_zone
  pi_ssh_key_name   = module.powervs_workspace[0].pi_ssh_public_key.name

  # Network Configuration
  pi_subnet_name = module.powervs_workspace[0].pi_private_subnet_1.name
  pi_subnet_id   = module.powervs_workspace[0].pi_private_subnet_1.id

  # Instance Configuration
  powervs_instance_name       = var.powervs_instance_name
  powervs_instance_image      = var.powervs_instance_image
  powervs_instance_processors = var.powervs_instance_processors
  powervs_instance_memory     = var.powervs_instance_memory
  powervs_instance_proc_type  = var.powervs_instance_proc_type

  # Storage Configuration
  powervs_storage_tier = var.powervs_storage_tier
  powervs_storage_size = var.powervs_storage_size

  # User Data
  pi_user_data = var.powervs_instance_user_data

  depends_on = [module.powervs_workspace]
}