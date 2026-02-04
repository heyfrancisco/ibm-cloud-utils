##############################################################################
# IBM Cloud Account Variables
##############################################################################

variable "ibmcloud_api_key" {
  description = "<<-EOT\nIBM Cloud API Key associated with the account to provision resources to.\nTo create an API key, run the following command:\n$ ibmcloud iam api-key-create MyKey -d \"this is my API key\" --file key_file\nEOT"
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

variable "ag" {
  description = "<<-EON\nChoose the Access Group where the user will be added to. To create an Access Group, run the following command:\n$ ibmcloud iam access-group-create MyGroup -d \"this is my Access Group\"\n To list Access Groups, run the following command:\n$ ibmcloud iam ags\nEOT"
  type        = string
}
