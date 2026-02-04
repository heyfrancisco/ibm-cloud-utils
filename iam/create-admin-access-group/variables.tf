##############################################################################
# IBM Cloud Account Variables
##############################################################################

variable "ibmcloud_api_key" {
  description = "\nIBM Cloud API Key associated with the account to provision resources to.\nTo create an API key, run the following command:\n$ ibmcloud iam api-key-create MyKey -d \"this is my API key\" --file key_file\n"
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
