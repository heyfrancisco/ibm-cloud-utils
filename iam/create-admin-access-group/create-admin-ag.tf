##############################################################################
# Create an Access Group with full admin privileges
# To run the script > $ terraform plan -var-file="var.tfvars.json"
#############################################################################

# Create Admin Access Group
resource "ibm_iam_access_group" "ag-admin" {
  name        = "admin_ag"
  description = "Administrator Access Group"
}

# Service: All Identity and Access enabled services
# Role: Administrator, Manager
resource "ibm_iam_access_group_policy" "policy-all-iam-services" {
  access_group_id = ibm_iam_access_group.ag-admin.id
  resource_attributes {
    name     = "serviceType"
    operator = "stringEquals"
    value    = "service"
  }
  roles = ["Administrator", "Manager"]
}


# Service: All Account Management Services
# Role: Administrator
resource "ibm_iam_access_group_policy" "policy-account-management" {
  access_group_id = ibm_iam_access_group.ag-admin.id
  roles           = ["Administrator"]
  resource_attributes {
    name     = "serviceType"
    operator = "stringEquals"
    value    = "platform_service"
  }
}

# Service: Resource Group only
# Enables to create RG
resource "ibm_iam_access_group_policy" "policy-resource-group" {
  access_group_id = ibm_iam_access_group.ag-admin.id
  roles           = ["Viewer", "Editor"]
  resources {
    resource_type = "resource-group"
  }
}

# Service: Support Center
# Role: Editor
resource "ibm_iam_access_group_policy" "policy-admin-support" {
  access_group_id = ibm_iam_access_group.ag-admin.id
  roles           = ["Editor"]
  resources {
    service = "support"
  }
}

# Service: Security & Compliance Center
# Role: Administrator, Editor
resource "ibm_iam_access_group_policy" "policy-admin-scc" {
  access_group_id = ibm_iam_access_group.ag-admin.id
  roles           = ["Administrator", "Editor"]
  resources {
    service = "compliance"
  }
}


# Service: IAM Identity Service
# Assign the role "User API key creator" to create API Key
resource "ibm_iam_access_group_policy" "policy-k8s-identity-administrator" {
  access_group_id = ibm_iam_access_group.ag-admin.id
  roles           = ["Administrator", "User API key creator", "Service ID creator"]
  resources {
    service = "iam-identity"
  }
}
