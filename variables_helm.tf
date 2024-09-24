variable "namespace" {
  type        = string
  description = "namespace"
  default     = "secoda"
}

variable "docker_password" {
  type = string
}

# DockerHub Config - Do Not Modify
variable "docker_username" {
  type    = string
  default = "secodaonpremise"
}

variable "docker_server" {
  description = "docker server"
  default     = "https://index.docker.io/v1/"
}

variable "docker_artifact_registry_address" {
  type    = string
  default = "secoda"
}

variable "docker_artifact_api_name" {
  type    = string
  default = "on-premise-api"
}

variable "docker_artifact_frontend_name" {
  type    = string
  default = "on-premise-frontend"
}

variable "docker_email" {
  type    = string
  default = "carter@secoda.co"
}

variable "log_retention" {
  type    = number
  default = 60
}

variable "name_identifier" {
  type        = string
  description = "unique name identifier"
  default     = "secoda"

  validation {
    condition     = can(regex("^[0-9a-z-]+$", var.name_identifier))
    error_message = "must be lower case letters, numbers or dash"
  }
}

variable "authorized_domains" {
  type        = string
  description = "comma separated list of domains- double backslash escape the commas for helm parsing"
  default     = "secoda.co"
}

variable "fqdn" {
  type        = string
  description = "fqdn of proxy"
  default     = "ekstest.dev.secoda.co"
}

variable "acm_lb_cert_arn" {
  type        = string
  description = "ACM cert to use for ALB ingress"
  default     = ""
}

#
# Postgres DB Settings
variable "rds_storage" {
  type    = number
  default = 256
}
variable "rds_instance" {
  type    = string
  default = "db.t4g.small"
}
variable "rds_version" {
  type    = string
  default = "14"
}
variable "rds_multi_az" {
  type    = bool
  default = false
}
variable "rds_backup_retention" {
  type    = number
  default = 21
}
variable "rds_deletion_protection" {
  type    = bool
  default = true
}

variable "redis_instance" {
  type        = string
  description = "redis elasticache instance"
  default     = "cache.t4g.medium"
}

# Elasticsearch replicas
variable "es_replicas" {
  type        = string
  description = "number of nodes in elasticsearch cluster minimum 1"
  default     = "1"
}

# Elasticsearch/Opensearch 
variable "es_volume_size" {
  type    = number
  default = 96
}

variable "es_instance" {
  type    = string
  default = "t3.medium.search"
}

# API container limits
variable "api_limits_cpu" {
  type        = string
  description = "api cpu limit"
  default     = "2048m"
}

variable "api_requests_cpu" {
  type        = string
  description = "api cpu request"
  default     = "2048m"
}

variable "api_limits_mem" {
  type        = string
  description = "api mem limit"
  default     = "20480Mi"
}

variable "api_requests_mem" {
  type        = string
  description = "api mem request"
  default     = "20480Mi"
}

# Frontend container limits
variable "frontend_limits_cpu" {
  type        = string
  description = "frontend cpu limit"
  default     = "512m"
}

variable "frontend_requests_cpu" {
  type        = string
  description = "frontend cpu request"
  default     = "512m"
}

variable "frontend_limits_mem" {
  type        = string
  description = "frontend mem limit"
  default     = "2048Mi"
}

variable "frontend_requests_mem" {
  type        = string
  description = "frontend mem request"
  default     = "2048Mi"
}

