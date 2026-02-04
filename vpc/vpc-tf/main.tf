########################################################################################################################
# Resource group
########################################################################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.2.0"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

########################################################################################################################
# VPC
########################################################################################################################

module "vpc" {
  source            = "terraform-ibm-modules/vpc/ibm"
  vpc_name          = "${var.prefix}-vpc"
  resource_group_id = module.resource_group.resource_group_id
  locations         = ["${var.region}-1", "${var.region}-2", "${var.region}-3"]
  vpc_tags          = var.resource_tags
  address_prefixes = [
    {
      name     = "${var.prefix}-${var.region}-1"
      location = "${var.region}-1"
      ip_range = "10.10.10.0/24"
    },
    {
      name     = "${var.prefix}-${var.region}-2"
      location = "${var.region}-2"
      ip_range = "10.10.20.0/24"
    },
    {
      name     = "${var.prefix}-${var.region}-3"
      location = "${var.region}-3"
      ip_range = "10.10.30.0/24"
    }
  ]

  subnet_name_prefix          = "${var.prefix}-subnet"
  default_network_acl_name    = "${var.prefix}-nacl"
  default_routing_table_name  = "${var.prefix}-routing-table"
  default_security_group_name = "${var.prefix}-sg"
  create_gateway              = true
  public_gateway_name_prefix  = "${var.prefix}-pw"
  number_of_addresses         = 16
}


