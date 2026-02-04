output "vpc_id" {
  value = ibm_is_vpc.vpc.id
}

output "subnet_id" {
  value = ibm_is_subnet.subnet.id
}

output "security_group_id" {
  value = ibm_is_security_group.sg.id
}
