##############################################################################
# Create a resource group or reuse an existing one
##############################################################################

resource "ibm_resource_group" "group" {
  name = "admin_rg"
}

