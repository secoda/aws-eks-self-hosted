################################################################################
#  IAMs
################################################################################

### Prerequisites IAM resources

resource "aws_iam_policy" "secoda_instance_policy" {
  name        = "${var.name_identifier}_secoda_instance_policy"
  description = "Secoda Instance Policy"

  policy = jsonencode({
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ],
        Effect = "Allow",
        Resource = [
          "arn:aws:s3:::${local.bucket_name}/*"
        ],
        Sid = "s3"
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ],
        Effect = "Allow",
        Resource = [
          "*"
        ]
      }
    ],
    Version = "2012-10-17"
  })

  tags = local.tags
}

resource "aws_iam_role" "secoda_instance_profile" {
  name = "${var.name_identifier}_secoda_instance_profile"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
      {
        Effect = "Allow",
        Principal = {
          Federated = module.eks.oidc_provider_arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringLike = {
            "${module.eks.oidc_provider}:sub" = ["system:serviceaccount:*:${var.name_identifier}"],
            "${module.eks.oidc_provider}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  managed_policy_arns = [aws_iam_policy.secoda_instance_policy.arn, "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy", "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore", "arn:aws:iam::aws:policy/AmazonPrometheusRemoteWriteAccess"]
}

###
# ACK Controller permissions

module "aws_controller_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.44.0"

  role_name = "aws-controller-${var.cluster_name}"

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${var.namespace}-adm:aws-controller"]
    }
  }

  role_policy_arns = {
    rds_full_access         = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
    s3_full_access          = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
    elasticache_full_access = "arn:aws:iam::aws:policy/AmazonElastiCacheFullAccess"
    opensearch_full_access  = "arn:aws:iam::aws:policy/AmazonOpenSearchServiceFullAccess"
  }

  tags = local.tags
}
