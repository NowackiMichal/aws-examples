# Provision of a Cloud Virtual Network

## Description
It is required to deploy a Virtual Network and configure subnets.

**NOTE:** For this task, you can use one of the available options:
1. The NEBo tasks for either AWS or Azure or GCP
2. Steps that should be completed using the cloud provider available for you.

- The virtual Network name should be `vnet-nebo`.
- `vnet-nebo` address should be `10.0.0.0/16`.
- `vnet-nebo` should have two subnets: `snet-public` and `snet-private`.
- `snet-public` address space should be `10.0.0.0/17`.
- `snet-private` address space should be `10.0.128.0/17`.

## Acceptance Criteria
- VM1 deployed to subnet `snet-private` is not accessible from public hosts.
- VM2 deployed to subnet `snet-public` is accessible from public hosts.
- VM2 is able to connect to VM1.

## Examples of Artifacts
Manually or automatically created a virtual network in a cloud that includes at least one of the following:
- Address
- Subnet
- Network interface
