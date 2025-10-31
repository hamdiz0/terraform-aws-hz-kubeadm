### Worker IAM Configuration ###

locals {
  worker_policies = [
    ["ccm_worker", "${path.module}/policies/ccm_worker_policy.json"]
  ]

  master_policies = [
    ["ccm_master", "${path.module}/policies/ccm_master_policy.json"]
  ]
}

# create IAM policies for worker
resource "aws_iam_policy" "worker_node_policy" {
  count  = length(local.worker_policies)
  name   = "${local.worker_policies[count.index][0]}_policy"
  policy = file(local.worker_policies[count.index][1])
}

# create IAM role for worker nodes
resource "aws_iam_role" "worker_node_role" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name = "Worker_Node_Role"
  }
}

# attach the policies to the worker role
resource "aws_iam_role_policy_attachment" "attach_worker_policy" {
  count      = length(local.worker_policies)
  role       = aws_iam_role.worker_node_role.name
  policy_arn = aws_iam_policy.worker_node_policy[count.index].arn
}

# create instance profile for worker nodes
resource "aws_iam_instance_profile" "worker_instance_profile" {
  name = "worker_instance_profile"
  role = aws_iam_role.worker_node_role.name
}

### Master IAM Configuration ###

# create IAM policies for master
resource "aws_iam_policy" "master_node_policy" {
  count  = length(local.master_policies)
  name   = "${local.master_policies[count.index][0]}_policy"
  policy = file(local.master_policies[count.index][1])
}

# create IAM role for master nodes
resource "aws_iam_role" "master_node_role" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name = "Master_Node_Role"
  }
}

# attach the policies to the master role
resource "aws_iam_role_policy_attachment" "attach_master_policy" {
  count      = length(local.master_policies)
  role       = aws_iam_role.master_node_role.name
  policy_arn = aws_iam_policy.master_node_policy[count.index].arn
}

# create instance profile for master nodes
resource "aws_iam_instance_profile" "master_instance_profile" {
  name = "master_instance_profile"
  role = aws_iam_role.master_node_role.name
}
