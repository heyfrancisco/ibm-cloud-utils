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
  type        = string
  default     = "eu-es"
}

variable "zone" {
  description = "IBM Cloud Zone for PowerVS"
  type        = string
  default     = ""
}

variable "tags" {
  description = "List of Tags"
  type        = list(string)
  default     = ["fro"]
}

variable "pws_id" {
  description = "ID of the Power Workspace"
  type        = string
}

variable "pvs_name" {
  description = "Name of the Power VSI to capture"
  type        = string
}

variable "pvs_id" {
  description = "ID of the Power VSI to capture"
  type        = string
}

variable "capture_image_name" {
  description = "Name of the captured image"
  type        = string
  default     = "image-capture"
}

variable "pvs_volume" {
  description = "Names of the volumes to include"
  type        = string
}

variable "destination" {
  description = "Destination for the captured image (image-catalog, cloud-storage, both)"
  type        = string
  default     = "image-catalog"
}
