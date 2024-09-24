#data "aws_ecrpublic_authorization_token" "token" {
#provider = aws.east1
#}


resource "helm_release" "rds-controller" {
  namespace        = "${var.namespace}-adm"
  create_namespace = true

  name       = "rds-controller"
  repository = "oci://public.ecr.aws/aws-controllers-k8s/"
  #repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  #repository_password = data.aws_ecrpublic_authorization_token.token.password
  chart   = "rds-chart"
  version = "1.4.3"

  values = [
    <<EOT
aws:
  region: ${var.region}
serviceAccount:
  name: aws-controller
  annotations:
    eks.amazonaws.com/role-arn: ${module.aws_controller_irsa.iam_role_arn}
EOT
  ]

  depends_on = [
    module.eks.cluster_id,
    module.aws_controller_irsa.iam_role_arn,
  ]

  lifecycle {
    ignore_changes = [
      repository_password,
    ]
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "eks_db_security_group"
  description = "Allow DB connection from EKS pods"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Port 5432 from EKS pods"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [
      module.eks.cluster_primary_security_group_id,
    ]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = local.tags
}

resource "helm_release" "s3-controller" {
  namespace        = "${var.namespace}-adm"
  create_namespace = true

  name       = "s3-controller"
  repository = "oci://public.ecr.aws/aws-controllers-k8s/"
  #repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  #repository_password = data.aws_ecrpublic_authorization_token.token.password
  chart   = "s3-chart"
  version = "1.0.15"

  values = [
    <<EOT
aws:
  region: ${var.region}
serviceAccount:
  create: false
  name: aws-controller
  annotations:
    eks.amazonaws.com/role-arn: ${module.aws_controller_irsa.iam_role_arn}
EOT
  ]

  depends_on = [
    module.eks.cluster_id,
    module.aws_controller_irsa.iam_role_arn,
  ]

  lifecycle {
    ignore_changes = [
      repository_password,
    ]
  }
}

resource "helm_release" "elasticache-controller" {
  namespace        = "${var.namespace}-adm"
  create_namespace = true

  name       = "elasticache-controller"
  repository = "oci://public.ecr.aws/aws-controllers-k8s/"
  #repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  #repository_password = data.aws_ecrpublic_authorization_token.token.password
  chart   = "elasticache-chart"
  version = "0.1.0"

  values = [
    <<EOT
aws:
  region: ${var.region}
serviceAccount:
  create: false
  name: aws-controller
  annotations:
    eks.amazonaws.com/role-arn: ${module.aws_controller_irsa.iam_role_arn}
EOT
  ]

  depends_on = [
    module.eks.cluster_id,
    module.aws_controller_irsa.iam_role_arn,
  ]

  lifecycle {
    ignore_changes = [
      repository_password,
    ]
  }
}

resource "aws_security_group" "elasticache_sg" {
  name        = "eks_elasticache_security_group"
  description = "Allow ElastiCache connection from EKS pods"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Port 6379 from EKS pods"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    security_groups = [
      module.eks.cluster_primary_security_group_id,
    ]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = local.tags
}

resource "helm_release" "opensearch-controller" {
  namespace        = "${var.namespace}-adm"
  create_namespace = true

  name       = "opensearch-controller"
  repository = "oci://public.ecr.aws/aws-controllers-k8s/"
  #repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  #repository_password = data.aws_ecrpublic_authorization_token.token.password
  chart   = "opensearchservice-chart"
  version = "0.0.27"

  values = [
    <<EOT
aws:
  region: ${var.region}
serviceAccount:
  create: false
  name: aws-controller
  annotations:
    eks.amazonaws.com/role-arn: ${module.aws_controller_irsa.iam_role_arn}
EOT
  ]

  depends_on = [
    module.eks.cluster_id,
    module.aws_controller_irsa.iam_role_arn,
  ]

  lifecycle {
    ignore_changes = [
      repository_password,
    ]
  }
}

resource "aws_security_group" "opensearch_sg" {
  name        = "eks_opensearch_security_group"
  description = "Allow OpenSearch connection from EKS pods"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Port 443 from EKS pods"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = [
      module.eks.cluster_primary_security_group_id,
    ]
  }

  ingress {
    description = "Port 80 from EKS pods"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [
      module.eks.cluster_primary_security_group_id,
    ]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = local.tags
}

