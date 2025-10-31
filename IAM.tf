### Worker iam configuration ###

variable "worker_policies" {
  type = list(tuple([string, string]))
  default = [
    ["ccm_worker", "./policies/ccm_worker_policy.json"]
  ]
}

# create an iam policies
resource "aws_iam_policy" "worker_node_policy" {
  count  = length(var.worker_policies)
  name   = "${var.worker_policies[count.index][0]}_policy"
  policy = file("${var.worker_policies[count.index][1]}")
}

# create an iam role
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

# attach the policies to the role
resource "aws_iam_role_policy_attachment" "attach_worker_policy" {
  count      = length(var.worker_policies)
  role       = aws_iam_role.worker_node_role.name
  policy_arn = aws_iam_policy.worker_node_policy[count.index].arn
}

# create an instance profile for the worker nodes to attach the created role
resource "aws_iam_instance_profile" "worker_instance_profile" {
  name = "worker_instance_profile"
  role = aws_iam_role.worker_node_role.name
}

### Master iam configuration ###

variable "master_policies" {
  type = list(tuple([string, string]))
  default = [
    ["ccm_master", "./policies/ccm_master_policy.json"]
  ]
}

# create an iam policies
resource "aws_iam_policy" "master_node_policy" {
  count  = length(var.master_policies)
  name   = "${var.master_policies[count.index][0]}_policy"
  policy = file("${var.master_policies[count.index][1]}")
}

# create an iam role
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

# attach the policy to the role
resource "aws_iam_role_policy_attachment" "attach_master_policy" {
  count      = length(var.master_policies)
  role       = aws_iam_role.master_node_role.name
  policy_arn = aws_iam_policy.master_node_policy[count.index].arn
}

# create an instance profile for the worker nodes to attach the created role
resource "aws_iam_instance_profile" "master_instance_profile" {
  name = "master_instance_profile"
  role = aws_iam_role.master_node_role.name
}