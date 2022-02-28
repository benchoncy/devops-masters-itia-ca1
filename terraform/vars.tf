variable "ACCESS_KEY" {}
variable "SECRET_KEY" {}
variable "PROJECT" {}
variable "VERSION" {}
variable "ENVIORNMENT" {}

variable "AMI_OWNERS" {
  type = list(string)
  default = ["self"]
}

variable "REGION" {
  default = "eu-west-1"
}

variable "KEY_NAME" {
  default = "TU_Dublin"
}

variable "INSTANCE_TYPE" {
  default = "t2.micro"
}

variable "SUBNET_PREFIX_CIDR" {
  default = "10.0.0.0/24"
}

variable "ALLOWED_SSH_SOURCES" {
  type = list(string)
  default = ["0.0.0.0/0"]
}

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

variable "LOG_RETENTION_DAYS" {
  default = 30
}