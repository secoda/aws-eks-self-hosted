resource "helm_release" "alb-controller" {
  depends_on        = [module.eks.cluster_id]
  name              = "aws-load-balancer-controller"
  chart             = "aws-load-balancer-controller"
  repository        = "https://aws.github.io/eks-charts"
  namespace         = "kube-system"
  dependency_update = true

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "awsRegion"
    value = var.region
  }

  set {
    name  = "region"
    value = var.region
  }

  set {
    name  = "vpcId"
    value = module.vpc.vpc_id
  }

  set {
    name  = "rbac.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.lb_role.iam_role_arn
  }

  set {
    name  = "enableServiceMutatorWebhook"
    value = "false"
  }
}

module "lb_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name                              = "${var.name_identifier}_eks_lb"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

