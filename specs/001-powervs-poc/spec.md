# Infrastructure Specification: PowerVS POC Template

**Spec ID**: `001-powervs-poc`
**Created**: 2026-02-05
**Status**: Draft
**Input**: User description: "I want to create a template for PowerVS POC. I need to repeat the creating on this infraestructure eveytime i have a new customer. This should create a PowerVS workspace connected to a VPC using Transit Gateway, having a VPN site to site ready to be configured with the customer on-prem and COS bucket connected via VPE to the PowerVS. Enable user to specify the vpc subnet and powervs subnet."

## Executive Summary *(mandatory)*

This specification defines a reusable infrastructure template for PowerVS Proof of Concept (POC) deployments. The template enables rapid provisioning of a complete hybrid cloud environment connecting Power Systems virtual servers to cloud infrastructure with secure connectivity to customer on-premises environments. This template will be deployed repeatedly for each new customer POC engagement.

## Clarifications

### Session 2026-02-05

- Q: IBM Cloud Region Selection → A: madrid (eu-es)
- Q: Default VPC Subnet CIDR Range → A: 10.240.0.0/24 (default, user-configurable)
- Q: Default PowerVS Subnet CIDR Range → A: 10.241.0.0/24 (default, user-configurable)
- Q: VPN Gateway Mode → A: Policy-based VPN
- Q: COS Bucket Naming Convention → A: {customer-id}-powervs-poc-{timestamp} (default, user-configurable)

## Problem Statement *(mandatory)*

### Current State

Currently, each PowerVS POC deployment requires manual configuration of multiple interconnected components including workspace creation, network connectivity setup, VPN configuration, and storage integration. This manual process is time-consuming, error-prone, and inconsistent across customer engagements.

### Desired State

A fully automated, repeatable infrastructure template that provisions a complete PowerVS POC environment in a consistent manner. The template should allow customization of network addressing while maintaining standardized architecture patterns. Deployment should be achievable through Infrastructure as Code with minimal manual intervention.

### Business Impact

**Benefits:**
- 80% reduction in POC setup time (from days to hours)
- Consistent architecture across all customer POCs
- Reduced errors from manual configuration
- Faster time-to-value for customer evaluations
- Simplified handoff between teams

**Risks if not implemented:**
- Continued inefficiency in POC delivery
- Inconsistent customer experiences
- Higher risk of configuration errors impacting POC success
- Difficulty scaling POC program to multiple concurrent customers

## Infrastructure Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Infrastructure MUST provide a Power Systems workspace environment for running AIX, IBM i, and Linux workloads
- **FR-002**: Infrastructure MUST provide a virtual private cloud network with configurable subnet addressing (default: 10.240.0.0/24)
- **FR-003**: Infrastructure MUST establish network connectivity between the Power Systems workspace and virtual private cloud using a transit gateway
- **FR-004**: Infrastructure MUST provide policy-based site-to-site VPN capability ready for customer on-premises network configuration
- **FR-005**: Infrastructure MUST provide object storage bucket (naming: {customer-id}-powervs-poc-{timestamp}, user-configurable) accessible from the Power Systems workspace through private network endpoints
- **FR-006**: Infrastructure MUST allow users to specify custom subnet ranges for both virtual private cloud (default: 10.240.0.0/24) and Power Systems networks (default: 10.241.0.0/24)
- **FR-007**: Infrastructure MUST implement network isolation between customer environments
- **FR-008**: Infrastructure MUST provide secure private connectivity to object storage without internet exposure
- **FR-009**: Infrastructure MUST support configuration as code for repeatable deployments
- **FR-010**: Infrastructure MUST include network routing between all components (workspace, VPC, storage)

### Non-Functional Requirements

#### Performance

- Network latency between Power Systems workspace and virtual private cloud < 5ms
- Transit gateway throughput supports minimum 10 Gbps
- VPN tunnel supports minimum 1 Gbps throughput
- Object storage access latency < 50ms from Power Systems workspace

#### Availability

- 99.9% uptime SLO for network connectivity (8.76 hours downtime/year)
- Transit gateway configured with redundancy
- VPN gateway configured with high availability
- Object storage with 99.99% availability SLA

#### Security

- All network traffic between components uses private connectivity (no public internet routing)
- VPN connections use policy-based IPsec with AES-256 encryption
- Object storage access restricted to authorized networks only
- Network segmentation between Power Systems workspace and virtual private cloud
- Role-based access control for infrastructure management
- Encryption in transit for all data movement

#### Scalability

- Template targets eu-es (Madrid) region for deployment
- Network addressing scheme accommodates future expansion
- Transit gateway supports adding additional network connections
- Object storage scales automatically with usage

## Service Level Objectives (SLOs) *(mandatory)*

- **Availability**: 99.9% uptime for network connectivity measured over 30-day rolling window
- **Provisioning Time**: Complete infrastructure deployment within 2 hours from template execution
- **Network Performance**: Transit gateway latency < 5ms measured between workspace and VPC endpoints
- **VPN Readiness**: VPN gateway operational and ready for customer configuration within deployment timeframe
- **Storage Access**: Object storage accessible from workspace with < 50ms latency for 95th percentile requests
- **Template Reusability**: Successfully deploy template for 10 consecutive customers without template modifications

## Cost Constraints *(mandatory)*

### Budget

- Initial POC infrastructure: $500-1000 per month per customer
- Assumes 30-90 day POC duration
- Costs include: workspace compute, network connectivity, VPN gateway, object storage (minimal usage)
- Does not include Power Systems instance compute costs (customer-specific)

### Cost Optimization

- Use smallest viable network gateway sizes for POC workloads
- Configure object storage with lifecycle policies for automatic cleanup
- Implement resource tagging for cost tracking per customer
- Document teardown procedures for POC completion
- Use reserved capacity where available for predictable components

## Success Criteria *(mandatory)*

### Code Validation

- [ ] Infrastructure code passes validation checks without errors
- [ ] All network CIDR ranges are configurable via input parameters
- [ ] Code includes validation for subnet range conflicts
- [ ] Resource naming follows consistent convention with customer identifier (COS bucket: {customer-id}-powervs-poc-{timestamp} or custom)
- [ ] All required resource dependencies are properly defined

### Security Validation

- [ ] No public internet gateways attached to Power Systems workspace networks
- [ ] Object storage access restricted to private endpoints only
- [ ] Policy-based VPN gateway configured with strong encryption (AES-256, SHA-256)
- [ ] Network security groups/ACLs limit traffic to required ports only
- [ ] All data in transit encrypted

### Performance Validation

- [ ] Network connectivity test between workspace and VPC succeeds with < 5ms latency
- [ ] Transit gateway routing tables correctly configured for all networks
- [ ] Object storage accessible from workspace via private endpoint
- [ ] VPN gateway operational and ready for customer configuration

### Operational Validation

- [ ] Template successfully deploys complete infrastructure without manual intervention
- [ ] All components visible in infrastructure management console
- [ ] Network topology diagram matches intended architecture
- [ ] Documentation includes customer-specific configuration values (VPN settings, subnet ranges)
- [ ] Teardown procedure successfully removes all resources

## Assumptions *(include if making assumptions)*

- Assume deployment in IBM Cloud eu-es (Madrid) region
- Assume customers will provide their own VPN endpoint configuration details (public IP, pre-shared key, routing)
- Assume POC workloads are development/test level (not production-grade requirements)
- Assume single availability zone deployment is sufficient for POC purposes
- Assume object storage usage will be minimal during POC (< 100 GB)
- Assume Power Systems workspace will run 1-3 virtual server instances
- Assume 30-90 day POC duration before infrastructure teardown
- Assume customers have existing on-premises infrastructure with VPN capability

## Out of Scope *(include if explicitly excluding items)*

- Power Systems virtual server instance provisioning (handled separately by customer)
- Operating system installation and configuration on Power Systems instances
- Application deployment and configuration
- Customer-specific VPN endpoint configuration (customer responsibility)
- Monitoring and alerting setup (basic infrastructure monitoring only)
- Backup and disaster recovery configuration
- Production-grade high availability and redundancy
- Multi-region deployment
- Integration with customer identity management systems

## Dependencies *(include if external dependencies exist)*

- Customer must provide VPN endpoint details (public IP address, pre-shared key, subnet ranges)
- Customer must have compatible VPN gateway equipment supporting IPsec
- Cloud platform account with appropriate permissions and quotas
- Network CIDR ranges must not conflict with customer on-premises networks
- DNS resolution for private endpoints (if required)

## Notes

- Template designed for repeatability across multiple customer POC engagements
- Network addressing must be customizable to avoid conflicts with customer networks
- VPN configuration will require customer-specific information not available at template creation time
- Consider creating documentation template for customer handoff including VPN configuration steps
- Template should include resource tagging strategy for cost tracking and lifecycle management
- Consider adding optional monitoring/logging components in future iterations

---

**Specification Quality Checklist**:
- [ ] No implementation details (cloud providers, specific tools)
- [ ] All requirements are testable and unambiguous
- [ ] Success criteria are measurable
- [ ] Cost constraints clearly defined
- [ ] Compliance requirements specified (if applicable)