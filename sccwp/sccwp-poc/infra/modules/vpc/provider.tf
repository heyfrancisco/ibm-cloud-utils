##############################################################################
# IBM CLOUD PROVIDER
##############################################################################

terraform {
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = ">= 1.79.0, < 2.0.0"
    }

    # Needed by terraform-ibm-modules/scc-workload-protection
    restapi = {
      source  = "Mastercard/restapi"
      version = ">= 2.0.1, < 3.0.0"
    }
  }
}

# IAM token to authenticate against the Resource Controller REST API
data "ibm_iam_auth_token" "auth_token" {}

# REST API provider used internally by the SCCWP module
provider "restapi" {
  # Global Resource Controller endpoint (works for all regions)
  # See IBM docs for list of endpoints if you ever need a regional one.
  uri = "https://resource-controller.cloud.ibm.com"

  headers = {
    Authorization = data.ibm_iam_auth_token.auth_token.iam_access_token
  }

  # Required by the SCCWP module so the provider returns a JSON object
  write_returns_object = true
}
