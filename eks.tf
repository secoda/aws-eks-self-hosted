data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}



################################################################################
# EKS Module
################################################################################

module "eks" {
  source                                   = "terraform-aws-modules/eks/aws"
  version                                  = "~> 20.0"
  enable_cluster_creator_admin_permissions = true

  cluster_name                           = var.cluster_name
  cluster_version                        = var.cluster_version
  cluster_endpoint_private_access        = true
  cluster_endpoint_public_access         = true
  cluster_ip_family                      = "ipv4"
  cloudwatch_log_group_retention_in_days = "400"

  cluster_addons = {
    amazon-cloudwatch-observability = {}
  }

  cluster_encryption_config = {
    provider_key_arn = aws_kms_key.eks.arn
    resources        = ["secrets"]
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  fargate_profiles = {
    default = {
      name         = "default"
      cluster_name = var.cluster_name
      subnets      = module.vpc.private_subnets
      iam_role_additional_policies = {
        cloudwatch_observability = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
      }
      selectors = [{
        namespace = var.namespace
      }]
    }
    adm = {
      name         = "default-adm"
      cluster_name = var.cluster_name
      subnets      = module.vpc.private_subnets
      iam_role_additional_policies = {
        cloudwatch_observability = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
      }
      selectors = [{
        namespace = "${var.namespace}-adm"
      }]
    }
    observability = {
      name         = "observability"
      cluster_name = var.cluster_name
      subnets      = module.vpc.private_subnets
      iam_role_additional_policies = {
        cloudwatch_observability = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
      }
      selectors = [{
        namespace = "amazon-cloudwatch"
      }]
    }
    system = {
      name         = "default-system"
      cluster_name = var.cluster_name
      subnets      = module.vpc.private_subnets
      iam_role_additional_policies = {
        cloudwatch_observability = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
      }
      selectors = [{
        namespace = "kube-system"
      }]
    }
    coredns = {
      name         = "coredns"
      cluster_name = var.cluster_name
      subnets      = module.vpc.private_subnets
      iam_role_additional_policies = {
        cloudwatch_observability = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
      }
      selectors = [{
        namespace = "kube-system"
        labels = {
          k8s-app = "kube-dns"
        }
      }]
    }
  }

  # Extend cluster security group rules
  cluster_security_group_additional_rules = {
    egress_nodes_ephemeral_ports_tcp = {
      description                = "To node 1025-65535"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "egress"
      source_node_security_group = true
    }

    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }

    egress_all = {
      description = "Node all egress"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "egress"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  # aws-auth configmap
  #manage_aws_auth_configmap = true

  #aws_auth_roles = var.aws_auth_roles

  #aws_auth_users = var.aws_auth_users

  cluster_tags = {
    # This should not affect the name of the cluster primary security group
    # Ref: https://github.com/terraform-aws-modules/terraform-aws-eks/pull/2006
    # Ref: https://github.com/terraform-aws-modules/terraform-aws-eks/pull/2008
    Name = var.cluster_name,
  }

  tags = local.tags
}

################################################################################
# Supporting Resources
################################################################################
# This policy is required for the KMS key used for EKS root volumes, so the cluster is allowed to enc/dec/attach encrypted EBS volumes
data "aws_iam_policy_document" "ebs" {
  # Copy of default KMS policy that lets you manage it
  statement {
    sid       = "Enable IAM User Permissions"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  # Required for EKS
  statement {
    sid = "Allow service-linked role use of the CMK"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling", # required for the ASG to manage encrypted volumes for nodes
        module.eks.cluster_iam_role_arn,                                                                                                            # required for the cluster / persistentvolume-controller to create encrypted PVCs
      ]
    }
  }

  statement {
    sid       = "Allow attachment of persistent resources"
    actions   = ["kms:CreateGrant"]
    resources = ["*"]

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling", # required for the ASG to manage encrypted volumes for nodes
        module.eks.cluster_iam_role_arn,                                                                                                            # required for the cluster / persistentvolume-controller to create encrypted PVCs
      ]
    }

    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }
  }
}

resource "aws_kms_key" "eks" {
  description             = "EKS Secret Encryption Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = local.tags
}

resource "aws_kms_key" "ebs" {
  description             = "Customer managed key to encrypt EKS managed node group volumes"
  deletion_window_in_days = 7
  policy                  = data.aws_iam_policy_document.ebs.json
}


resource "null_resource" "k8s_patcher" {
  depends_on = [module.eks.cluster_id]
  triggers = {
    // fire any time the cluster is update in a way that changes its endpoint or auth
    endpoint = module.eks.cluster_endpoint
    ca_crt   = base64decode(module.eks.cluster_certificate_authority_data)
  }
  provisioner "local-exec" {
    command = <<EOH
cat >/tmp/ca.crt <<EOF
${base64decode(module.eks.cluster_certificate_authority_data)}
EOF
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/$(uname -s | tr '[:upper:]' '[:lower:]')/$(uname -m | tr '[:upper:]' '[:lower:]')/kubectl && chmod +x ./kubectl && \
if [ -n "$(kubectl --server="${module.eks.cluster_endpoint}" --certificate_authority=/tmp/ca.crt --token="${data.aws_eks_cluster_auth.this.token}" get deployment coredns -n kube-system -o 'jsonpath={.spec.template.metadata.annotations}')" ]; then
  ./kubectl \
    --server="${module.eks.cluster_endpoint}" \
    --certificate_authority=/tmp/ca.crt \
    --token="${data.aws_eks_cluster_auth.this.token}" \
    patch deployment coredns \
    -n kube-system --type json \
    -p='[{"op": "remove", "path": "/spec/template/metadata/annotations/eks.amazonaws.com~1compute-type"}]' && \
  ./kubectl \
    --server="${module.eks.cluster_endpoint}" \
    --certificate_authority=/tmp/ca.crt \
    --token="${data.aws_eks_cluster_auth.this.token}" \
    scale deployment coredns \
    -n kube-system --replicas 0 && \
  ./kubectl \
    --server="${module.eks.cluster_endpoint}" \
    --certificate_authority=/tmp/ca.crt \
    --token="${data.aws_eks_cluster_auth.this.token}" \
    scale deployment coredns \
    -n kube-system --replicas 2 ; fi && \
rm ./kubectl
EOH
  }
}

