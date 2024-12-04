##############################################################################
# Capture IBM Cloud POWERVS VSI and Export to COS or/and Image Catalog
# To run the script > $ terraform plan -var-file="var.tfvars.json"
##############################################################################

resource "random_integer" "random_4digit" {
  min = 1000
  max = 9999
}

locals {
  TIMESTAMP = "${formatdate("YYYYMMDD_HHmmss", timestamp())}-${random_integer.random_4digit.result}"
}

# Captures the Power VSI image and exports it to the specified destination (COS or image catalog)
resource "ibm_pi_capture" "capture_image" {
  pi_cloud_instance_id   = var.pws_id
  pi_capture_name        = "${var.pvs_name}-${local.TIMESTAMP}"
  pi_instance_name       = var.pvs_name
  pi_capture_destination = var.destination
}
