provider "aws" {
    access_key = var.ACCESS_KEY
    secret_key = var.SECRET_KEY
    region = var.REGION

    default_tags {
      tags = {
        Project = var.PROJECT
        Environment = var.ENVIORNMENT
      }
  }
}