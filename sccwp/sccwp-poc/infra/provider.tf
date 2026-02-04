terraform {
  required_providers {
    ibm     = { source = "IBM-Cloud/ibm", version = ">= 1.79.0, < 2.0.0" }
    restapi = { source = "Mastercard/restapi", version = ">= 2.0.1, < 3.0.0" }
  }
}

provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = var.region
}

data "ibm_iam_auth_token" "auth" {}

provider "restapi" {
  uri                  = "https://resource-controller.cloud.ibm.com"
  headers              = { Authorization = data.ibm_iam_auth_token.auth.iam_access_token }
  write_returns_object = true
}

data "ibm_resource_group" "rg" {
  name = var.resource_group_name
}
