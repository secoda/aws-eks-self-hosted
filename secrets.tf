resource "random_password" "database_password" {
  length  = 16
  special = false
}

resource "random_password" "es_password" {
  length           = 16
  special          = true
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
  override_special = "_"
}

resource "tls_private_key" "jwt" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "random_uuid" "secret_key" {}

resource "kubernetes_secret" "secoda" {
  metadata {
    name      = "secoda-dockerhub"
    namespace = kubernetes_namespace.app.metadata.0.name
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "${var.docker_server}" = {
          "username" = var.docker_username
          "password" = var.docker_password
          "email"    = var.docker_email
          "auth"     = base64encode("${var.docker_username}:${var.docker_password}")
        }
      }
    })
  }
}

resource "kubernetes_secret" "keycloak_password" {
  metadata {
    name      = "secoda-keycloak-password"
    namespace = kubernetes_namespace.app.metadata.0.name
  }

  type = "Opaque"

  data = {
    DB_PASSWORD       = random_password.database_password.result
    ES_PASSWORD       = random_password.es_password.result
    PRIVATE_KEY       = base64encode(tls_private_key.jwt.private_key_pem)
    PUBLIC_KEY        = base64encode(tls_private_key.jwt.public_key_pem)
    APISERVICE_SECRET = random_uuid.secret_key.result
  }
}

