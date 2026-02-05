---

description: "Task list for PowerVS POC Template infrastructure implementation"
---

# Tasks: PowerVS POC Template

**Input**: Design documents from `/specs/001-powervs-poc/`
**Prerequisites**: plan.md (required), spec.md (required)

**Infrastructure**: PowerVS workspace connected to VPC via Transit Gateway, with policy-based VPN for customer on-premises connectivity and Cloud Object Storage accessible via Virtual Private Endpoint (VPE).

**Organization**: Tasks grouped by infrastructure tier following dependency hierarchy (Foundation → Network → Compute/Data → Application)

## Format: `[ID] [P?] Description`

- **[ID]**: Sequential task number (T001, T002, T003...)
- **[P]**: Can run in parallel (different files, no dependencies) - optional
- **Description**: Clear action with exact file path included

Tasks are organized by infrastructure tier in the phase structure below

## Path Conventions

- **IaC files**: Root directory (pvs-poc-template/)
- **Terraform**: `*.tf`, `terraform.tfvars.example`, `modules/*/`
- **Documentation**: `docs/`, `README.md`
- **Examples**: `examples/customer-deployment/`

---

## Phase 1: Setup

**Purpose**: Terraform project initialization, backend configuration, and directory structure

- [X] T001 Create root directory structure (modules/, examples/, docs/) per plan.md
- [X] T002 [P] Create versions.tf with Terraform >= 1.7.0 and IBM provider ~> 1.63 version constraints
- [X] T003 [P] Create provider.tf with IBM Cloud provider configuration for eu-es region
- [X] T004 [P] Create variables.tf with input variables (customer_id, vpc_subnet_cidr, powervs_subnet_cidr, VPN config, COS bucket name, resource_group_id, ibmcloud_api_key, tags)
- [X] T005 [P] Create outputs.tf with outputs (vpn_gateway_public_ip, vpn_connection_status, powervs_workspace_id, cos_bucket_endpoint, vpc_subnet_cidr, powervs_subnet_cidr)
- [X] T006 [P] Create terraform.tfvars.example with example variable values and documentation
- [X] T007 [P] Create .gitignore to exclude .terraform/, *.tfstate, *.tfvars (except .example), .terraform.lock.hcl
- [X] T008 Configure Terraform backend for IBM Cloud Object Storage (S3-compatible) in versions.tf with bucket "terraform-state-powervs-poc", key pattern "customers/${var.customer_id}/terraform.tfstate", region "eu-es"
- [X] T009 Create modules/ directory structure (powervs-workspace/, vpc-network/, transit-gateway/, vpn-gateway/, cos-storage/)
- [X] T010 Run `terraform init` to initialize backend and download IBM provider
- [X] T011 Run `terraform validate` - setup checkpoint

---

## Phase 2: Network Tier

**Purpose**: Network infrastructure - VPC, PowerVS workspace, Transit Gateway, security groups

**⚠️ CRITICAL**: Network tier MUST complete before VPN and storage resources can be provisioned

### VPC Network Module

- [X] T012 Create modules/vpc-network/variables.tf with inputs (customer_id, vpc_subnet_cidr, resource_group_id, tags)
- [X] T013 Create modules/vpc-network/outputs.tf with outputs (vpc_id, vpc_crn, subnet_id, subnet_cidr)
- [X] T014 Create modules/vpc-network/main.tf using terraform-ibm-modules/vpc/ibm module to create VPC with manual address prefix (10.240.0.0/24 default), single subnet in eu-es-1 zone, no public gateway (private connectivity only)

### PowerVS Workspace Module

- [X] T015 Create modules/powervs-workspace/variables.tf with inputs (customer_id, powervs_subnet_cidr, resource_group_id, tags)
- [X] T016 Create modules/powervs-workspace/outputs.tf with outputs (workspace_id, workspace_crn, workspace_guid, subnet_id, subnet_cidr)
- [X] T017 Create modules/powervs-workspace/main.tf using terraform-ibm-modules/powervs-workspace/ibm module to create PowerVS workspace in mad02 zone with private subnet (10.241.0.0/24 default)

### Transit Gateway Module

- [X] T018 Create modules/transit-gateway/variables.tf with inputs (customer_id, powervs_workspace_crn, vpc_crn, resource_group_id, tags)
- [X] T019 Create modules/transit-gateway/outputs.tf with outputs (transit_gateway_id, transit_gateway_crn, connection_status)
- [X] T020 Create modules/transit-gateway/main.tf using terraform-ibm-modules/transit-gateway/ibm module to create local Transit Gateway with connections to PowerVS workspace and VPC, enable route propagation

### Security Groups

- [X] T021 Create modules/vpc-network/security-groups.tf with VPN gateway security group (inbound UDP 500/4500 from customer VPN peer, outbound to PowerVS subnet 10.241.0.0/24 and customer on-prem CIDRs)
- [X] T022 [P] Create modules/vpc-network/security-groups.tf with VPE gateway security group (inbound HTTPS 443 from VPC subnet 10.240.0.0/24 and PowerVS subnet 10.241.0.0/24, outbound HTTPS 443 to COS endpoints)

### Network Tier Validation

- [X] T023 Run `terraform validate` - network tier checkpoint

**Checkpoint**: Network tier complete - VPN gateway and storage resources can now be provisioned

---

## Phase 3: Connectivity & Storage Tier

**Purpose**: VPN Gateway for customer connectivity and Cloud Object Storage with VPE

**Dependencies**: Requires Network Tier (Phase 2) to be complete

### VPN Gateway Module

- [X] T024 Create modules/vpn-gateway/variables.tf with inputs (customer_id, vpc_id, subnet_id, customer_vpn_peer_address, customer_vpn_preshared_key, customer_on_prem_cidrs, vpc_subnet_cidr, powervs_subnet_cidr, security_group_id, tags)
- [X] T025 Create modules/vpn-gateway/outputs.tf with outputs (vpn_gateway_id, vpn_gateway_public_ip, vpn_connection_id, vpn_connection_status)
- [X] T026 Create modules/vpn-gateway/main.tf using terraform-ibm-modules/vpn-gateway/ibm module to create policy-based VPN gateway in VPC subnet with IKEv2, AES-256-CBC encryption, SHA-256 authentication, DH Group 14, connection to customer VPN peer with pre-shared key, local CIDRs (VPC + PowerVS subnets), remote CIDRs (customer on-prem)

### Cloud Object Storage Module

- [X] T027 Create modules/cos-storage/variables.tf with inputs (customer_id, cos_bucket_name, vpc_id, subnet_id, resource_group_id, security_group_id, tags)
- [X] T028 Create modules/cos-storage/outputs.tf with outputs (cos_instance_id, cos_bucket_name, cos_bucket_id, vpe_gateway_id, private_endpoint)
- [X] T029 Create modules/cos-storage/main.tf using terraform-ibm-modules/cos/ibm module to create COS instance and regional bucket (eu-es) with standard storage class, force_delete enabled for POC cleanup, bucket naming pattern {customer-id}-powervs-poc-{timestamp}
- [X] T030 [P] Create modules/cos-storage/vpe.tf to create Virtual Private Endpoint gateway in VPC subnet connecting to COS regional endpoint (s3.direct.eu-es.cloud-object-storage.appdomain.cloud), attach VPE security group

### Connectivity & Storage Validation

- [X] T031 Run `terraform validate` - connectivity & storage tier checkpoint

**Checkpoint**: Connectivity and storage tier complete - root module orchestration can now be implemented

---

## Phase 4: Root Module Orchestration

**Purpose**: Orchestrate all modules in main.tf with proper dependencies

**Dependencies**: Requires all module definitions (Phase 2 & 3) to be complete

- [X] T032 Create main.tf to instantiate vpc-network module with customer_id, vpc_subnet_cidr, resource_group_id, tags
- [X] T033 Add powervs-workspace module to main.tf with customer_id, powervs_subnet_cidr, resource_group_id, tags
- [X] T034 Add transit-gateway module to main.tf with customer_id, powervs_workspace_crn from powervs-workspace output, vpc_crn from vpc-network output, resource_group_id, tags, explicit depends_on for vpc-network and powervs-workspace modules
- [X] T035 Add vpn-gateway module to main.tf with customer_id, vpc_id and subnet_id from vpc-network outputs, customer VPN configuration variables, vpc_subnet_cidr, powervs_subnet_cidr, security_group_id from vpc-network, tags, explicit depends_on for vpc-network module
- [X] T036 Add cos-storage module to main.tf with customer_id, cos_bucket_name, vpc_id and subnet_id from vpc-network outputs, resource_group_id, security_group_id from vpc-network, tags, explicit depends_on for vpc-network module
- [X] T037 Run `terraform validate` - root module checkpoint
- [X] T038 Run `terraform plan -var-file=terraform.tfvars.example` to preview infrastructure (expect errors due to missing actual values, verify structure is correct)

---

## Phase 5: Documentation & Examples

**Purpose**: Documentation, deployment guides, and example configurations

**Dependencies**: Requires root module orchestration (Phase 4) to be complete

### Core Documentation

- [ ] T039 Create README.md with template overview, features (PowerVS workspace, VPC, Transit Gateway, VPN, COS with VPE), prerequisites (IBM Cloud account, Terraform 1.7+, customer VPN details), quick start instructions, architecture diagram reference
- [ ] T040 [P] Create docs/architecture.md with detailed network topology diagram (ASCII art or Mermaid), component descriptions, network flow explanations, security architecture
- [ ] T041 [P] Create docs/deployment-guide.md with step-by-step deployment instructions (clone repo, configure variables, initialize Terraform, plan and apply, capture outputs), validation steps (verify resources in IBM Cloud console, test connectivity), troubleshooting common issues
- [ ] T042 [P] Create docs/customer-handoff.md with VPN configuration guide for customers (VPN gateway public IP, pre-shared key handling, IPsec parameters, routing configuration), network information (VPC CIDR, PowerVS CIDR), COS access instructions

### Example Deployment

- [ ] T043 Create examples/customer-deployment/ directory structure
- [ ] T044 Create examples/customer-deployment/main.tf that references root module with example configuration
- [ ] T045 Create examples/customer-deployment/terraform.tfvars with example values for ACME Corporation (customer_id="acme-corp", vpc_subnet_cidr="10.240.0.0/24", powervs_subnet_cidr="10.241.0.0/24", placeholder VPN config, cos_bucket_name="acme-corp-powervs-poc-20260205")
- [ ] T046 Create examples/customer-deployment/README.md with example-specific instructions and notes

### Additional Documentation

- [ ] T047 [P] Create docs/teardown-guide.md with resource cleanup procedures (terraform destroy command, verification steps, state file cleanup, cost verification)
- [ ] T048 [P] Create docs/variables.md with comprehensive variable documentation (name, type, description, default, required/optional, examples for each variable)
- [ ] T049 [P] Add module-level README.md files to each module directory (modules/powervs-workspace/README.md, modules/vpc-network/README.md, modules/transit-gateway/README.md, modules/vpn-gateway/README.md, modules/cos-storage/README.md) with module purpose, inputs, outputs, usage examples

---

## Phase 6: Polish & Validation

**Purpose**: Final validation, formatting, security checks, and deployment readiness

**Dependencies**: Requires all previous phases to be complete

### Code Quality

- [ ] T050 Run `terraform fmt -recursive` to format all .tf files in root and modules
- [ ] T051 Run `terraform validate` on root module to verify all configurations
- [ ] T052 [P] Validate each module independently (cd into each module directory, run terraform init and terraform validate)
- [ ] T053 [P] Review all variable descriptions and defaults for clarity and correctness
- [ ] T054 [P] Review all output descriptions for completeness

### Security & Best Practices

- [ ] T055 [P] Verify no hardcoded credentials in any .tf files (API keys, pre-shared keys should be variables)
- [ ] T056 [P] Verify sensitive variables marked with sensitive = true (customer_vpn_preshared_key, ibmcloud_api_key)
- [ ] T057 [P] Verify all resources have appropriate tags (customer_id, environment, project, created_by)
- [ ] T058 [P] Verify security groups follow least privilege (only required ports open, specific source/destination CIDRs)
- [ ] T059 [P] Verify no public internet gateways attached to PowerVS or VPC subnets (private connectivity only)

### Infrastructure Validation

- [ ] T060 Verify VPC subnet CIDR is configurable via variable (default 10.240.0.0/24)
- [ ] T061 Verify PowerVS subnet CIDR is configurable via variable (default 10.241.0.0/24)
- [ ] T062 Verify COS bucket naming follows pattern {customer-id}-powervs-poc-{timestamp} or custom value
- [ ] T063 Verify Transit Gateway connects both PowerVS workspace and VPC with route propagation enabled
- [ ] T064 Verify VPN gateway configuration includes all required parameters (peer address, pre-shared key, local/remote CIDRs)
- [ ] T065 Verify VPE gateway connects to COS regional endpoint (eu-es) with private DNS resolution

### Final Checks

- [ ] T066 Run `terraform plan` with example terraform.tfvars to verify plan generation (expect errors for missing actual credentials, verify resource count and types are correct)
- [ ] T067 [P] Verify .gitignore excludes all sensitive files (*.tfstate, *.tfvars except .example, .terraform/)
- [ ] T068 [P] Verify terraform.tfvars.example includes all required variables with example values and clear comments
- [ ] T069 [P] Verify README.md includes link to all documentation files
- [ ] T070 [P] Verify all documentation files are complete and accurate (no TODO placeholders, all links work)
- [ ] T071 Final review of project structure matches plan.md directory layout
- [ ] T072 Create CHANGELOG.md with initial release notes (v1.0.0, features, requirements, known limitations)

---

## Dependencies & Execution Order

### Phase Dependencies

**PowerVS POC Template - Execution Pattern:**
- **Phase 1: Setup**: No dependencies - can start immediately
- **Phase 2: Network Tier**: Depends on Setup - BLOCKS all connectivity and storage resources
- **Phase 3: Connectivity & Storage Tier**: Depends on Network Tier - VPN and COS require VPC and subnets
- **Phase 4: Root Module Orchestration**: Depends on all module definitions being complete
- **Phase 5: Documentation & Examples**: Depends on root module orchestration
- **Phase 6: Polish & Validation**: Depends on all previous phases

### Critical Infrastructure Dependencies

**Network Foundation (Phase 2):**
- VPC and subnets MUST exist before VPN gateway
- VPC and subnets MUST exist before VPE gateway
- PowerVS workspace MUST exist before Transit Gateway connection
- VPC MUST exist before Transit Gateway connection
- Security groups MUST be defined before VPN and VPE gateways reference them

**Connectivity & Storage (Phase 3):**
- VPN gateway requires VPC, subnet, and security group from Phase 2
- COS VPE gateway requires VPC, subnet, and security group from Phase 2
- Transit Gateway must complete before VPN routing can work properly

**Module Dependencies:**
- All module definitions (T012-T030) must complete before root module orchestration (T032-T036)
- Root module must complete before documentation can reference actual implementation

### Validation Checkpoints

- **T011**: Setup validation - Terraform initialized, providers downloaded
- **T023**: Network tier validation - VPC, PowerVS, Transit Gateway, security groups defined
- **T031**: Connectivity & storage validation - VPN and COS modules defined
- **T037**: Root module validation - All modules orchestrated correctly
- **T051**: Final validation - All code formatted and validated

### Parallel Opportunities

**Within Phase 1 (Setup):**
- T002, T003, T004, T005, T006, T007 can run in parallel (different files)

**Within Phase 2 (Network Tier):**
- VPC module files (T012-T014) can run in parallel with PowerVS module files (T015-T017)
- Transit Gateway module files (T018-T020) must wait for VPC and PowerVS outputs
- Security group files (T021, T022) can run in parallel (different security groups)

**Within Phase 3 (Connectivity & Storage):**
- VPN module files (T024-T026) can run in parallel with COS module files (T027-T030)

**Within Phase 5 (Documentation):**
- T040, T041, T042, T047, T048, T049 can all run in parallel (different documentation files)

**Within Phase 6 (Polish):**
- T052, T053, T054 can run in parallel (independent validation tasks)
- T055-T059 can run in parallel (independent security checks)
- T067, T068, T069, T070 can run in parallel (independent documentation checks)

### When Tasks CANNOT Be Parallel

**CRITICAL: Tasks CANNOT run in parallel when:**

1. **Same File Modification**:
   - ❌ T021 and T022 both modify security-groups.tf (must be sequential or split into separate files)
   - ✅ T012 (vpc-network/variables.tf) and T015 (powervs-workspace/variables.tf) - different files

2. **Module Dependencies**:
   - ❌ T034 (Transit Gateway in main.tf) before T032-T033 complete (needs VPC and PowerVS outputs)
   - ❌ T035 (VPN in main.tf) before T032 completes (needs VPC outputs)
   - ✅ T024-T026 (VPN module) and T027-T030 (COS module) - independent modules

3. **Cross-Phase Dependencies**:
   - ❌ Any Phase 3 task before Phase 2 completes (VPN/COS need VPC/subnets)
   - ❌ Any Phase 4 task before Phase 2 and 3 complete (root module needs all modules defined)
   - ✅ Within Phase 2: VPC module and PowerVS module (independent until Transit Gateway)

4. **Validation Checkpoints**:
   - ❌ Starting Phase 2 before T011 validation passes
   - ❌ Starting Phase 3 before T023 validation passes
   - ✅ Running multiple validation checks in Phase 6 (T052, T055-T059)

---

## Implementation Strategy

### Tier-by-Tier Code Generation

1. **Complete Phase 1**: Setup (versions.tf, provider.tf, variables.tf, outputs.tf, directory structure)
2. **VALIDATE**: Run `terraform init` and `terraform validate` (T010-T011)
3. **Complete Phase 2**: Network Tier (all module definitions for VPC, PowerVS, Transit Gateway, security groups)
4. **VALIDATE**: Run `terraform validate` on each module (T023)
5. **Complete Phase 3**: Connectivity & Storage (VPN and COS module definitions)
6. **VALIDATE**: Run `terraform validate` on each module (T031)
7. **Complete Phase 4**: Root Module (main.tf orchestration)
8. **VALIDATE**: Run `terraform validate` and `terraform plan` (T037-T038)
9. **Complete Phase 5**: Documentation (README, guides, examples)
10. **Complete Phase 6**: Polish (formatting, security checks, final validation)

### Multi-Person Workflow

When multiple team members work on the template:

1. **Person A**: Complete Phase 1 (Setup) - foundation for everyone
2. **Person B & C** (after Phase 1): Work in parallel on Phase 2
   - Person B: VPC and Transit Gateway modules (T012-T020)
   - Person C: PowerVS module and security groups (T015-T022)
3. **Person B & C** (after Phase 2): Work in parallel on Phase 3
   - Person B: VPN Gateway module (T024-T026)
   - Person C: COS Storage module (T027-T030)
4. **Person A** (after Phase 2 & 3): Complete Phase 4 (Root module orchestration)
5. **All** (after Phase 4): Parallelize Phase 5 documentation tasks
6. **All** (after Phase 5): Parallelize Phase 6 validation tasks

---

## Notes

- **[P] tasks**: Different files, no dependencies within same tier - can execute in parallel
- **Infrastructure tiers**: Follow dependency hierarchy (Setup → Network → Connectivity/Storage → Orchestration → Documentation → Polish)
- **Validation checkpoints**: Run `terraform validate` at tier boundaries (T011, T023, T031, T037, T051)
- **Module-first approach**: Define all modules before orchestrating in root main.tf
- **Customer-specific values**: All customer-specific configuration via variables (no hardcoded values)
- **Security**: Private connectivity only, no public internet exposure, encrypted VPN tunnel
- **Reusability**: Template designed for repeated deployment across multiple customers
- **POC focus**: Baseline complexity, single zone, cost-optimized for 30-90 day evaluation
- **State management**: COS backend with per-customer state file isolation
- **Region**: All resources in eu-es (Madrid) region

---

## Success Metrics

**Task Completion**: 72 tasks total
- Phase 1 (Setup): 11 tasks
- Phase 2 (Network Tier): 12 tasks
- Phase 3 (Connectivity & Storage): 8 tasks
- Phase 4 (Root Module): 7 tasks
- Phase 5 (Documentation): 11 tasks
- Phase 6 (Polish): 23 tasks

**Parallel Opportunities**: 35+ tasks can run in parallel within their respective phases

**Validation Checkpoints**: 5 critical validation points (T011, T023, T031, T037, T051)

**Environment Order**: Single template deployment per customer (no dev/staging/prod progression)

**Format Validation**: ✅ All 72 tasks follow checklist format (checkbox, ID, optional [P], description with file paths)