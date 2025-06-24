resource "aws_instance" "license_server" {
  count                   = var.license_server ? 1 : 0
  ami                     = data.aws_ami.amazon_linux_kernel5.id
  instance_type           = var.license_server_type
  iam_instance_profile    = aws_iam_instance_profile.license_server_profile[0].name
  subnet_id               = local.private_subnet_ids[0]
  disable_api_termination = true
  vpc_security_group_ids  = [aws_security_group.allow_codemeter[0].id]

  metadata_options {
    # [EC2.8] EC2 instances should use IMDSv2
    # https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards-fsbp-controls.html#fsbp-ec2-8
    http_endpoint = "enabled"
    http_tokens   = "required" # Require session token for Instance Metadata Service Version 2 (IMDSv2)
  }
  user_data = <<-EOF
#!/bin/bash
yum update -y
wget -O CodeMeter.rpm "${var.codemeter}"
yum -y localinstall CodeMeter.rpm
systemctl stop codemeter
sed -i -e '/IsNetworkServer=/ s/=.*/=1/' /etc/wibu/CodeMeter/Server.ini
systemctl start codemeter
systemctl enable codemeter
EOF

  lifecycle {
    ignore_changes = [
      ami,
    ]
  }
  tags = merge(var.tags, { "Name" = local.license_server, "Patch Group" = local.patchgroupid })
}

data "aws_ami" "amazon_linux_kernel5" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-202*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}
resource "aws_iam_role" "license_server_role" {
  count       = var.license_server ? 1 : 0
  description = "IAM role used for the license server instance profile."
  name        = local.license_server_role
  tags        = var.tags
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "license_server_policy" {
  count       = var.license_server ? 1 : 0
  name        = local.license_server_policy
  description = "Allows access to S3 bucket and Secure Session Manager connections."
  policy      = templatefile("${path.module}/templates/license_server_policy.json", { bucket = local.license_server_bucket_name })
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "s3_policy_attachment" {
  count      = var.license_server ? 1 : 0
  role       = aws_iam_role.license_server_role[0].name
  policy_arn = aws_iam_policy.license_server_policy[0].arn
}

resource "aws_iam_role_policy_attachment" "license_server_ssm" {
  count      = var.license_server ? 1 : 0
  role       = aws_iam_role.license_server_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_s3_bucket" "license_server_bucket" {
  count  = var.license_server ? 1 : 0
  bucket = local.license_server_bucket_name
  tags   = var.tags
}

# [S3.5] S3 buckets should require requests to use Secure Socket Layer
resource "aws_s3_bucket_policy" "ssl_only_policy" {
  count  = var.license_server ? 1 : 0
  bucket = aws_s3_bucket.license_server_bucket[0].id
  policy = templatefile("${path.module}/templates/ssl_only_policy.json", { bucket = aws_s3_bucket.license_server_bucket[0].id })
}


resource "aws_iam_instance_profile" "license_server_profile" {
  count = var.license_server ? 1 : 0
  name  = local.license_server_instance_profile
  role  = aws_iam_role.license_server_role[0].name
}


resource "aws_security_group" "allow_codemeter" {
  count       = var.license_server ? 1 : 0
  name        = "allow_codemeter"
  description = "Allow communication with CodeMeter license server"
  vpc_id      = local.vpc_id
  tags        = var.tags

  ingress {

    from_port   = 22350
    to_port     = 22350
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidr]
    description = "Inbound TCP on port 22350 from kubernetes nodes security group"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "allow all outbound traffic"

  }
}

