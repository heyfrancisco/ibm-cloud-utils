resource "ibm_is_vpc" "vpc" {
  name                      = "${var.prefix}-vpc"
  resource_group            = var.resource_group_id
  address_prefix_management = "manual"
  tags                      = var.tags
}

resource "ibm_is_vpc_address_prefix" "prefix" {
  name = "${var.prefix}-${var.zone}-prefix"
  zone = var.zone
  vpc  = ibm_is_vpc.vpc.id
  cidr = var.vpc_cidr
}

resource "ibm_is_subnet" "subnet" {
  name            = "${var.prefix}-subnet"
  vpc             = ibm_is_vpc.vpc.id
  zone            = var.zone
  ipv4_cidr_block = var.subnet_cidr
  resource_group  = var.resource_group_id
  depends_on      = [ibm_is_vpc_address_prefix.prefix]
}

resource "ibm_is_security_group" "sg" {
  name           = "${var.prefix}-sg"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = var.resource_group_id
  tags           = var.tags
}

resource "ibm_is_security_group_rule" "inbound_tcp" {
  for_each  = { ssh = 22, rdp = 3389 }
  group     = ibm_is_security_group.sg.id
  direction = "inbound"
  remote    = "0.0.0.0/0"

  tcp {
    port_min = each.value
    port_max = each.value
  }
}

resource "ibm_is_security_group_rule" "egress_all" {
  group     = ibm_is_security_group.sg.id
  direction = "outbound"
  remote    = "0.0.0.0/0"
}
