variable "cidr" {
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