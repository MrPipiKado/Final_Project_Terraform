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
#Kubernetes     #
#################

resource "aws_security_group" "k8s_master" {
  name        = "k8s_master"
  description = "Allow access to k8s_master and it serves as a bastion host"
  vpc_id      = aws_vpc.this[0].id

  ingress {
    description = "To Kubernetes master from public subnet1"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [var.public_subnet_cidrs[0]]
  }

  ingress {
    description = "Bastion ssh from anywhere"
    from_port   = var.bastion_ssh_port
    to_port     = var.bastion_ssh_port
    protocol    = "tcp"
    cidr_blocks = [var.internet_cidr_block]
  }

  ingress {
    description = "cluster external port from anywhere"
    from_port   = var.cluster_port
    to_port     = var.cluster_port
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
    Name = "K8s_master_bastion_SG"
  }

  depends_on = [
    aws_vpc.this[0],
    aws_subnet.public[0],
    aws_route_table.public_route,
  ]
}

resource "aws_instance" "k8s_master" {
  count = var.create_k8s_master ? 1 : 0

  ami                    = var.ami_ubuntu
  instance_type          = var.instance_type_k8s_master
  subnet_id              = aws_subnet.public[0].id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.k8s_master.id]
  private_ip             = var.k8s_master_private_ip

  root_block_device {
    delete_on_termination = false
  }

  depends_on = [
    aws_vpc.this,
    aws_route_table.public_route,
    aws_security_group.k8s_master,
  ]

  tags = {
    Name = "k8s_master_bastion"
  }
}

#################
#Jenkins master #
#################

resource "aws_security_group" "jenkins_master" {
  name        = "jenkins_master"
  description = "Allow access to jenkins web page from anywhere and to ssh from k8s_master"
  vpc_id      = aws_vpc.this[0].id

  ingress {
    description = "Jenkins console from anywhere"
    from_port   = var.web_page_port
    to_port     = var.web_page_port
    protocol    = "tcp"
    cidr_blocks = [var.internet_cidr_block]
  }

  ingress {
    description = "Jenkins ssh from anywhere"
    from_port   = var.jenkins_ssh_port
    to_port     = var.jenkins_ssh_port
    protocol    = "tcp"
    security_groups = [aws_security_group.k8s_master.id]
  }

  ingress {
    description = "Port to exec into pods from k8s_master"
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    security_groups = [aws_security_group.k8s_master.id]
  }

  ingress {
    description = "nodeexternal service port from anywhere"
    from_port   = var.deployment_port
    to_port     = var.deployment_port
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
    Name = "JenkinsMasterSG"
  }

  depends_on = [
    aws_vpc.this[0],
    aws_subnet.public[0],
    aws_route_table.public_route,
  ]
}

resource "aws_instance" "jenkins_master" {
  count = var.create_jenkins ? 1 : 0

  ami                    = var.ami_ubuntu
  instance_type          = var.instance_type_jenkins
  subnet_id              = aws_subnet.public[0].id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.jenkins_master.id, aws_security_group.elb_in.id]
  private_ip             = var.jenkins_master_private_ip

  root_block_device {
    delete_on_termination = false
  }
  
  depends_on = [
    aws_vpc.this,
    aws_route_table.public_route,
    aws_security_group.jenkins_master,
  ]

  tags = {
    Name = "JenkinsMaster"
  }
}

#################
#Jenkins slave  #
#################

resource "aws_security_group" "jenkins_slave" {
  name        = "jenkins_slave"
  description = "Allow access to jenkins_slave from Jenkins "
  vpc_id      = aws_vpc.this[0].id

  ingress {
    description     = "Jenkins_slave ssh from k8s_master"
    from_port       = var.jenkins_slave_ssh_port
    to_port         = var.jenkins_slave_ssh_port
    protocol        = "tcp"
    security_groups = [aws_security_group.k8s_master.id]
  }

  ingress {
    description     = "Jenkins_slave ssh from Jenkins_master"
    from_port       = var.jenkins_slave_ssh_port
    to_port         = var.jenkins_slave_ssh_port
    protocol        = "tcp"
    security_groups = [aws_security_group.jenkins_master.id]
  }

  ingress {
    description     = "Jenkins_slave kubelet from Jenkins_master"
    from_port       = 6443
    to_port         = 6443
    protocol        = "tcp"
    security_groups = [aws_security_group.k8s_master.id]
  }

  ingress {
    description = "exec into pods from k8s_master"
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    security_groups = [aws_security_group.k8s_master.id]
  }

  ingress {
    description = "Deployment from anywhere"
    from_port   = var.deployment_port
    to_port     = var.deployment_port
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
  instance_type               = var.instance_type_jenkins_slave
  subnet_id                   = aws_subnet.public[0].id
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.jenkins_slave.id, aws_security_group.elb_in.id]
  private_ip                  = var.jenkins_slave_private_ip

  root_block_device {
    delete_on_termination = false
  }

  depends_on = [
    aws_vpc.this,
    aws_route_table.public_route,
    aws_security_group.jenkins_slave,
  ]

  tags = {
    Name = "JenkinsSlave"
  }
}

#################
#RDS DB         #
#################

resource "aws_security_group" "db" {
  name        = "db"
  description = "Allow access to db from production instances"
  vpc_id      = aws_vpc.this[0].id

  ingress {
    description = "DB from production instances"
    from_port   = var.db_port
    to_port     = var.db_port
    protocol    = "tcp"
    security_groups = [aws_security_group.jenkins_master.id, aws_security_group.jenkins_slave.id, aws_security_group.k8s_master.id]
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

#################
#Load balancer  #
#################

resource "aws_security_group" "elb" {
  name        = "elb"
  description = "Allow access to alb from internet"
  vpc_id      = aws_vpc.this[0].id

  ingress {
    description = "DB from production instances"
    from_port   = 80
    to_port     = 80
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
    Name = "ALB_SG"
  }

  depends_on = [
    aws_vpc.this[0],
    aws_subnet.public[0],
    aws_route_table.public_route,
  ]
}

resource "aws_security_group" "elb_in" {
  name        = "elb_in"
  description = "Allow access to instance from elb"
  vpc_id      = aws_vpc.this[0].id

  ingress {
    description = "alb to instances"
    from_port   = var.deployment_port
    to_port     = var.deployment_port
    protocol    = "tcp"
    security_groups = [aws_security_group.elb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.internet_cidr_block]
  }

  tags = {
    Name = "ALB_IN_SG"
  }

  depends_on = [
    aws_vpc.this[0],
    aws_subnet.public[0],
    aws_route_table.public_route,
  ]
}

resource "aws_lb_target_group" "final_lb" {
  name     = "final-lb"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.this[0].id
}

resource "aws_lb_target_group_attachment" "jenkins_master" {
  target_group_arn = aws_lb_target_group.final_lb.arn
  target_id        = aws_instance.jenkins_master[0].id
  port             = var.deployment_port
  depends_on = [
    aws_lb_target_group.final_lb,
  ]
}

resource "aws_lb_target_group_attachment" "jenkins_slave" {
  target_group_arn = aws_lb_target_group.final_lb.arn
  target_id        = aws_instance.jenkins_slave[0].id
  port             = var.deployment_port
}

resource "aws_lb_listener" "http"{
  load_balancer_arn = aws_lb.final_lb.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code = 404
    }
  }
}

resource "aws_lb_listener_rule" "listener"{
  listener_arn = aws_lb_listener.http.arn
  priority = 100

  condition {
    path_pattern {
      values = ["/"]
    }
  }

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.final_lb.arn
  }

}

resource "aws_lb" "final_lb" {
  name               = "final-elb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.elb.id]
  subnets            = [aws_subnet.public[0].id, aws_subnet.public[1].id]
  enable_http2       = true
  enable_deletion_protection = false

  tags = {
    Name = "final-lb"
  }
}