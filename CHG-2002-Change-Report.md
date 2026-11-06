
# CHG-2002 — Terraform Infrastructure Change Report

## Environment
- Company: Northstar Solutions (simulated)
- AWS Region: us-east-2
- Project: AWS-002
- Tool: Terraform

## Change Request
Update the EC2 instance Name tag from
`northstar-terraform-web-server` to
`northstar-terraform-web-prod-test`.

The EC2 instance must not be replaced.

## Issue Encountered
During the initial Terraform plan review, the proposed
change targeted `aws_vpc.northstar` instead of
`aws_instance.web`.

The plan showed an unintended VPC tag modification.

## Investigation
Reviewed the Terraform plan and identified the
incorrect resource being modified.

## Resolution
Restored the original VPC Name tag and updated the
Name tag in the EC2 resource configuration.

## Validation
The corrected Terraform plan showed:

Plan: 0 to add, 1 to change, 0 to destroy.

Terraform applied the change successfully:

Apply complete! Resources: 0 added, 1 changed,
0 destroyed.

The EC2 instance retained its original instance ID.

## Lessons Learned
- Always review Terraform plans before applying changes.
- Verify which resource Terraform intends to modify.
- Understand the difference between in-place updates
  and resource replacement.
- Use infrastructure as code for controlled changes.
