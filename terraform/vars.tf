variable "ACCESS_KEY" {}
variable "SECRET_KEY" {}
variable "PROJECT" {}
variable "ENVIORNMENT" {}

variable "REGION" {
  default = "eu-west-1"
}

variable "INSTANCE_TYPE" {
  default = "t2.micro"
}

variable "SUBNET_PREFIX_CIDR" {
  default = "10.0.0.0/24"
}

variable "AMI" {}

variable "MAX_INSTANCES" {
  default = 6
}

variable "MIN_INSTANCES" {
  default = 2
}

variable "TARGET_INSTANCES" {
  default = 3
}

variable "HEALTH_CHECK_GRACE_PERIOD" {
  default = 300
}