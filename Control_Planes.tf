# create control plane nodes based on the master_number value
resource "aws_instance" "master" {
  count                       = var.control_plane_number
  ami                         = var.k8s_ami_id
  instance_type               = var.master_instance_type
  vpc_security_group_ids      = [aws_security_group.master_sg.id]
  # Distribute instances evenly across the 3 private subnets (round-robin)
  subnet_id = aws_subnet.private_subnet[count.index % 3].id
  associate_public_ip_address = false
  key_name                    = aws_key_pair.key.key_name
  iam_instance_profile        = aws_iam_instance_profile.master_instance_profile.name
  user_data = base64encode(<<-EOF
    #!/bin/bash
    HOST_TYPE=master-${aws_subnet.private_subnet[count.index % 3].availability_zone}
    ${file("${path.module}/scripts/k8s_node_setup.sh")}
    EOF
  )
  # ignore name tagging as the instance tags it self
  lifecycle {
    ignore_changes = [tags["Name"]]
  }
  tags = {
    "kubernetes.io/cluster/kubernetes" = "owned"
  }
  depends_on = [module.hz-nat , aws_nat_gateway.nat_gateway]
}

# Join the other master nodes to the cluster
resource "null_resource" "join_masters" {
  # connect to the instance via ssh
  count = var.control_plane_number - 1
  connection {
    type         = "ssh"
    user         = var.instance_user
    private_key  = file(var.ssh_private_key_location)
    host         = aws_instance.master[count.index + 1].private_ip
    bastion_host = aws_instance.bastion.public_ip
    bastion_user = var.bastion_host_user
  }

  # copy the script to the instance
  provisioner "file" {
    source      = "${path.module}/scripts/master_join_script.sh"
    destination = "/home/${var.instance_user}/master_join_script.sh"
  }

  # execute the script
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/${var.instance_user}/master_join_script.sh",
      "sudo bash /home/${var.instance_user}/master_join_script.sh"
    ]
  }
  depends_on = [null_resource.initilize_cluster]
}