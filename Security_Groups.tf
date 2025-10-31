data "http" "my_public_ip" {
  url = "https://api.ipify.org?format=text"
}

### MASTER SECURITY GROUP ###

resource "aws_security_group" "master_sg" {
  name        = "master-sg"
  description = "security group for k8s master Node"
  vpc_id      = aws_vpc.vpc.id
  tags = {
    "kubernetes.io/cluster/kubernetes" = "owned"
  }
}

# control palne ports
variable "control_plane_ports" {
  type = list(tuple([string, string, string, string]))
  default = [
    # ["from_port","to_port","ip_protocol","service"]
    ["6443", "6443", "tcp", "Kubernetes API"],
    ["2379", "2380", "tcp", "etcd"],
    ["10250", "10250", "tcp", "Kubelet API"],
    ["10259", "10259", "tcp", "kube-scheduler"],
    ["10257", "10257", "tcp", "controller-manager"],
    ["443", "443", "tcp", "HTTPS"],
    ["80", "80", "tcp", "HTTP"],
    ["22", "22", "tcp", "SSH"],
    ["6783", "6784", "tcp", "Weave-tcp"],
    ["6783", "6784", "udp", "Weave-udp"]
  ]
}

# apply all control plane ports
resource "aws_vpc_security_group_ingress_rule" "control_plane_ingress" {
  count             = length(var.control_plane_ports)
  security_group_id = aws_security_group.master_sg.id
  cidr_ipv4         = aws_vpc.vpc.cidr_block
  from_port         = var.control_plane_ports[count.index][0]
  to_port           = var.control_plane_ports[count.index][1]
  ip_protocol       = var.control_plane_ports[count.index][2]
  description       = "Allow ${var.control_plane_ports[count.index][3]}"
}


# allow all outbound
resource "aws_vpc_security_group_egress_rule" "control_plane_egress" {
  security_group_id = aws_security_group.master_sg.id
  from_port         = 0
  to_port           = 0
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow all outbound traffic from control plane"
  lifecycle {
    ignore_changes = all
  }
}

### WORKER SECURITY GROUP ###

resource "aws_security_group" "worker_sg" {
  name        = "worker-sg"
  description = "security group for k8s worker Nodes"
  vpc_id      = aws_vpc.vpc.id
  tags = {
    "kubernetes.io/cluster/kubernetes" = "owned"
  }
}

# worker node ports
variable "worker_node_ports" {
  type = list(tuple([string, string, string, string]))
  default = [
    # ["from_port","to_port","ip_protocol","service"]
    ["10250", "10250", "tcp", "Kubelet API"],
    ["10256", "10256", "tcp", "kube-proxy"],
    ["443", "443", "tcp", "HTTPS"],
    ["80", "80", "tcp", "HTTP"],
    ["6783", "6784", "tcp", "Weave-tcp"],
    ["6783", "6784", "udp", "Weave-udp"],
    ["30000", "32767", "tcp", "NodePort Services"],
    ["22", "22", "tcp", "SSH"],
  ]
}

# apply all worker node ports
resource "aws_vpc_security_group_ingress_rule" "worker_node_ingress" {
  count             = length(var.worker_node_ports)
  security_group_id = aws_security_group.worker_sg.id
  cidr_ipv4         = aws_vpc.vpc.cidr_block
  from_port         = var.worker_node_ports[count.index][0]
  to_port           = var.worker_node_ports[count.index][1]
  ip_protocol       = var.worker_node_ports[count.index][2]
  description       = "Allow ${var.worker_node_ports[count.index][3]}"
}

# allow all outbound
resource "aws_vpc_security_group_egress_rule" "worker_node_egress" {
  security_group_id = aws_security_group.worker_sg.id
  from_port         = 0
  to_port           = 0
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow all outbound traffic from worker nodes"
  lifecycle {
    ignore_changes = all
  }
}

### BASTION SECURITY GROUP ###

resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "security group for k8s worker Nodes"
  vpc_id      = aws_vpc.vpc.id
}

# ssh
resource "aws_vpc_security_group_ingress_rule" "bastion_ssh_ingress" {
  security_group_id = aws_security_group.bastion_sg.id
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = "${data.http.my_public_ip.response_body}/32"
  description       = "allow ssh"
}

# allow all outbound
resource "aws_vpc_security_group_egress_rule" "bastion_ssh_egress" {
  security_group_id = aws_security_group.bastion_sg.id
  from_port         = 0
  to_port           = 0
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow all outbound traffic for the bastion host"
  lifecycle {
    ignore_changes = all
  }
}


