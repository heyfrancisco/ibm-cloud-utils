output "vpc_id" {
  value = module.vpc.vpc_id
}

output "subnet_id" {
  value = module.vpc.subnet_id
}

output "security_group_id" {
  value = module.vpc.security_group_id
}

output "linux_public_ip" {
  value = module.compute.linux_public_ip
}

output "windows_public_ip" {
  value = module.compute.windows_public_ip
}

output "linux_private_ip" {
  value = module.compute.linux_private_ip
}

output "windows_private_ip" {
  value = module.compute.windows_private_ip
}

output "ssh_key_name" {
  value = module.compute.ssh_key_name
}
