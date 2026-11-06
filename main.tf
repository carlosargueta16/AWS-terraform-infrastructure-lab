
# =========================================================
# AWS-002 — Northstar Terraform Infrastructure Automation
# Region: Ohio (us-east-2)
# =========================================================

# 1. TERRAFORM AND AWS PROVIDER

terraform {
  required_version = ">= 1.17.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region  = "us-east-2"
  profile = "fresh-canvas"
}

# 2. VPC

resource "aws_vpc" "northstar" {
  cidr_block           = "10.30.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
  Name    = "northstar-terraform-vpc"
  Project = "AWS-002"
}
}

# 3. PUBLIC SUBNET

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.northstar.id
  cidr_block              = "10.30.1.0/24"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = true

  tags = {
    Name    = "northstar-public-subnet"
    Project = "AWS-002"
  }
}

# 4. PRIVATE SUBNET

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.northstar.id
  cidr_block        = "10.30.2.0/24"
  availability_zone = "us-east-2a"

  tags = {
    Name    = "northstar-private-subnet"
    Project = "AWS-002"
  }
}

# 5. INTERNET GATEWAY

resource "aws_internet_gateway" "northstar" {
  vpc_id = aws_vpc.northstar.id

  tags = {
    Name    = "northstar-terraform-igw"
    Project = "AWS-002"
  }
}

# 6. PUBLIC ROUTE TABLE

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.northstar.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.northstar.id
  }

  tags = {
    Name    = "northstar-public-rt"
    Project = "AWS-002"
  }
}

# 7. PUBLIC ROUTE TABLE ASSOCIATION

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# 8. PRIVATE ROUTE TABLE

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.northstar.id

  tags = {
    Name    = "northstar-private-rt"
    Project = "AWS-002"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# 9. EC2 SECURITY GROUP

resource "aws_security_group" "web" {
  name        = "northstar-terraform-web-sg"
  description = "Security group for Northstar web server"
  vpc_id      = aws_vpc.northstar.id

  tags = {
    Name    = "northstar-terraform-web-sg"
    Project = "AWS-002"
  }
}

# Allow inbound HTTP traffic

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.web.id

  description = "Allow public HTTP traffic"
  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
}

# Allow outbound IPv4 traffic

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.web.id

  description = "Allow outbound IPv4 traffic"
  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}

# 10. IAM ROLE FOR SESSION MANAGER

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ssm" {
  name               = "northstar-terraform-ssm-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = {
    Project = "AWS-002"
  }
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm" {
  name = "northstar-terraform-ssm-profile"
  role = aws_iam_role.ssm.name
}

# 11. AMAZON LINUX 2023 AMI

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# 12. EC2 WEB SERVER

resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]

  iam_instance_profile = aws_iam_instance_profile.ssm.name

  associate_public_ip_address = true

  credit_specification {
    cpu_credits = "standard"
  }

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  user_data = <<-EOF
    #!/bin/bash
    dnf install -y httpd
    systemctl enable --now httpd

    cat > /var/www/html/index.html <<'HTML'
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <title>Northstar Solutions - AWS-002</title>
    </head>
    <body>
      <h1>Northstar Solutions</h1>
      <h2>Terraform Infrastructure Automation</h2>
      <p>Environment: Development</p>
      <p>Server: Amazon Linux 2023</p>
      <p>Deployment Method: Terraform</p>
      <p>Project: AWS-002</p>
      <p>Status: Operational</p>
    </body>
    </html>
    HTML
  EOF

  tags = {
  Name    = "northstar-terraform-web-prod-test"
  Project = "AWS-002"
}

  depends_on = [
    aws_route_table_association.public,
    aws_iam_role_policy_attachment.ssm
  ]
}

# 13. TERRAFORM OUTPUTS

output "vpc_id" {
  description = "Northstar VPC ID"
  value       = aws_vpc.northstar.id
}

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = aws_subnet.public.id
}

output "ec2_instance_id" {
  description = "Northstar EC2 instance ID"
  value       = aws_instance.web.id
}

output "ec2_public_ip" {
  description = "Public IPv4 address of the web server"
  value       = aws_instance.web.public_ip
}

output "website_url" {
  description = "Northstar demonstration website URL"
  value       = "http://${aws_instance.web.public_ip}"
}
