variable "ssh_private_key_location" {
  type = string
  description = "location of the generated SSH private key"
}

variable "ssh_public_key_location" {
  type = string
  description = "location of the generated SSH public key"
}

variable "region" {
  type        = string
  description = "The AWS region to deploy the Kubernetes cluster in"
}

variable "bastion_ami" {
  type        = string
  default     = "ami-0359cb6c0c97c6607" # debian 12 ami
  description = "The AMI ID for the bastion host (default: Debian 12)"
}

variable "bastion_host_user" {
  type        = string
  default     = "admin"
  description = "The SSH username for connecting to the bastion host (default user for Debian AMI)"
}

variable "k8s_ami_id" {
  type        = string
  description = "The id of the AMI to use for Kubernetes master and worker nodes. Use existing AMI or create youre own with the hz-ami-gen module (https://registry.terraform.io/modules/hamdiz0/hz-ami-gen)"
}

variable "master_instance_type" {
  type        = string
  description = "The EC2 instance type for Kubernetes master/control plane nodes"
}

variable "worker_instance_type" {
  type        = string
  description = "The EC2 instance type for Kubernetes worker nodes"
}

variable "bastion_instance_type" {
  type        = string
  description = "The EC2 instance type for the bastion host"
}

variable "nat_instance_type" {
  type        = string
  default     = "t2.micro"
  description = "The EC2 instance type for the NAT instance (only used if use_nat_gateway is false). Default: t4g.micro (ARM-based)"
}

variable "instance_user" {
  type        = string
  description = "The SSH username for connecting to Kubernetes master and worker nodes. (Debian: admin | Amazon Linux: ec2-user | ...)"
}

variable "local_user" {
  type        = string
  description = "The local user on your machine. Used in the SSH config to simlify SSH connections to the bastion and control planes (ssh master-1, ssh bastion, ssh master-2, ...)"
}

variable "min_worker_number" {
  type        = number
  description = "The minimum number of worker nodes in the autoscaling group"
}

variable "max_worker_number" {
  type        = number
  description = "The maximum number of worker nodes in the autoscaling group"
}

variable "control_plane_number" {
  type        = number
  description = "The number of master/control plane nodes to deploy"
  
  validation {
    condition     = var.control_plane_number > 0 && var.control_plane_number % 2 != 0
    error_message = "Control plane number must be a positive odd number (1, 3, 5, etc.) for proper etcd quorum"
  }
}

variable "use_internal_lb" {
  type        = bool
  default     = false
  description = "Whether to use an internal load balancer for the Kubernetes API (true = internal, false = public ip of the initial master node)"
}

variable "use_nat_gateway" {
  type        = bool
  default     = false
  description = "Whether to use AWS NAT Gateway (true) or a NAT instance (false). NAT Gateway is more reliable but more expensive. The NAT instance is created using the hz-nat-instance module (https://registry.terraform.io/modules/hamdiz0/hz-nat-instance)."
}