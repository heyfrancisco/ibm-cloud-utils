variable "prefix" {
  type = string
}

variable "zone" {
  type = string
}

variable "resource_group_id" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "security_group_id" {
  type = string
}

variable "instance_profile" {
  type = string
}

variable "ssh_key_name" {
  type = string
}

variable "linux_image_name" {
  type = string
}

variable "windows_image_name" {
  type = string
}

variable "tags" {
  type    = list(string)
  default = []
}
