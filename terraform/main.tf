provider "aws" {
  region = var.aws_region
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_subnet" "default" {
  for_each = toset(data.aws_subnets.default.ids)
  id       = each.value
}

# This VPC's default route table has an internet gateway route, but individual
# subnets have their own explicit associations with other route tables (some
# private-only, one pointing at a since-deleted NAT gateway) — so a subnet
# being part of the "default" VPC does not mean it can reach the internet.
# aws_route_table resolves whichever table actually applies to each subnet
# (explicit association, or the main table if none), so this reflects real
# routing rather than assuming.
data "aws_route_table" "default" {
  for_each  = toset(data.aws_subnets.default.ids)
  subnet_id = each.value
}

locals {
  # us-east-1e doesn't support every instance type (t3.micro included), so
  # exclude it rather than let AWS pick an unsupported AZ at random. Also
  # require an active route to an internet gateway.
  eligible_subnet_ids = sort([
    for s in data.aws_subnet.default : s.id
    if s.availability_zone != "us-east-1e" && anytrue([
      for r in data.aws_route_table.default[s.id].routes :
      r.cidr_block == "0.0.0.0/0" && length(regexall("^igw-", r.gateway_id)) > 0
    ])
  ])
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "tls_private_key" "generated" {
  count     = var.key_pair_name == null ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated" {
  count      = var.key_pair_name == null ? 1 : 0
  key_name   = "${var.project_name}-key"
  public_key = tls_private_key.generated[0].public_key_openssh
}

resource "local_sensitive_file" "private_key" {
  count           = var.key_pair_name == null ? 1 : 0
  content         = tls_private_key.generated[0].private_key_pem
  filename        = "${path.module}/${var.project_name}-key.pem"
  file_permission = "0600"
}

locals {
  key_name = coalesce(var.key_pair_name, try(aws_key_pair.generated[0].key_name, null))
}

# Shared across every environment — created once (in the default workspace,
# where var.security_group_id is left null) and referenced by ID everywhere else.
# No SSH ingress: deploys and manual access both go through SSM instead.
resource "aws_security_group" "app" {
  count       = var.security_group_id == null ? 1 : 0
  name_prefix = "${var.project_name}-sg-"
  description = "Allow app traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "App"
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

locals {
  security_group_id = coalesce(var.security_group_id, try(aws_security_group.app[0].id, null))
}

# Shared IAM role/instance profile so instances can be managed via SSM (used
# for deploys from CI and for manual `aws ssm start-session` access) instead
# of SSH. Created once, in the default workspace, and referenced by name
# elsewhere — same pattern as the security group above.
data "aws_iam_policy_document" "ec2_assume_role" {
  count = var.instance_profile_name == null ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ssm" {
  count              = var.instance_profile_name == null ? 1 : 0
  name               = "${var.project_name}-ec2-ssm-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role[0].json
}

resource "aws_iam_role_policy_attachment" "ssm" {
  count      = var.instance_profile_name == null ? 1 : 0
  role       = aws_iam_role.ssm[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm" {
  count = var.instance_profile_name == null ? 1 : 0
  name  = "${var.project_name}-ec2-ssm-profile"
  role  = aws_iam_role.ssm[0].name
}

locals {
  instance_profile_name = coalesce(var.instance_profile_name, try(aws_iam_instance_profile.ssm[0].name, null))
}

# One instance per workspace. The default workspace only manages the shared SG,
# key pair, and SSM role above, so it's skipped here (count = 0) — dev/prod
# workspaces (selected via `terraform workspace select` + their own tfvars
# file) get one.
resource "aws_instance" "app" {
  count = terraform.workspace == "default" ? 0 : 1

  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = local.eligible_subnet_ids[0]
  vpc_security_group_ids      = [local.security_group_id]
  key_name                    = local.key_name
  iam_instance_profile        = local.instance_profile_name
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/user_data.sh.tftpl", {
    image_ref = "${var.image_name}:${var.image_tag}"
    app_port  = var.app_port
  })

  tags = {
    Name = "${var.project_name}-${terraform.workspace}"
  }
}
