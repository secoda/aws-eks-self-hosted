## Local variables

locals {
  tags = merge(
    var.tags,
    {
      ClusterName = var.cluster_name
    }
  )
}
