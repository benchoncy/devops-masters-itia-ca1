variable "ACCESS_KEY" {}
variable "SECRET_KEY" {}
variable "PROJECT" {}
variable "DEPLOYMENT" {}

variable "REGION" {
  default = "eu-west-1"
}

variable "INSTANCE_TYPE" {
  default = "t2.micro"
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