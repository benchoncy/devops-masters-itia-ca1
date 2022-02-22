#!/bin/bash

cd ./terraform

terraform init
terraform plan -out output.terraform
terraform apply output.terraform
rm output.terraform