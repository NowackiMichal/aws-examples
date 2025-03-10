# Ensure distributing client requests across multiple application servers

This project sets up Load balancer and an 3 x EC2 instances for testing, all provisioned via Terraform.

## Task

- Create Load Balancer.
- Select a load balancer type
- Define your Load Balancer
- Assign security groups to your Load Balancer in a VPC
- Configure Health Checks for your VM insatnces
- Register VM instances with your load balancer
- Tag yout load balancer
- Verify your load balancer