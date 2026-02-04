variable "prefix" {
  type = string
}

variable "zone" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "subnet_cidr" {
  type = string
}

variable "resource_group_id" {
  type = string
}

variable "tags" {
  type    = list(string)
  default = []
}
