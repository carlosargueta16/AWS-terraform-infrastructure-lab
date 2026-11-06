# AWS-002 — Terraform Infrastructure Automation

## Project Overview

This project demonstrates how to provision, modify, validate, and destroy AWS infrastructure using **Terraform Infrastructure as Code (IaC)**.

The project simulates an infrastructure automation assignment for a fictional company, **Northstar Solutions**.

Unlike a manual AWS Console deployment, this environment is defined in reusable Terraform configuration files.

## Technologies Used

- Terraform (HCL)
- AWS CLI
- Amazon VPC
- Amazon EC2 (Amazon Linux 2023)
- AWS IAM
- AWS Systems Manager Session Manager
- AWS Security Groups
- Apache HTTP Server
- GitHub and Visual Studio Code

## Infrastructure Architecture

The Terraform configuration provisions:

- VPC: `10.30.0.0/16`
- Public subnet: `10.30.1.0/24`
- Private subnet: `10.30.2.0/24`
- Internet Gateway and public route table
- Security group permitting inbound HTTP on TCP port 80
- Amazon Linux EC2 instance with encrypted EBS storage
- IAM role and instance profile for Session Manager

The EC2 instance uses a startup script to automatically install Apache and deploy the Northstar demonstration website.

## Terraform Deployment Workflow

The infrastructure was managed using the following commands:

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

Terraform successfully provisioned **15 AWS resources**.

The deployed website was verified through its public HTTP endpoint.

## Change Management — CHG-2002

A simulated change request required updating the EC2 instance's Name tag without replacing the instance.

During the first Terraform plan review, an unintended change to the VPC Name tag was identified.

The configuration was corrected, and the new plan showed:

`Plan: 0 to add, 1 to change, 0 to destroy.`

The intended EC2 tag change was applied successfully without replacing the instance.

See [CHG-2002 Change Report](CHG-2002-Change-Report.md) for the full troubleshooting and change-management documentation.

## Infrastructure Cleanup

After deployment and validation, the environment was removed using:

```bash
terraform plan -destroy
terraform destroy
```

Terraform confirmed:

`Destroy complete! Resources: 15 destroyed.`

All Terraform-managed resources were removed. The infrastructure can be recreated using the configuration files.

## Skills Demonstrated

- Infrastructure as Code
- AWS infrastructure provisioning
- Terraform resource dependencies
- Terraform plan review and change management
- AWS networking and security configuration
- Automated Linux web server deployment
- Infrastructure troubleshooting
- Resource lifecycle management
- GitHub documentation

## Security Notes

This is a temporary development environment, not a production deployment.

- Administrative SSH access is not exposed.
- EC2 administration uses AWS Systems Manager Session Manager.
- Terraform state files and credentials are excluded from the public repository.
- HTTP is used for the demonstration website without TLS.
- Temporary infrastructure was destroyed after testing.
