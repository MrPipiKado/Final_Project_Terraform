#################
#Resources      #
#################

variable "create_jenkins" {
  description = "Determines wether it is neede to ctreate the jenkins instance."
  type        = bool
  default     = true
}

variable "create_jenkins_slave" {
  description = "Determines wether it is neede to ctreate the jenkins instance."
  type        = bool
  default     = true
}

variable "create_k8s_master" {
  description = "Determines wether it is neede to ctreate the k8s_master."
  type        = bool
  default     = true
}

variable "create_db" {
  description = "Determines wether it is neede to ctreate the RDS DB."
  type        = bool
  default     = true
}

#################
#VPC            #
#################
variable "create_vpc" {
  description = "Determines wether it is neede to ctreate the VPC."
  type        = bool
  default     = true
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

#default
#An instance launched into the VPC runs on shared hardware by default,
#unless you explicitly specify a different tenancy during instance launch.
#
#dedicated
#An instance launched into the VPC is a Dedicated Instance by default,
#unless you explicitly specify a tenancy of host during instance launch. You cannot specify a tenancy of default during instance launch.
variable "instance_tenancy" {
  description = "A tenancy option for instances launched into the VPC"
  type        = string
  default     = "default"
}

variable "enable_dns_hostnames" {
  description = "Should be true to enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Should be true to enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "vps_name" {
  description = "Name of VPS"
  type        = string
  default     = "Final_Project"
}

#################
#Subnets        #
#################

variable "create_public_subnets" {
  description = "Determines wether it is neede to ctreate public subnets."
  type        = bool
  default     = true
}

variable "public_subnet_cidrs" {
  description = "Cidr for public subnet 1"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "create_private_subnets" {
  description = "Determines wether it is neede to ctreate public subnets."
  type        = bool
  default     = true
}

variable "private_subnet_cidrs" {
  description = "Cidr for private subnet 1"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "azs" {
  description = "Availability Zone A name"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b", "us-west-2c", "us-west-2d"]
}

variable "map_public_ip_on_launch" {
  description = "Auto-assign public IP on launch"
  type        = bool
  default     = true
}

#################
#Kubernetes     #
#################

variable "bastion_ssh_port" {
  description = "bastion_ssh_port"
  type        = number
  default     = 22
}
variable "cluster_port" {
  description = "bastion_ssh_port"
  type        = number
  default     = 8080
}

variable "internet_cidr_block" {
  description = "Internet_cidr_block"
  type        = string
  default     = "0.0.0.0/0"
}

variable "ami_ubuntu" {
  description = "Ubuntu server 20.04"
  type        = string
  default     = "ami-06e54d05255faf8f6"
}

variable "instance_type_k8s_master" {
  description = "The type of jenkins instance "
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "The key name to use for the instance"
  type        = string
  default     = "Key1"
}

variable "k8s_master_private_ip" {
  description = "Jenkins_slave_private_ip"
  type        = string
  default     = "10.0.1.150"
}

#################
#Jenkins slave  #
#################

variable "jenkins_slave_ssh_port" {
  description = "Jenkins_port"
  type        = number
  default     = 22
}

variable "jenkins_slave_private_ip" {
  description = "Jenkins_slave_private_ip"
  type        = string
  default     = "10.0.1.100"
}

variable "jenkins_console_port" {
  description = "Jenkins_port"
  type        = number
  default     = 8080
}

variable "instance_type_jenkins_slave" {
  description = "The type of server instance "
  type        = string
  default     = "t2.micro"
}

#################
#Jenkins master #
#################

variable "web_page_port" {
  description = "Web page port"
  type        = number
  default     = 8080
}

variable "jenkins_ssh_port" {
  description = "Web page port"
  type        = number
  default     = 22
}

variable "jenkins_master_private_ip" {
  description = "server_private_ip"
  type        = string
  default     = "10.0.1.200"
}

variable "instance_type_jenkins" {
  description = "The type of server instance "
  type        = string
  default     = "t2.micro"
}
#################
#RDS DB         #
#################

variable "db_name" {
  description = "DB name"
  type        = string
}

variable "db_user" {
  description = "DB user"
  type        = string
}

variable "db_password" {
  description = "DB password"
  type        = string
}

variable "db_port" {
  description = "DB port"
  type        = number
}

variable "identifier" {
  description = "The name of the RDS instance, if omitted, Terraform will assign a random, unique identifier"
  type        = string
  default     = "final-project-db"
}

variable "engine" {
  description = "The database engine to use"
  type        = string
  default     = "mysql"
}

variable "engine_version" {
  description = "The engine version to use"
  type        = string
  default     = "5.7"
}

variable "instance_class" {
  description = "The instance type of the RDS instance"
  type        = string
  default     = "db.t2.micro"
}

variable "allocated_storage" {
  description = "The allocated storage in gigabytes"
  type        = string
  default     = "20"
}

variable "storage_type" {
  description = "One of 'standard' (magnetic), 'gp2' (general purpose SSD), or 'io1' (provisioned IOPS SSD). The default is 'io1' if iops is specified, 'standard' if not. Note that this behaviour is different from the AWS web console, where the default is 'gp2'."
  type        = string
  default     = "gp2"
}

variable "storage_encrypted" {
  description = "Specifies whether the DB instance is encrypted"
  type        = bool
  default     = false
}

variable "iam_database_authentication_enabled" {
  description = "Specifies whether or mappings of AWS Identity and Access Management (IAM) accounts to database accounts is enabled"
  type        = bool
  default     = false
}

variable "multi_az" {
  description = "Specifies if the RDS instance is multi-AZ"
  type        = bool
  default     = false
}

variable "publicly_accessible" {
  description = "Bool to control if instance is publicly accessible"
  type        = bool
  default     = false
}

variable "allow_major_version_upgrade" {
  description = "Indicates that major version upgrades are allowed. Changing this parameter does not result in an outage and the change is asynchronously applied as soon as possible"
  type        = bool
  default     = false
}

variable "auto_minor_version_upgrade" {
  description = "Indicates that minor engine upgrades will be applied automatically to the DB instance during the maintenance window"
  type        = bool
  default     = true
}

variable "apply_immediately" {
  description = "Specifies whether any database modifications are applied immediately, or during the next maintenance window"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Determines whether a final DB snapshot is created before the DB instance is deleted. If true is specified, no DBSnapshot is created. If false is specified, a DB snapshot is created before the DB instance is deleted, using the value from final_snapshot_identifier"
  type        = bool
  default     = true
}

variable "copy_tags_to_snapshot" {
  description = "On delete, copy all Instance tags to the final snapshot (if final_snapshot_identifier is specified)"
  type        = bool
  default     = false
}

variable "performance_insights_enabled" {
  description = "Specifies whether Performance Insights are enabled"
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "The database can't be deleted when this value is set to true."
  type        = bool
  default     = false
}