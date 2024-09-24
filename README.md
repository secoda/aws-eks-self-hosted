# aws_eks_onprem
**On prem Secoda for EKS**

Secoda for EKS should be installed using the included Terraform and Helm chart. Although, it may be installed as just a Helm chart by manually installing all prerequisites.
This method is not recommended, though.

## Terraform Prerequisites
The Terraform setup requires an AWS account with the ability to run the API as a user or role that has permissions to manage IAM, EC2, EKS, ACM (since this role
requires IAM permissions, it's likely you'll just run it with an admin-level account or role.) You will also need to install Terraform and be able to authenticate
Terraform to your AWS account.

## Terraform Setup for Secoda
The Terraform setup will follow these steps:

* Ensure Terraform is installed and working (https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
* Set up your AWS authentication for Terraform (https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
  * Note: Make sure your region is correctly set up for your desired Secoda installation environment.
* Change into the `aws_eks_onprem` directory
* Copy `terraform.tfvars_example` to `terraform.tfvars`
* Edit `terraform.tfvars` to match your environment
  * Set the `docker_password` to the password provided by Secoda
  * Set the `region` to your installation AWS region
  * Set the `authorized_domains` to any email address domains that you will use to log in to Secoda
  * Set the FQDN to the address you will be using to access Secoda (like `secoda.customer.com`)
    * Note: this address will be used to provision an ACM certificate that must be approved before the Terraform installation can complete. You may pre-provision this certificate and set the `acm_lb_cert_arn` value in `terraform.tfvars`
* Run `terraform init` to initialize the dependencies
* Run `terraform install` to install everything
  * If you have not preprovisioned an ACM certificate you will need to approve the automatically-generated certificate (you will see Terraform waiting for `aws_acm_certificate_validation.secoda` to complete while the Terraform install is paused waiting for approval)
* There are a number of long-running installation steps, both in the Terraform prerequisite install and in the Secoda Helm install that will take some time to complete
* Once the installation is complete, Terraform will output
  * The FQDN of the ingress load balancer (like `secoda-lb-17356723.us-west-1.elb.amazonaws.com`.) This will be the DNS CNAME target for your FQDN.
  * The NAT egress IP address. You will use this for your allow-list IP addresses on any firewalls or security groups. All outgoing connections to databases or applications will originate from this address.

## Updating Secoda

* The Secoda Helm is configured to pull the latest images automatically on restart.
* `kubectl rollout restart deployment -n secoda` will redeploy the application with the latest images.

## Terraform Details- Some basic direction to install the Secoda Helm Chart without Terraform (Not Recommended)
Terraform creates these assets during the installation process **These are the assets you must create manually if you do not use Terraform for the installation**:

* A VPC with NAT Gateway egress, 2 public subnets, 2 private application subnets, 2 DB subnets and 2 Elasticache subnets
* DB and Elasticache subnet groups
* An EKS cluster and Fargate profiles to run the workloads
* The k8s application namespace
* A k8s secret with Dockerhub authentication credentials
* A k8s secret with all application passwords and secrets
* IAM roles for the application
* Install AWS Controllers for Kubernetes (ACK) for RDS, S3, Elasticache and OpenSearch (includes namespace and IAM/k8s roles)
* Security groups for all ACK services
* Install ALB Ingress Controller (AWS Load Balancer Controller)
* Install the Secoda Helm Chart

| TF File      | Purpose  | Helm Values Set |
| :-------- | :--------  | :---------- |
| `variables.tf` | VPC and EKS defaults | None |
| `variables_helm.tf` | Helm Defaults | Namespace is set here<br/>`serviceAccount.name`<br/>`ingress.hosts`<br/>`ingress.annotations.alb\\.ingress\\.kubernetes\\.io/load-balancer-name`<br/>`datastores.secoda.authorized_domains`<br/>`datastores.secoda.authorized_domains`<br/>`services.api.image.registry`<br/>`services.api.image.name`<br/>`services.api.resources.requests.cpu`<br/>`services.api.resources.limits.cpu`<br/>`services.api.resources.requests.memory`<br/>`services.api.resources.limits.memory`<br/>`services.frontend.image.registry`<br/>`services.frontend.image.name`<br/>`services.frontend.resources.requests.cpu`<br/>`services.frontend.resources.limits.cpu`<br/>`services.frontend.resources.requests.memory`<br/>`services.frontend.resources.limits.memory`<br/>`services.rds.rds_storage`<br/>`services.rds.rds_instance`<br/>`services.rds.rds_version`<br/>`services.rds.rds_multiAz`<br/>`services.rds.rds_backup_retention`<br/>`services.rds.rds_deletion_protection`<br/>`services.es.es_volume_size`<br/>`services.es.es_instance`<br/>`services.es.es_replicas`<br/>`services.es.es_region`<br/>`services.redis.redis_instance`<br/>`services.s3.s3_region`<br/>`logging.region`<br/>`logging.prefix`<br/>`logging.group`<br/>`logging.retention` |
| `vpc.tf` | Creates VPC and RDS,Elasticache subnets and subnet groups | <br/>`services.rds.rds_subnet_group`<br/>`services.es.es_subnet`<br/>`services.redis.redis_subnetgroup` |
| `eks.tf` | Create EKS cluster, Fargate profiles and OIDC provider | None |
| `locals.tf` | Set some values for the EKS cluster | None |
| `kube_defaults.tf` | Creates some defaults, including app namespace | <br/>`serviceAccount.namespace` |
| `secrets.tf` | Secure population of secrets outside of Helm | `secoda-dockerhub` secret for dockerhub credentials<br/>`secoda-keycloak-password` secret for `DB_PASSWORD`, `ES_PASSWORD`, `PRIVATE_KEY`, `PUBLIC_KEY`, `APISERVICE_SECRET` to set env vars |
| `iam.tf` | Create IAM role for the app service account<br/>Create IAM role and service account for ACK controllers | `serviceAccount.role_arn` |
| `aws-controller.tf` | Install ACK controllers for RDS, S3, Opensearch, Elasticache<br/>Create security group for each service | <br/>`services.rds.rds_sg`<br/>`services.es.es_sg`<br/>`services.redis.redis_sg` |
| `aws-lb-controller.tf` | Install ALB ingress controller | None |
| `acm_cert.tf` | Create ACM certificate for the ALB ingress | `ingress.annotations.alb\\.ingress\\.kubernetes\\.io/certificate-arn` |
| `helm_secoda.tf` | Helm release for secoda app | `services.s3.s3_name` |

An example `values.yaml` file is also included. However, all of the prerequisites must be in place before trying to install the Secoda Helm directly 
