resource "aws_vpc" "nodes" {
  depends_on = [
    aws_iam_role_policy_attachment.cluster_eks_cluster,
    aws_iam_role_policy_attachment.cluster_eks_service,
    aws_iam_role_policy_attachment.nodes_ecr,
    aws_iam_role_policy_attachment.nodes_eks_cni,
    aws_iam_role_policy_attachment.nodes_eks_worker,
  ]

  cidr_block           = var.cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.tags, {
    "kubernetes.io/cluster/${var.name}" : "shared"
  })
}

resource "aws_internet_gateway" "nodes" {
  vpc_id = aws_vpc.nodes.id

  tags = local.tags
}

resource "aws_subnet" "public" {
  count = 3

  availability_zone       = local.availability_zones[count.index]
  cidr_block              = cidrsubnet(var.cidr, 4, count.index)
  map_public_ip_on_launch = !var.private
  vpc_id                  = aws_vpc.nodes.id

  tags = merge(local.tags, {
    Name = "${var.name} public ${count.index}"
    "kubernetes.io/cluster/${var.name}" : "shared"
    "kubernetes.io/role/elb" : ""
  })

  timeouts {
    delete = "6h"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.nodes.id

  tags = merge(local.tags, {
    Name = "${var.name} public"
  })
}

resource "aws_route" "public-default" {
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.nodes.id
  route_table_id         = aws_route_table.public.id

  timeouts {
    create = "5m"
  }
}

resource "aws_route_table_association" "public" {
  count = 3

  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public[count.index].id
}

resource "aws_subnet" "private" {
  count = var.private ? 3 : 0

  availability_zone = local.availability_zones[count.index]
  cidr_block        = cidrsubnet(var.cidr, 2, count.index + 1)
  vpc_id            = aws_vpc.nodes.id

  tags = merge(local.tags, {
    Name = "${var.name} private ${count.index}"
    "kubernetes.io/cluster/${var.name}" : "shared"
    "kubernetes.io/role/internal-elb" : ""
  })

  timeouts {
    delete = "6h"
  }
}

resource "aws_eip" "nat" {
  count = var.private ? 3 : 0

  vpc = true

  tags = merge(local.tags, {
    Name = "${var.name} nat ${count.index}"
  })
}

resource "aws_nat_gateway" "private" {
  count = var.private ? 3 : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(local.tags, {
    Name = "${var.name} ${count.index}"
  })
}

resource "aws_route_table" "private" {
  count = var.private ? 3 : 0

  vpc_id = aws_vpc.nodes.id

  tags = merge(local.tags, {
    Name = "${var.name} private ${count.index}"
  })
}

resource "aws_route" "private-default" {
  depends_on = [
    aws_internet_gateway.nodes,
    aws_route_table.private,
  ]

  count = var.private ? 3 : 0

  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.private[count.index].id
  route_table_id         = aws_route_table.private[count.index].id

  timeouts {
    create = "5m"
  }
}

resource "aws_route_table_association" "private" {
  count = var.private ? 3 : 0

  route_table_id = aws_route_table.private[count.index].id
  subnet_id      = aws_subnet.private[count.index].id
}

resource "aws_security_group" "cluster" {
  name        = "${var.name}-cluster"
  description = "${var.name} cluster"
  vpc_id      = aws_vpc.nodes.id

  tags = merge(local.tags, {
    Name = "${var.name}-cluster"
  })
}

resource "null_resource" "network" {
  depends_on = [
    aws_internet_gateway.nodes,
    aws_nat_gateway.private,
    aws_route.private-default,
    aws_route.public-default,
    aws_route_table.private,
    aws_route_table.public,
    aws_route_table_association.private,
    aws_route_table_association.public,
    aws_security_group.cluster,
    aws_subnet.private,
    aws_subnet.public,
    aws_vpc.nodes,
  ]

  provisioner "local-exec" {
    when    = destroy
    command = "sleep 300"
  }
}
