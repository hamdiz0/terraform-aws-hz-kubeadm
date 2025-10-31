# create a template file for the worker nodes
data "template_file" "worker_user_data" {
  template   = <<-EOF
  #!/bin/bash
  HOST_TYPE=worker
  $${file("./scripts/k8s_node_setup.sh")}
  $${file("./scripts/worker_join_script.sh")}
  EOF
  depends_on = [null_resource.initilize_cluster] # make sure the template is only generated after the join scripts are retrieved
}

# create a launch template 
resource "aws_launch_template" "worker_template" {
  name_prefix   = "worker_node_launch_template"
  image_id      = var.k8s_ami_id
  instance_type = var.worker_instance_type
  key_name      = aws_key_pair.key.key_name
  user_data     = base64encode(data.template_file.worker_user_data.rendered) # use the template file for the worker nodes

  # associate the worker instance profile
  iam_instance_profile {
    name = aws_iam_instance_profile.worker_instance_profile.name
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.worker_sg.id]
  }
}

# create an auto scaling group
resource "aws_autoscaling_group" "worker_autoscaling_group" {
  name                = "worker_autoscaling_group"
  max_size            = var.max_worker_number
  min_size            = var.min_worker_number
  vpc_zone_identifier = aws_subnet.private_subnet[*].id
  launch_template {
    id      = aws_launch_template.worker_template.id
    version = "$Latest"
  }
  tag {
    key = "kubernetes.io/cluster/kubernetes"
    value = "owned"
    propagate_at_launch = true
  }
}
