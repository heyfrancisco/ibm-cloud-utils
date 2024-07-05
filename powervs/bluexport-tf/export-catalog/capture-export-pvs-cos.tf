##############################################################################
# Capture IBM Cloud POWERVS VSI and Export to COS or/and Image Catalog
# To run the script > $ terraform plan -var-file="var.tfvars.json"
##############################################################################

locals {
  CURRENT_TIME = formatdate("YYYYMMDD_HHmmss", timestamp())
}

# Fetches the details of the Power VSI.
data "ibm_pi_instance" "vsi" {
  pi_cloud_instance_id = var.pws_id
  pi_instance_name     = var.pvs_name
}

# Fetches the volumes attached to the Power VSI, excluding specified volumes.
data "ibm_pi_volume" "vsi_volumes" {
  pi_cloud_instance_id = var.pws_id
  pi_volume_name       = var.pvs_volume
}

# Captures the Power VSI image and exports it to the specified destination (COS or image catalog)
resource "ibm_pi_capture" "capture_image" {
  pi_cloud_instance_id   = var.pws_id
  pi_capture_name        = "${var.capture_image_name}-${var.pvs_name}-${local.CURRENT_TIME}"
  pi_instance_name       = var.pvs_name
  pi_capture_destination = var.destination
}
