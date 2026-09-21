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

locals {
  allowed_cidr = var.allowed_cidr != "" ? var.allowed_cidr : "${trimspace(data.http.operator_ip[0].response_body)}/32"
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

# AWS equivalent of an NSG: only the operator IP can hit SSH or the HTTP frontend.
resource "aws_security_group" "nsg" {
  name        = "${var.name}-nsg"
  description = "Restrict SSH and HTTP to the operator public IP"
  vpc_id      = aws_vpc.demo.id

  ingress {
    description = "SSH from operator"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.allowed_cidr]
  }

  ingress {
    description = "HTTP frontend from operator"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [local.allowed_cidr]
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
