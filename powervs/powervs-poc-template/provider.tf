##############################################################################
# IBM Cloud Provider Configuration
#
# This file configures the IBM Cloud provider for Terraform.
# The provider is used to interact with IBM Cloud resources.
#
# Prerequisites:
# - IBM Cloud API key with appropriate permissions
# - Set IC_API_KEY environment variable or use ibmcloud_api_key variable
#
# Usage:
#   export IC_API_KEY="your-api-key-here"
#   terraform init
##############################################################################

##############################################################################
# Data Sources
##############################################################################

# Look up default resource group by name
data "ibm_resource_group" "resource_group" {
  name = var.resource_group_name
}

# Look up VPC resource group (uses default if not specified)
data "ibm_resource_group" "vpc_resource_group" {
  name = var.vpc_resource_group_name != null ? var.vpc_resource_group_name : var.resource_group_name
}

# Look up COS resource group (uses default if not specified)
data "ibm_resource_group" "cos_resource_group" {
  name = var.cos_resource_group_name != null ? var.cos_resource_group_name : var.resource_group_name
}

# Look up PowerVS resource group (uses default if not specified)
data "ibm_resource_group" "powervs_resource_group" {
  name = var.powervs_resource_group_name != null ? var.powervs_resource_group_name : var.resource_group_name
}

##############################################################################
# IBM Cloud Provider
# Documentation: https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs
provider "ibm" {
  # IBM Cloud API Key
  # Best practice: Use environment variable IC_API_KEY instead of hardcoding
  # ibmcloud_api_key = var.ibmcloud_api_key

  # Region for VPC and other regional resources
  region = var.region

  # IBM Cloud Account ID (optional, auto-detected if not specified)
  # ibmcloud_account_id = var.ibmcloud_account_id

  # Timeout settings for API calls
  ibmcloud_timeout = 300

  # Retry settings for transient failures
  max_retries = 3
}

# IBM Cloud Provider for PowerVS (Power Systems Virtual Server)
# PowerVS requires a separate provider configuration with zone-specific endpoints
provider "ibm" {
  alias = "powervs"

  # IBM Cloud API Key
  # Best practice: Use environment variable IC_API_KEY instead of hardcoding
  # ibmcloud_api_key = var.ibmcloud_api_key

  # PowerVS zone (e.g., dal10, us-south, etc.)
  zone = var.powervs_zone

  # Region for PowerVS resources
  region = var.region

  # Timeout settings for API calls
  ibmcloud_timeout = 300

  # Retry settings for transient failures
  max_retries = 3
}

##############################################################################
# Provider Configuration Notes
##############################################################################
#
# 1. API Key Management:
#    - Never commit API keys to version control
#    - Use environment variables: export IC_API_KEY="your-key"
#    - Or use IBM Cloud Secrets Manager for production
#
# 2. Region Selection:
#    - VPC resources use the 'region' parameter
#    - PowerVS resources use the 'zone' parameter
#    - Ensure region and zone are compatible
#
# 3. Multiple Provider Instances:
#    - Default provider for VPC, COS, Transit Gateway, VPE
#    - 'powervs' alias for PowerVS workspace and instances
#
# 4. Timeout and Retry:
#    - Increased timeout for long-running operations
#    - Automatic retry for transient API failures
#
# 5. Authentication Methods:
#    - Environment variable: IC_API_KEY (recommended)
#    - Provider configuration: ibmcloud_api_key
#    - IBM Cloud CLI: ibmcloud login
#
##############################################################################