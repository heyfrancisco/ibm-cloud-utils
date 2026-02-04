module "vpc" {
  source            = "./modules/vpc"
  prefix            = var.prefix
  zone              = var.zone
  vpc_cidr          = var.vpc_cidr
  subnet_cidr       = var.subnet_cidr
  resource_group_id = data.ibm_resource_group.rg.id
  tags              = var.tags
}

module "compute" {
  source = "./modules/compute"
  prefix             = var.prefix
  zone               = var.zone
  resource_group_id  = data.ibm_resource_group.rg.id
  vpc_id             = module.vpc.vpc_id
  subnet_id          = module.vpc.subnet_id
  security_group_id  = module.vpc.security_group_id
  instance_profile   = var.instance_profile
  ssh_key_name       = var.ssh_key_name
  linux_image_name   = var.linux_image_name
  windows_image_name = var.windows_image_name
  tags               = var.tags
}

module "scc_wp" {
  source  = "terraform-ibm-modules/scc-workload-protection/ibm"
  version = "1.16.1"
  name                = "${var.prefix}-instance"
  region              = var.region
  resource_group_id   = data.ibm_resource_group.rg.id
  resource_tags       = var.tags
  scc_wp_service_plan = var.sccwp_service_plan
  cspm_enabled        = false
}
