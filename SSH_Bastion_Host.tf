### Bastion instance ###
resource "aws_instance" "bastion" {
  ami                         = var.bastion_ami
  instance_type               = var.bastion_instance_type
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  subnet_id                   = aws_subnet.public_subnet[1].id
  associate_public_ip_address = true
  key_name                    = aws_key_pair.key.key_name
  tags = {
    Name = "bastion"
  }
}

### SSH CONFIGURATION ###
resource "aws_key_pair" "key" {
  key_name   = "ssh-key"
  public_key = file(var.ssh_public_key_location)
}

# setup an ssh configuration
resource "local_file" "ssh_config" {
  filename = "/home/${var.local_user}/.ssh/config"
  content = <<EOF
    # Bastion host configuration
    Host bastion
      HostName ${aws_instance.bastion.public_ip}
      User ${var.bastion_host_user}
      IdentityFile ${abspath(path.module)}/../key/ssh-key
      ForwardAgent yes

    # Master nodes configuration
    ${join("\n", [for i, instance in aws_instance.master : <<EOF
      Host master-${i + 1}
        HostName ${instance.private_ip}
        User ${var.instance_user}
        IdentityFile ${abspath(path.module)}/../key/ssh-key
        ProxyJump bastion
    EOF
  ])}
  EOF
}