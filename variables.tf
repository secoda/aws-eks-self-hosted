variable "region" {
  type    = string
  default = "us-west-1"
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "secoda"
}

variable "cluster_version" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "1.30"
}

variable "aws_auth_roles" {
  description = "A map of extra roles to be added into aws-auth"
  type        = list(any)
  default     = []
}

variable "aws_auth_users" {
  description = "A map of extra roles to be added into aws-auth"
  type        = list(any)
  default     = []
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "vpc_azs" {
  type    = list(string)
  default = ["us-west-1b", "us-west-1c"]
}

variable "private_subnets" {
  type    = list(string)
  default = ["10.0.0.0/24", "10.0.2.0/24"]
}

variable "database_subnets" {
  type    = list(string)
  default = ["10.0.20.0/24", "10.0.22.0/24"]
}

variable "elasticache_subnets" {
  type    = list(string)
  default = ["10.0.30.0/24", "10.0.32.0/24"]
}

variable "public_subnets" {
  type    = list(string)
  default = ["10.0.10.0/24", "10.0.12.0/24"]
}

variable "enable_flow_log" {
  type    = bool
  default = false
}
