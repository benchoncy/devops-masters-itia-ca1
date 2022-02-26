variable "ACCESS_KEY" {}
variable "SECRET_KEY" {}
variable "PROJECT" {}
variable "VERSION" {}

variable "AMI_SUFFIX" {
  default = ""
}

variable "REGION" {
  default = "eu-west-1"
}

variable "BASE_AMI" {
  default = "ami-0ec23856b3bad62d3"
}

variable "AMI_USERS" {
  type = list(string)
  default = []
}

variable "AMI_GROUPS" {
  type = list(string)
  default = []
}

variable "INSTANCE_TYPE" {
  default = "t2.micro"
}

variable "SSH_UNAME" {
  default = "ec2-user"
}

variable "HTML_LOCATION" {
  default = "../example_static_website"
}

source "amazon-ebs" "immutable-image" {
  access_key = var.ACCESS_KEY
  secret_key = var.SECRET_KEY
  region = var.REGION
  source_ami = var.BASE_AMI
  instance_type = var.INSTANCE_TYPE
  communicator = "ssh"
  ssh_username = var.SSH_UNAME
  ami_name =  "${var.PROJECT}_${var.VERSION}${var.AMI_SUFFIX}"
  ami_users = var.AMI_USERS
  ami_groups = var.AMI_GROUPS
  tags = {
    Project = var.PROJECT
    Version = var.VERSION
  }
}

build {
  sources = ["sources.amazon-ebs.immutable-image"]

  provisioner "ansible" {
    playbook_file = "./playbook/main.yml"
    extra_arguments = [ "--extra-vars", "html_source=${var.HTML_LOCATION}" ]
  }
}