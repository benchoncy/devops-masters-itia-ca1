# DevOps Masters - IT Infrastructure &amp; Automation - CA1

This repository holds a proof of concept web application deployment as part of a continuous assesment.

Allows creation of an example AMI image and deployment of said image in a virtual private cloud in a load balanced autoscaling group, spread across multiple availability zones. A preset CloudWatch dashboard is created as part of the deployment.

## Build

### Requirements

- Terraform
- Ansible
- Packer
- AWS account

### AMI build

Packer and Ansible is used to create an example AMI image running a hello world webpage served by Apache.

To run packer, you can use:
```shell
packer_build.sh
```
This method assumes you have a `*.auto.pkr.hcl` file in the `/packer_build/` directory with all necessary variables.

#### Required variables
| Variables | Note |
|---|---|
| `ACCESS_KEY` | AWS access key |
| `SECERET_KEY` | AWS secret key |
| `PROJECT` | unique project name |
| `VERSION` | unique version |

#### Additional variables

| Variables | Default | Note |
|---|---|---|
| `AMI_SUFFIX` | `""` | suffix added to AMI name |
| `REGION` | `eu-west-1` | AWS region to build and save AMI image |
| `BASE_AMI` | `ami-0ec23856b3bad62d3` | AMI to use as base image, defaults to RHEL8 |
| `AMI_USERS` | `[]` | IAM users to be granted access to the image |
| `AMI_GROUPS` | `[]` | IAM groups to be granted access to the image |
| `INSTANCE_TYPE` | `t2.micro` | Instance type to use during build |
| `SSH_NAME` | `ec2-user` | SSH user to use during build |
| `HTML_LOCATION` | `../example_static_website` | Location of HTML files to copy to the image |
| `PLAYBOOK_LOCATION` | `./playbook/main.yml` | Location of ansible playbook to run |


### Terraform deployment

To deploy the web app on AWS, run:
```shell
terraform.sh
```
This method assumes you have an `override.tfvars` file in the `/terraform/` directory with all necessary variables.

#### Required variables
| Variables | Note |
|---|---|
| `ACCESS_KEY` | AWS access key |
| `SECERET_KEY` | AWS secret key |
| `PROJECT` | unique project name (should be the same as the desired AMI) |
| `VERSION` | unique version (should be the same as the desired AMI) |
| `ENVIORNMENT` | unique enviornment name for this project, e.g. 'Production' |

#### Additional variables

| Variables | Default | Note |
|---|---|---|
| `AMI_OWNERS` | `["self"]` | Owners of AMIs to search for deployment AMI |
| `REGION` | `eu-west-1` | AWS region to deploy |
| `KEY_NAME` | `TU_Dublin` | Key to add to instances for break-glass feature |
| `INSTANCE_TYPE` | `t2.micro` | Instance type to use for deployment |
| `SUBNET_PREFIX_CIDR` | `10.0.0.0/24` | CIDR prefix to use when creating subnets |
| `ALLOWED_SSH_SOURCES` | `["0.0.0.0/0"]` | Source CIDRs allowed to SSH to instances |
| `MAX_INSTANCES` | `6` | Max allowed instances at one time |
| `MIN_INSTANCES` | `2` | Min allowed instances at one time |
| `TARGET_INSTANCES` | `3` | Target number of instances at deployment time |
| `HEALTH_CHECK_GRACE_PERIOD` | `300` | Number of seconds between health checks for autoscaling |

### Teardown

To destroy the deployed resources, run:
```shell
terraform_destroy.sh
```

Additionally, the build AMI image and Snapshot should be deregistered/deleted from AWS under `EC2 > AMIs` and `EC2 > Snapshots` respectively.

> Note: This repo is part of a university assignment, assume all decisions made for experimentation and learning and not for long-term maintainability.
