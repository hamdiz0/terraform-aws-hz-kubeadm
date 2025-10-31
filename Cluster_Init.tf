locals {
  k8s_api = var.use_internal_lb ? aws_lb.internal_lb[0].dns_name : aws_instance.master[0].private_ip
}

# Initilize the cluster with one of the masters
resource "null_resource" "initilize_cluster" {
  # connect to the instance via ssh
  connection {
    type         = "ssh"
    user         = var.instance_user
    private_key  = file(var.ssh_private_key_location)
    host         = aws_instance.master[0].private_ip
    bastion_host = aws_instance.bastion.public_ip
    bastion_user = var.bastion_host_user
  }

  # copy the init script to the instance
  provisioner "file" {
    source      = "${path.module}/scripts/cluster_init.sh"
    destination = "/home/${var.instance_user}/cluster_init.sh"
  }

  # execute the script
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/${var.instance_user}/cluster_init.sh",
      "sudo bash /home/${var.instance_user}/cluster_init.sh ${local.k8s_api} ${var.instance_user}"
    ]
  }

  # retrieve the join commands
  provisioner "local-exec" {
    command = <<EOT
      ssh-keyscan ${aws_instance.bastion.public_ip} >> \
        /home/${var.local_user}/.ssh/known_hosts

      ssh-keyscan ${aws_instance.master[0].private_ip} >> \
        /home/${var.local_user}/.ssh/known_hosts
        
      scp -o StrictHostKeyChecking=no \
        master-1:/home/${var.instance_user}/worker_join_script.sh \
        ${path.module}/scripts/worker_join_script.sh

      scp -o StrictHostKeyChecking=no \
        master-1:/home/${var.instance_user}/master_join_script.sh \
        ${path.module}/scripts/master_join_script.sh    
    EOT
  }
  depends_on = [local_file.ssh_config]
}

# Execute the cluster_add_ons.sh script
resource "null_resource" "cluster_add_ons" {
  connection {
    type         = "ssh"
    user         = var.instance_user
    private_key  = file(var.ssh_private_key_location)
    host         = aws_instance.master[0].private_ip
    bastion_host = aws_instance.bastion.public_ip
    bastion_user = var.bastion_host_user
  }
  provisioner "file" {
    source      = "${path.module}/scripts/cluster_add_ons.sh"
    destination = "/home/${var.instance_user}/cluster_add_ons.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/${var.instance_user}/cluster_add_ons.sh",
      "sudo bash /home/${var.instance_user}/cluster_add_ons.sh ${var.min_worker_number} ${var.control_plane_number}",
      "kubectl get pods -A"
    ]
  }
  depends_on = [aws_autoscaling_group.worker_autoscaling_group, null_resource.join_masters]
}
