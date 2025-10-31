# Bastion Host Outputs
output "bastion_host_public_ip" {
  value       = aws_instance.bastion.public_ip
  description = "The public IP address of the bastion host"
}

output "bastion_host_id" {
  value       = aws_instance.bastion.id
  description = "The instance ID of the bastion host"
}

output "bastion_security_group_id" {
  value       = aws_security_group.bastion_sg.id
  description = "The security group ID of the bastion host"
}

# Kubernetes API Outputs
output "k8s_api" {
  value       = local.k8s_api
  description = "The Kubernetes API endpoint"
}

# Join Scripts Outputs
output "worker_join_script" {
  value       = file("${path.module}/scripts/worker_join_script.sh")
  description = "A script containing the join command used to attach new worker nodes to the cluster"
}

output "master_join_script" {
  value       = file("${path.module}/scripts/master_join_script.sh")
  description = "A script containing the join command used to attach new master nodes to the cluster"
}

# Worker Autoscaling Outputs
output "worker_autoscaling_group_id" {
  value       = aws_autoscaling_group.worker_autoscaling_group.id
  description = "The ID of the worker autoscaling group"
}

output "worker_autoscaling_group_arn" {
  value       = aws_autoscaling_group.worker_autoscaling_group.arn
  description = "The ARN of the worker autoscaling group"
}

output "worker_autoscaling_group_name" {
  value       = aws_autoscaling_group.worker_autoscaling_group.name
  description = "The name of the worker autoscaling group"
}

output "worker_launch_template_id" {
  value       = aws_launch_template.worker_template.id
  description = "The ID of the worker launch template"
}

# Master/Control Plane Outputs
output "master_instance_ids" {
  value       = aws_instance.master[*].id 
  description = "List of master node instance IDs"
}

output "master_instance_private_ips" {
  value       = aws_instance.master[*].private_ip
  description = "List of master node private IP addresses"
}

output "master_security_group_id" {
  value       = aws_security_group.master_sg.id
  description = "The security group ID for master nodes"
}

output "master_security_group_arn" {
  value       = aws_security_group.master_sg.arn
  description = "The security group ARN for master nodes"
}

# Worker Security Group Outputs
output "worker_security_group_id" {
  value       = aws_security_group.worker_sg.id
  description = "The security group ID for worker nodes"
}

output "worker_security_group_arn" {
  value       = aws_security_group.worker_sg.arn
  description = "The security group ARN for worker nodes"
}

# VPC and Network Outputs
output "vpc_id" {
  value       = aws_vpc.vpc.id
  description = "The VPC ID where the cluster is deployed"
}

output "private_subnet_ids" {
  value       = aws_subnet.private_subnet[*].id
  description = "List of private subnet IDs where cluster nodes are deployed"
}

output "public_subnet_ids" {
  value       = aws_subnet.public_subnet[*].id
  description = "List of public subnet IDs"
}

