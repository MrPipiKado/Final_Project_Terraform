resource "aws_vpc" "this" {
  count = var.create_vpc ? 1 : 0

  cidr_block                       = var.vpc_cidr
  instance_tenancy                 = var.instance_tenancy
  enable_dns_hostnames             = var.enable_dns_hostnames
  enable_dns_support               = var.enable_dns_support

  tags = {
      Name = var.vps_name
  }
}

resource "aws_subnet" "public" {
  count = var.create_public_subnets ? length(var.public_subnet_cidrs) : 0

  vpc_id                          = aws_vpc.this[0].id
  cidr_block                      = var.public_subnet_cidrs[count.index]
  availability_zone               = var.azs[count.index]
  map_public_ip_on_launch         = var.map_public_ip_on_launch

  tags = {
      Name = "Public-${count.index}" 
  }

  depends_on = [
    aws_vpc.this[0],
  ]
}

resource "aws_subnet" "private" {
  count = var.create_private_subnets ? length(var.private_subnet_cidrs) : 0

  vpc_id                          = aws_vpc.this[0].id
  cidr_block                      = var.private_subnet_cidrs[count.index]
  availability_zone               = var.azs[count.index]
  map_public_ip_on_launch         = var.map_public_ip_on_launch

  tags = {
      Name = "Private-${count.index}"
  }

  depends_on = [
    aws_vpc.this[0],
  ]
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.this[0].id

  tags = {
    Name = "GW"
  }

  depends_on = [
    aws_vpc.this,
  ]
}

resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.this[0].id

  route {
    cidr_block = var.internet_cidr_block
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "PublicRoute"
  }

  depends_on = [
    aws_vpc.this[0],
  ]
}

resource "aws_route_table_association" "public_route_associations" {
  count = length(var.public_subnet_cidrs)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_route.id

  depends_on = [
    aws_route_table.public_route,
  ]
}

resource "aws_security_group" "jenkins" {
  name        = "jenkins"
  description = "Allow access to jenkins"
  vpc_id      = aws_vpc.this[0].id

  ingress {
    description = "Jenkins console from anywhere"
    from_port   = var.jenkins_console_port
    to_port     = var.jenkins_console_port
    protocol    = "tcp"
    cidr_blocks = [var.internet_cidr_block]
  }

  ingress {
    description = "Jenkins ssh from anywhere"
    from_port   = var.jenkins_ssh_port
    to_port     = var.jenkins_ssh_port
    protocol    = "tcp"
    cidr_blocks = [var.internet_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.internet_cidr_block]
  }

  tags = {
    Name = "JenkinsSG"
  }

  depends_on = [
    aws_vpc.this[0],
    aws_subnet.public[0],
    aws_route_table.public_route,
  ]
}

resource "aws_instance" "jenkins" {
  count = var.create_jenkins ? 1 : 0

  ami              = var.ami_ubuntu
  instance_type    = var.instance_type_jenkins
  subnet_id        = aws_subnet.public[0].id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.jenkins.id]

  ebs_block_device {
    device_name  = "/dev/sda1" 
    volume_size  = 8
    volume_type  = "gp2"
  }

  depends_on = [
    aws_vpc.this,
    aws_route_table.public_route,
    aws_security_group.jenkins,
  ]

  tags = {
    Name = "Jenkins"
  }
}