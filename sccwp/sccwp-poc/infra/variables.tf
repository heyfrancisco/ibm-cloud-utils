variable "ibmcloud_api_key" {
  type      = string
  sensitive = true
}

variable "region" {
  type    = string
  default = "eu-es"
}

variable "resource_group_name" {
  type = string
}

variable "prefix" {
  type    = string
  default = "sccwp-demo"
}

variable "tags" {
  type    = list(string)
  default = ["env:demo"]
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

variable "instance_profile" {
  type    = string
  default = "nxf-2x2"
}

variable "vpc_cidr" {
  type    = string
  default = "10.10.0.0/16"
}

variable "subnet_cidr" {
  type    = string
  default = "10.10.10.0/24"
}

variable "zone" {
  type    = string
  default = "eu-es-1"
}

variable "sccwp_service_plan" {
  type    = string
  default = "graduated-tier"
}
