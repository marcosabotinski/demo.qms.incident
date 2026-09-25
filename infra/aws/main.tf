data "http" "operator_ip" {
  count = var.allowed_cidr == "" ? 1 : 0
  url   = "https://checkip.amazonaws.com/"
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

data "cloudflare_ip_ranges" "cloudflare" {}

locals {
  allowed_cidr = var.allowed_cidr != "" ? var.allowed_cidr : "${trimspace(data.http.operator_ip[0].response_body)}/32"
  # Zone IP Access Rules: /32 must be target "ip" without the suffix; anything
  # else is ip_range (/16 and /24 are what Cloudflare actually accepts).
  allow_access_rules = {
    for c in var.allow_cidrs :
    c => {
      target = endswith(c, "/32") ? "ip" : "ip_range"
      value  = endswith(c, "/32") ? trimsuffix(c, "/32") : c
    }
  }
}

resource "aws_vpc" "demo" {
  cidr_block           = "10.42.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.name}-vpc"
  }
}

resource "aws_internet_gateway" "demo" {
  vpc_id = aws_vpc.demo.id

  tags = {
    Name = "${var.name}-igw"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.demo.id
  cidr_block              = "10.42.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${var.name}-public"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.demo.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo.id
  }

  tags = {
    Name = "${var.name}-public"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "nsg" {
  name_prefix = "${var.name}-nsg-"
  description = "SSH from operator; HTTP from Cloudflare ranges only"
  vpc_id      = aws_vpc.demo.id

  ingress {
    description = "SSH from operator"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.allowed_cidr]
  }

  ingress {
    description = "HTTP from Cloudflare proxy ranges"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = data.cloudflare_ip_ranges.cloudflare.ipv4_cidrs
  }

  egress {
    description = "Allow outbound for package installs and image pulls"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-nsg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_key_pair" "demo" {
  key_name   = "${var.name}-operator"
  public_key = var.ssh_public_key
}

resource "aws_instance" "demo" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.nsg.id]
  key_name                    = aws_key_pair.demo.key_name
  associate_public_ip_address = true
  user_data                   = file("${path.module}/user-data.sh")
  user_data_replace_on_change = false

  root_block_device {
    volume_size           = var.volume_size_gb
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = {
    Name = var.name
  }
}

resource "aws_eip" "demo" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.demo]

  tags = {
    Name = var.name
  }
}

resource "aws_eip_association" "demo" {
  instance_id   = aws_instance.demo.id
  allocation_id = aws_eip.demo.id
}

resource "cloudflare_dns_record" "demo" {
  zone_id = var.cloudflare_zone_id
  name    = var.hostname
  type    = "A"
  content = aws_eip.demo.public_ip
  proxied = true
  ttl     = 1
}

resource "cloudflare_zone_setting" "ssl" {
  zone_id    = var.cloudflare_zone_id
  setting_id = "ssl"
  value      = "flexible"
}

# Zone-scoped IP Access Rules ("this website" in the dashboard). Free-plan
# tool. They apply to every hostname in the zone; whitelist skips security
# for those IPs but does not deny everyone else.
# scripts/allow-my-ip.sh adds bot addresses through the Cloudflare API.
# Those rules are outside this for_each. Do not replace it with a resource
# that reconciles every zone access rule; apply would delete the bot CIDRs.
resource "cloudflare_access_rule" "visitor_allow" {
  for_each = local.allow_access_rules

  zone_id = var.cloudflare_zone_id
  mode    = "whitelist"
  notes   = "${var.name} visitor allow ${each.key}"
  configuration = {
    target = each.value.target
    value  = each.value.value
  }
}
