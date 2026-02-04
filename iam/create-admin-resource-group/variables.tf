##############################################################################
# IBM Cloud Account Variables
##############################################################################

variable "ibmcloud_api_key" {
  description = "<<-EOT\nIBM Cloud API Key associated with the account to provision resources to.\nTo create an API key, run the following command:\n$ ibmcloud iam api-key-create MyKey -d \"this is my API key\" --file key_file\nEOT"
  type        = string
  sensitive   = true
}

variable "prefix" {
  description = "A prefix for all resources to be created."
  type        = string
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
