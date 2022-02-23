#!/bin/bash

cd ./terraform

terraform destroy -var-file=override.tfvars
rm output.terraform