#################
#VPC            #
#################

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

#################
#Subnets        #
#################

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

#################
#Jenkins        #
#################

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

  ami                    = var.ami_ubuntu
  instance_type          = var.instance_type_jenkins
  subnet_id              = aws_subnet.public[0].id
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
    Name = "Jenkins_master"
  }
}

resource "aws_security_group" "jenkins_slave" {
  name        = "jenkins_slave"
  description = "Allow access to jenkins_slave from Jenkins "
  vpc_id      = aws_vpc.this[0].id

  ingress {
    description     = "Jenkins_slave ssh from Jenkins_master"
    from_port       = var.jenkins_ssh_port
    to_port         = var.jenkins_ssh_port
    protocol        = "tcp"
    security_groups = [aws_security_group.jenkins.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.internet_cidr_block]
  }

  tags = {
    Name = "JenkinsSlaveSG"
  }

  depends_on = [
    aws_vpc.this[0],
    aws_subnet.public[0],
    aws_route_table.public_route,
  ]
}

resource "aws_instance" "jenkins_slave" {
  count = var.create_jenkins_slave ? 1 : 0

  ami                         = var.ami_ubuntu
  instance_type               = var.instance_type_jenkins
  subnet_id                   = aws_subnet.public[0].id
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.jenkins.id]
  private_ip                  = var.jenkins_slave_private_ip
  associate_public_ip_address = false

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
    Name = "JenkinsSlave"
  }
}

#################
#Server         #
#################

resource "aws_security_group" "server" {
  name        = "server"
  description = "Allow access to server web page from anywhere and to ssh from jenkins"
  vpc_id      = aws_vpc.this[0].id

  ingress {
    description = "Web page from anywhere"
    from_port   = var.web_page_port
    to_port     = var.web_page_port
    protocol    = "tcp"
    cidr_blocks = [var.internet_cidr_block]
  }

  ingress {
    description = "Jenkins ssh from anywhere"
    from_port   = var.web_server_ssh_port
    to_port     = var.web_server_ssh_port
    protocol    = "tcp"
    security_groups = [aws_security_group.jenkins.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.internet_cidr_block]
  }

  tags = {
    Name = "WebServerSG"
  }

  depends_on = [
    aws_vpc.this[0],
    aws_subnet.public[0],
    aws_route_table.public_route,
  ]
}

resource "aws_instance" "server" {
  count = var.create_server ? 1 : 0

  ami                    = var.ami_ubuntu
  instance_type          = var.instance_type_server
  subnet_id              = aws_subnet.public[0].id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.server.id]
  private_ip             = var.server_private_ip

  ebs_block_device {
    device_name  = "/dev/sda1" 
    volume_size  = 8
    volume_type  = "gp2"
  }

  depends_on = [
    aws_vpc.this,
    aws_route_table.public_route,
    aws_security_group.server,
  ]

  tags = {
    Name = "Server"
  }
}

#################
#RDS DB         #
#################

resource "aws_security_group" "db" {
  name        = "db"
  description = "Allow access to db from production instance"
  vpc_id      = aws_vpc.this[0].id

  ingress {
    description = "DB from production instance"
    from_port   = var.db_port
    to_port     = var.db_port
    protocol    = "tcp"
    security_groups = [aws_security_group.server.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.internet_cidr_block]
  }

  tags = {
    Name = "DB_SG"
  }

  depends_on = [
    aws_vpc.this[0],
    aws_subnet.public[0],
    aws_route_table.public_route,
  ]
}

resource "aws_db_subnet_group" "db" {
  name       = "db"
  subnet_ids = [aws_subnet.private[0].id, aws_subnet.private[1].id]

  tags = {
    Name = "My DB subnet group"
  }
}

resource "aws_db_instance" "db" {
  count = var.create_db ? 1 : 0

  identifier = var.identifier

  engine            = var.engine
  engine_version    = var.engine_version
  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage
  storage_type      = var.storage_type
  storage_encrypted = var.storage_encrypted

  name                                = var.db_name
  username                            = var.db_user
  password                            = var.db_password
  port                                = var.db_port
  iam_database_authentication_enabled = var.iam_database_authentication_enabled

  vpc_security_group_ids = [aws_security_group.db.id]
  db_subnet_group_name   = aws_db_subnet_group.db.id

  multi_az            = var.multi_az
  publicly_accessible = var.publicly_accessible

  allow_major_version_upgrade = var.allow_major_version_upgrade
  auto_minor_version_upgrade  = var.auto_minor_version_upgrade
  apply_immediately           = var.apply_immediately
  skip_final_snapshot         = var.skip_final_snapshot
  copy_tags_to_snapshot       = var.copy_tags_to_snapshot

  performance_insights_enabled = var.performance_insights_enabled

  deletion_protection      = var.deletion_protection

  tags = {
    Name = "FinalProjectDB"
  }

}