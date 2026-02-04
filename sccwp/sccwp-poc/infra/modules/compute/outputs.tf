output "linux_public_ip" {
  value = ibm_is_floating_ip.fip["linux"].address
}

output "windows_public_ip" {
  value = ibm_is_floating_ip.fip["windows"].address
}

output "linux_private_ip" {
  value = ibm_is_instance.vm["linux"].primary_network_interface[0].primary_ip[0].address
}

output "windows_private_ip" {
  value = ibm_is_instance.vm["windows"].primary_network_interface[0].primary_ip[0].address
}

output "ssh_key_name" {
  value = var.ssh_key_name
}
