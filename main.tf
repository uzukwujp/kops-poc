
terraform {
  required_providers {
    kops = {
      source = "eddycharly/kops"
      version = "1.26.0-alpha.1"
    }
  }
}

provider "kops" {
  state_store = "s3://k8s-state-kops"
  // optionally set up your cloud provider access config
  aws {
    profile = "new-nonprod"
  }
}

locals {
  masterType  = "t3.medium"
  nodeType    = "t3.medium"
  clusterName = "cluster.kops.darey.io"
  dnsZone     = "kops.darey.io"
  vpcId       = "vpc-0e17cfea101f0195e"
  privateSubnets = [
    { subnetId = "subnet-0c69c0ac92a4958c6", zone = "us-east-1b" },
    { subnetId = "subnet-022ddaf0618c5b4dd", zone = "us-east-1a" },
    { subnetId = "subnet-0b3fa3ca298002591", zone = "us-east-1c" }
  ]
  utilitySubnets = [
    { subnetId = "subnet-09cb8e28b88e21a04", zone = "us-east-1a" },
    { subnetId = "subnet-02bb45f5ca35add07", zone = "us-east-1b" },
    { subnetId = "subnet-03681c9c4a925c196", zone = "us-east-1c" }
  ]
}

resource "kops_cluster" "cluster" {
  name               = local.clusterName
  admin_ssh_key      = file("${path.module}/kops.pub")
  kubernetes_version = "stable"
  dns_zone           = local.dnsZone
  network_id         = local.vpcId

  cloud_provider {
    aws {}
  }

  iam {
    allow_container_registry = true
  }

  networking {
    calico {}
  }

  topology {
    masters = "private"
    nodes   = "private"
    dns {
      type = "Private"
    }
  }

  subnet {
    name        = "private-0"
    type        = "Private"
    provider_id = local.privateSubnets[0].subnetId
    zone        = local.privateSubnets[0].zone
  }
  subnet {
    name        = "private-1"
    type        = "Private"
    provider_id = local.privateSubnets[1].subnetId
    zone        = local.privateSubnets[1].zone
  }
  subnet {
    name        = "private-2"
    type        = "Private"
    provider_id = local.privateSubnets[2].subnetId
    zone        = local.privateSubnets[2].zone
  }

  subnet {
    name        = "utility-0"
    type        = "Utility"
    provider_id = local.utilitySubnets[0].subnetId
    zone        = local.utilitySubnets[0].zone
  }
  subnet {
    name        = "utility-1"
    type        = "Utility"
    provider_id = local.utilitySubnets[1].subnetId
    zone        = local.utilitySubnets[1].zone
  }
  subnet {
    name        = "utility-2"
    type        = "Utility"
    provider_id = local.utilitySubnets[2].subnetId
    zone        = local.utilitySubnets[2].zone
  }

  etcd_cluster {
    name = "main"
    member {
      name           = "master-0"
      instance_group = "master-0"
    }
    member {
      name           = "master-1"
      instance_group = "master-1"
    }
    member {
      name           = "master-2"
      instance_group = "master-2"
    }
  }

  etcd_cluster {
    name = "events"
    member {
      name           = "master-0"
      instance_group = "master-0"
    }
    member {
      name           = "master-1"
      instance_group = "master-1"
    }
    member {
      name           = "master-2"
      instance_group = "master-2"
    }
  }
}


# kops instance instance_group

resource "kops_instance_group" "master-0" {
  cluster_name = kops_cluster.cluster.id
  name         = "master-0"
  role         = "Master"
  min_size     = 1
  max_size     = 1
  machine_type = local.masterType
  subnets      = ["private-0"]
}
resource "kops_instance_group" "master-1" {
  cluster_name = kops_cluster.cluster.id
  name         = "master-1"
  role         = "Master"
  min_size     = 1
  max_size     = 1
  machine_type = local.masterType
  subnets      = ["private-1"]
}

resource "kops_instance_group" "master-2" {
  cluster_name = kops_cluster.cluster.id
  name         = "master-2"
  role         = "Master"
  min_size     = 1
  max_size     = 1
  machine_type = local.masterType
  subnets      = ["private-2"]
}

resource "kops_instance_group" "node-0" {
  cluster_name = kops_cluster.cluster.id
  name         = "node-0"
  role         = "Node"
  min_size     = 1
  max_size     = 2
  machine_type = local.nodeType
  subnets      = ["private-0"]
}

resource "kops_instance_group" "node-1" {
  cluster_name = kops_cluster.cluster.id
  name         = "node-1"
  role         = "Node"
  min_size     = 1
  max_size     = 2
  machine_type = local.nodeType
  subnets      = ["private-1"]
}

resource "kops_instance_group" "node-2" {
  cluster_name = kops_cluster.cluster.id
  name         = "node-2"
  role         = "Node"
  min_size     = 1
  max_size     = 2
  machine_type = local.nodeType
  subnets      = ["private-2"]
}

resource "kops_cluster_updater" "updater" {
  cluster_name = kops_cluster.cluster.id

  keepers = {
    cluster  = kops_cluster.cluster.revision
    master-0 = kops_instance_group.master-0.revision
    master-1 = kops_instance_group.master-1.revision
    master-2 = kops_instance_group.master-2.revision
    node-0   = kops_instance_group.node-0.revision
    node-1   = kops_instance_group.node-1.revision
    node-2   = kops_instance_group.node-2.revision
  }
}
