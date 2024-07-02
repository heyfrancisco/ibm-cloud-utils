##############################################################################
# IBM Cloud Account Variables
##############################################################################

variable "ibmcloud_api_key" {
  description = "IBM Cloud API Key associated with the account to provision resources to"
  type        = string
  default     = ""
  sensitive   = true
}

variable "prefix" {
  type        = string
  default     = ""
  description = "A prefix for all resources to be created. If none provided a random prefix will be created"
}

variable "region" {
  description = "IBM Cloud region where all resources will be provisioned (e.g. eu-es)"
  default     = "eu-es"
}

variable "tags" {
  description = "List of Tags"
  type        = list(string)
  default     = ["fro"]
}
