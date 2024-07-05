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
  description = "A prefix for all resources to be created"
}

/* Zones for PowerVS in Madrid
mad02
mad04
*/
variable "region" {
  description = "IBM Cloud Region where all resources will be provisioned (e.g. eu-es)"
  default     = "eu-es"
}

variable "zone" {
  description = "IBM Cloud Zone for PowerVS"
  default     = ""
}

variable "tags" {
  description = "List of Tags"
  type        = list(string)
  default     = ["fro"]
}

variable "pws_id" {
  description = "ID of the Power Workspace"
}

variable "pvs_name" {
  description = "Name of the Power VSI to capture"
}

variable "pvs_id" {
  description = "ID of the Power VSI to capture"
}

variable "capture_image_name" {
  description = "Name of the captured image"
  default     = "image-capture"
}

variable "pvs_volume" {
  description = "Names of the volumes to include"
}

variable "destination" {
  description = "Destination for the captured image (image-catalog, cloud-storage, both)"
  default     = "image-catalog"
}
