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
  default     = false
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

variable "public_subnet_cidrs" {
  description = "Cidr for public subnet 1"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
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


variable "jenkins_console_port" {
  description = "Jenkins_port"
  type        = number
  default     = 8080
}

variable "jenkins_ssh_port" {
  description = "Jenkins_port"
  type        = number
  default     = 22
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

variable "instance_type_jenkins" {
  description = "The type of jenkins instance "
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "The key name to use for the instance"
  type        = string
  default     = "Key1"
}