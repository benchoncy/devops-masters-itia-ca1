#!/bin/bash

cd ./terraform

terraform init
terraform plan -out output.terraform -var-file=override.tfvars
terraform apply output.terraform