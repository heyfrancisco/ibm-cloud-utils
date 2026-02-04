##############################################################################
# Terraform and Provider Version Constraints
#
# This file defines the required versions for Terraform and providers.
# Version constraints ensure compatibility and prevent breaking changes.
#
# Version Strategy:
# - Terraform: >= 1.3.0 (required for modern features)
# - IBM Cloud Provider: ~> 1.60 (allows minor updates, prevents major changes)
##############################################################################

terraform {
  # Minimum Terraform version required
  # Version 1.3.0+ required for:
  # - Enhanced validation rules
  # - Improved error messages
  # - Better state management
  required_version = ">= 1.3.0"

  # Required providers with version constraints
  required_providers {
    # IBM Cloud Provider
    # Documentation: https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "~> 1.60"
    }

    # Random provider for generating unique identifiers
    # Used for resource naming and unique values
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }

    # Time provider for time-based operations
    # Used for delays and time-based resources
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }

    # Null provider for provisioners and dependencies
    # Used for resource dependencies and triggers
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }

  ##############################################################################
  # Backend Configuration (Optional)
  ##############################################################################
  #
  # Uncomment and configure for remote state storage
  # Recommended for production environments
  #
  # backend "s3" {
  #   # IBM Cloud Object Storage backend configuration
  #   bucket                      = "terraform-state-bucket"
  #   key                         = "landing-zone/terraform.tfstate"
  #   region                      = "us-south"
  #   endpoint                    = "s3.us-south.cloud-object-storage.appdomain.cloud"
  #   skip_credentials_validation = true
  #   skip_region_validation      = true
  #   skip_metadata_api_check     = true
  # }
  #
  # Alternative: Terraform Cloud backend
  # backend "remote" {
  #   organization = "your-organization"
  #   workspaces {
  #     name = "ibm-cloud-landing-zone"
  #   }
  # }
  #
  ##############################################################################
}

##############################################################################
# Version Constraint Notes
##############################################################################
#
# 1. Terraform Version:
#    - ">= 1.3.0" allows any version 1.3.0 or higher
#    - Ensures access to modern Terraform features
#    - Test upgrades in non-production first
#
# 2. Provider Versions:
#    - "~> 1.60" allows 1.60.x but not 2.0.0
#    - Prevents breaking changes from major updates
#    - Allows bug fixes and minor features
#
# 3. Version Pinning:
#    - For production, consider exact versions: "= 1.60.0"
#    - Update versions deliberately after testing
#    - Document version changes in change log
#
# 4. Backend Configuration:
#    - Local backend (default) stores state locally
#    - Remote backend recommended for teams
#    - Enable state locking for concurrent access
#    - Regular state backups are critical
#
# 5. Provider Updates:
#    - Run 'terraform init -upgrade' to update providers
#    - Review provider changelogs before updating
#    - Test in non-production environment first
#
##############################################################################

##############################################################################
# Module Version Requirements
##############################################################################
#
# The following IBM Cloud Terraform modules are used in this project:
#
# 1. landing-zone-vpc: 8.7.0
#    Source: terraform-ibm-modules/landing-zone-vpc/ibm
#
# 2. site-to-site-vpn: 3.0.4
#    Source: terraform-ibm-modules/site-to-site-vpn/ibm
#
# 3. cos: 10.5.0
#    Source: terraform-ibm-modules/cos/ibm
#
# 4. powervs-workspace: 4.1.2
#    Source: terraform-ibm-modules/powervs-workspace/ibm
#
# 5. powervs-instance: 2.8.2
#    Source: terraform-ibm-modules/powervs-instance/ibm
#
# 6. transit-gateway: 2.5.2
#    Source: terraform-ibm-modules/transit-gateway/ibm
#
# 7. vpe-gateway: 4.7.12
#    Source: terraform-ibm-modules/vpe-gateway/ibm
#
# These versions are specified in each module's configuration.
# Refer to IMPLEMENTATION_PLAN.md for detailed module requirements.
#
##############################################################################