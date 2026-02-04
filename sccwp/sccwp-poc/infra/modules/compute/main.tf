data "ibm_is_ssh_key" "key" { name = var.ssh_key_name }
data "ibm_is_image" "linux" { name = var.linux_image_name }
data "ibm_is_image" "windows" { name = var.windows_image_name }

locals {
  instances = {
    linux   = data.ibm_is_image.linux.id
    windows = data.ibm_is_image.windows.id
  }
}

resource "ibm_is_instance" "vm" {
  for_each       = local.instances
  name           = "${var.prefix}-${each.key}"
  vpc            = var.vpc_id
  zone           = var.zone
  profile        = var.instance_profile
  image          = each.value
  resource_group = var.resource_group_id
  keys           = [data.ibm_is_ssh_key.key.id]
  tags           = var.tags

  primary_network_interface {
    subnet          = var.subnet_id
    security_groups = [var.security_group_id]
  }
}

resource "ibm_is_floating_ip" "fip" {
  for_each       = ibm_is_instance.vm
  name           = "${var.prefix}-${each.key}-fip"
  target         = each.value.primary_network_interface[0].id
  resource_group = var.resource_group_id
  tags           = var.tags
}
