resource "random_uuid" "bucket" {}

locals {
  bucket_name = "${var.name_identifier}-private-${substr(random_uuid.bucket.result, 0, 11)}a"
}

resource "helm_release" "secoda" {
  name      = var.name_identifier
  chart     = "${path.module}/helm/charts/secoda"
  namespace = kubernetes_namespace.app.metadata.0.name
  wait      = true
  timeout   = 1800

  values = [
    file("${path.module}/values.yaml")
  ]

  set {
    name  = "serviceAccount.name"
    value = var.name_identifier
  }
  set {
    name  = "serviceAccount.role_arn"
    value = aws_iam_role.secoda_instance_profile.arn
  }
  set {
    name  = "serviceAccount.namespace"
    value = kubernetes_namespace.app.metadata.0.name
  }
  set {
    name  = "ingress.hosts"
    value = var.fqdn
  }
  set {
    name  = "ingress.annotations.alb\\.ingress\\.kubernetes\\.io/load-balancer-name"
    value = "${var.name_identifier}-lb"
  }
  set {
    name  = "ingress.annotations.alb\\.ingress\\.kubernetes\\.io/certificate-arn"
    value = local.aws_acm_arn
  }
  set {
    name  = "datastores.secoda.authorized_domains"
    value = var.authorized_domains
  }

  set {
    name  = "services.api.image.registry"
    value = var.docker_artifact_registry_address
  }
  set {
    name  = "services.api.image.name"
    value = var.docker_artifact_api_name
  }

  set {
    name  = "services.api.resources.requests.cpu"
    value = var.api_requests_cpu
  }
  set {
    name  = "services.api.resources.limits.cpu"
    value = var.api_limits_cpu
  }
  set {
    name  = "services.api.resources.requests.memory"
    value = var.api_requests_mem
  }
  set {
    name  = "services.api.resources.limits.memory"
    value = var.api_limits_mem
  }

  set {
    name  = "services.frontend.image.registry"
    value = var.docker_artifact_registry_address
  }
  set {
    name  = "services.frontend.image.name"
    value = var.docker_artifact_frontend_name
  }

  set {
    name  = "services.frontend.resources.requests.cpu"
    value = var.frontend_requests_cpu
  }
  set {
    name  = "services.frontend.resources.limits.cpu"
    value = var.frontend_limits_cpu
  }
  set {
    name  = "services.frontend.resources.requests.memory"
    value = var.frontend_requests_mem
  }
  set {
    name  = "services.frontend.resources.limits.memory"
    value = var.frontend_limits_mem
  }

  set {
    name  = "services.rds.rds_storage"
    value = var.rds_storage
  }
  set {
    name  = "services.rds.rds_instance"
    value = var.rds_instance
  }
  set {
    name  = "services.rds.rds_version"
    value = var.rds_version
  }
  set {
    name  = "services.rds.rds_multiAz"
    value = var.rds_multi_az
  }
  set {
    name  = "services.rds.rds_sg"
    value = aws_security_group.rds_sg.id
  }
  set {
    name  = "services.rds.rds_backup_retention"
    value = var.rds_backup_retention
  }
  set {
    name  = "services.rds.rds_subnet_group"
    value = module.vpc.database_subnet_group_name
  }
  set {
    name  = "services.rds.rds_deletion_protection"
    value = var.rds_deletion_protection
  }
  set {
    name  = "services.es.es_volume_size"
    value = var.es_volume_size
  }
  set {
    name  = "services.es.es_instance"
    value = var.es_instance
  }
  set {
    name  = "services.es.es_replicas"
    value = var.es_replicas
  }
  set {
    name  = "services.es.es_region"
    value = var.region
  }
  set {
    name  = "services.es.es_sg"
    value = aws_security_group.opensearch_sg.id
  }
  set {
    name  = "services.es.es_subnet"
    value = module.vpc.database_subnets[0]
  }
  set {
    name  = "services.es.es_acct_id"
    value = data.aws_caller_identity.current.account_id
  }
  set {
    name  = "services.redis.redis_instance"
    value = var.redis_instance
  }
  set {
    name  = "services.redis.redis_subnetgroup"
    value = module.vpc.elasticache_subnet_group_name
  }
  set {
    name  = "services.redis.redis_sg"
    value = aws_security_group.elasticache_sg.id
  }
  set {
    name  = "services.s3.s3_region"
    value = var.region
  }
  set {
    name  = "services.s3.s3_name"
    value = local.bucket_name
  }
  set {
    name  = "logging.region"
    value = var.region
  }
  set {
    name  = "logging.prefix"
    value = "${var.name_identifier}-"
  }
  set {
    name  = "logging.group"
    value = "${var.name_identifier}-logs"
  }
  set {
    name  = "logging.retention"
    value = var.log_retention
  }
  depends_on = [
    module.eks.cluster_id,
    helm_release.rds-controller,
    helm_release.s3-controller,
    helm_release.elasticache-controller,
    helm_release.opensearch-controller,
    helm_release.alb-controller,
    kubernetes_secret.keycloak_password,
    aws_acm_certificate_validation.secoda
  ]
}
