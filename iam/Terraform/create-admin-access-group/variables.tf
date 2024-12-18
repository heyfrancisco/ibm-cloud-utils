##############################################################################
# IBM Cloud Account Variables
##############################################################################

variable "ibmcloud_api_key" {
  description = "IBM Cloud API Key associated with the account to provision resources to."
  type        = string
  sensitive   = true
}

variable "region" {
  description = "IBM Cloud region where all resources will be provisioned (e.g. eu-es)."
  default     = "eu-es"
}

variable "tags" {
  description = "List of Tags"
  type        = list(string)
  default     = ["fro"]
}
