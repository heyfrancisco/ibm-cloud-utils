#!/bin/bash

##############################################################################
# IBM Cloud POC Account Setup Script
# 
# This script configures a new IBM Cloud account with:
# 1. Admin access group with full privileges
# 2. Admin resource group
# 3. User invitations to the account
#
# Usage: ./setup-poc-account.sh
##############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ACCESS_GROUP_NAME="admin_ag"
RESOURCE_GROUP_NAME="admin_rg"

##############################################################################
# Helper Functions
##############################################################################

print_header() {
    echo -e "\n${BLUE}===================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}===================================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

check_ibmcloud_login() {
    if ! ibmcloud target &>/dev/null; then
        print_error "Not logged in to IBM Cloud"
        echo "Please run: ibmcloud login"
        exit 1
    fi
    print_success "IBM Cloud CLI authenticated"
}

##############################################################################
# Step 1: Create Access Group
##############################################################################

create_access_group() {
    print_header "Step 1: Creating Access Group '${ACCESS_GROUP_NAME}'"
    
    # Check if access group already exists
    if ibmcloud iam access-group "${ACCESS_GROUP_NAME}" &>/dev/null; then
        print_warning "Access group '${ACCESS_GROUP_NAME}' already exists"
        read -p "Do you want to skip this step? (y/n): " skip_ag
        if [[ "$skip_ag" =~ ^[Yy]$ ]]; then
            print_info "Skipping access group creation"
            return 0
        fi
        print_error "Access group already exists. Exiting."
        exit 1
    fi
    
    # Create access group
    print_info "Creating access group..."
    if ibmcloud iam access-group-create "${ACCESS_GROUP_NAME}" -d "Administrator Access Group" &>/dev/null; then
        print_success "Access group '${ACCESS_GROUP_NAME}' created successfully"
    else
        print_error "Failed to create access group"
        exit 1
    fi
    
    # Get access group ID
    AG_ID=$(ibmcloud iam access-group "${ACCESS_GROUP_NAME}" --output json | grep -o '"id": "[^"]*' | grep -o '[^"]*$' | head -1)
    
    if [ -z "$AG_ID" ]; then
        print_error "Failed to retrieve access group ID"
        exit 1
    fi
    
    print_info "Access group ID: ${AG_ID}"
}

##############################################################################
# Step 2: Assign Policies to Access Group
##############################################################################

assign_policies() {
    print_header "Step 2: Assigning Policies to Access Group"
    
    # Policy 1: All Identity and Access enabled services - Administrator, Manager
    print_info "Assigning policy: All IAM services (Administrator, Manager)..."
    if ibmcloud iam access-group-policy-create "${ACCESS_GROUP_NAME}" \
        --roles Administrator,Manager \
        --attributes "serviceType=service" &>/dev/null; then
        print_success "Policy assigned: All IAM services"
    else
        print_error "Failed to assign policy: All IAM services"
    fi
    
    # Policy 2: All Account Management Services - Administrator
    print_info "Assigning policy: All Account Management (Administrator)..."
    if ibmcloud iam access-group-policy-create "${ACCESS_GROUP_NAME}" \
        --roles Administrator \
        --attributes "serviceType=platform_service" &>/dev/null; then
        print_success "Policy assigned: All Account Management"
    else
        print_error "Failed to assign policy: All Account Management"
    fi
    
    # Policy 3: Resource Group - Viewer, Editor
    print_info "Assigning policy: Resource Group (Viewer, Editor)..."
    if ibmcloud iam access-group-policy-create "${ACCESS_GROUP_NAME}" \
        --roles Viewer,Editor \
        --resource-type resource-group &>/dev/null; then
        print_success "Policy assigned: Resource Group"
    else
        print_error "Failed to assign policy: Resource Group"
    fi
    
    # Policy 4: Support Center - Editor
    print_info "Assigning policy: Support Center (Editor)..."
    if ibmcloud iam access-group-policy-create "${ACCESS_GROUP_NAME}" \
        --roles Editor \
        --service-name support &>/dev/null; then
        print_success "Policy assigned: Support Center"
    else
        print_error "Failed to assign policy: Support Center"
    fi
    
    # Policy 5: Security & Compliance Center - Administrator, Editor
    print_info "Assigning policy: Security & Compliance Center (Administrator, Editor)..."
    if ibmcloud iam access-group-policy-create "${ACCESS_GROUP_NAME}" \
        --roles Administrator,Editor \
        --service-name compliance &>/dev/null; then
        print_success "Policy assigned: Security & Compliance Center"
    else
        print_error "Failed to assign policy: Security & Compliance Center"
    fi
    
    # Policy 6: IAM Identity Service - Administrator, User API key creator, Service ID creator
    print_info "Assigning policy: IAM Identity Service (Administrator, User API key creator, Service ID creator)..."
    if ibmcloud iam access-group-policy-create "${ACCESS_GROUP_NAME}" \
        --roles Administrator,"User API key creator","Service ID creator" \
        --service-name iam-identity &>/dev/null; then
        print_success "Policy assigned: IAM Identity Service"
    else
        print_error "Failed to assign policy: IAM Identity Service"
    fi
    
    print_success "All policies assigned successfully"
}

##############################################################################
# Step 3: Create Resource Group
##############################################################################

create_resource_group() {
    print_header "Step 3: Creating Resource Group '${RESOURCE_GROUP_NAME}'"
    
    # Check if resource group already exists
    if ibmcloud resource group "${RESOURCE_GROUP_NAME}" &>/dev/null; then
        print_warning "Resource group '${RESOURCE_GROUP_NAME}' already exists"
        read -p "Do you want to skip this step? (y/n): " skip_rg
        if [[ "$skip_rg" =~ ^[Yy]$ ]]; then
            print_info "Skipping resource group creation"
            return 0
        fi
        print_error "Resource group already exists. Exiting."
        exit 1
    fi
    
    # Create resource group
    print_info "Creating resource group..."
    if ibmcloud resource group-create "${RESOURCE_GROUP_NAME}" &>/dev/null; then
        print_success "Resource group '${RESOURCE_GROUP_NAME}' created successfully"
    else
        print_error "Failed to create resource group"
        exit 1
    fi
}

##############################################################################
# Step 4: Invite Users
##############################################################################

invite_users() {
    print_header "Step 4: Inviting Users to Account"
    
    echo -e "${YELLOW}Enter email addresses to invite (one per line, empty line to finish):${NC}"
    
    emails=()
    while true; do
        read -p "Email: " email
        if [ -z "$email" ]; then
            break
        fi
        emails+=("$email")
    done
    
    if [ ${#emails[@]} -eq 0 ]; then
        print_warning "No email addresses provided. Skipping user invitations."
        return 0
    fi
    
    print_info "Inviting ${#emails[@]} user(s) to the account and adding to '${ACCESS_GROUP_NAME}'..."
    
    for email in "${emails[@]}"; do
        print_info "Inviting: ${email}"
        if ibmcloud account user-invite "${email}" --access-groups "${ACCESS_GROUP_NAME}" &>/dev/null; then
            print_success "Invited: ${email}"
        else
            print_error "Failed to invite: ${email}"
        fi
    done
    
    print_success "User invitation process completed"
}

##############################################################################
# Main Execution
##############################################################################

main() {
    print_header "IBM Cloud POC Account Setup"
    
    # Check IBM Cloud CLI login
    check_ibmcloud_login
    
    # Display current account
    ACCOUNT_NAME=$(ibmcloud target --output json | grep -o '"name": "[^"]*' | grep -o '[^"]*$' | head -1)
    print_info "Current account: ${ACCOUNT_NAME}"
    
    echo ""
    read -p "Continue with setup? (y/n): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_warning "Setup cancelled by user"
        exit 0
    fi
    
    # Execute setup steps
    create_access_group
    assign_policies
    create_resource_group
    invite_users
    
    # Summary
    print_header "Setup Complete!"
    print_success "Access Group: ${ACCESS_GROUP_NAME}"
    print_success "Resource Group: ${RESOURCE_GROUP_NAME}"
    print_info "Users have been invited and added to the admin access group"
    
    echo -e "\n${GREEN}POC account setup completed successfully!${NC}\n"
}

# Run main function
main
