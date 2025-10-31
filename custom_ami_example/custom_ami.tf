module "ami-gen" {
  source  = "hamdiz0/hz-ami-gen/aws"

  public_ssh_key_path = "../key/ssh-key.pub"
  private_ssh_key_path = "../key/ssh-key"
  script_path = "./ami_setup.sh"

  public_subnet_id = "subnet-0372a2f746c7ea032"
  base_ami = "ami-0359cb6c0c97c6607" #ami-0a411b25a0dc707f3
  ami_default_user = "admin" #ec2-user
  custom_ami_name = "k8s_ami"

  delete_resources = true
}
