# Ops Manager Demo via Terraform

This repository contains all relevant files for automatically deploy a MongoDB Ops Manager including configured Backup.
In addition, you can specify the number of agent nodes which will be available for a MongoDB deployment.  
**This is only for demo purposes only and IS NOT suitable for production deployment!**

# Required Tools

This repository is utilizing [Terraform](https://www.terraform.io/) which is an open-source infrastructure as code software tool.
Terraform will automate the deployment of infrastructure components, copy required files from this folder and execute installation scripts according to the Ops Manager [manual](https://docs.opsmanager.mongodb.com/current/tutorial/install-simple-test-deployment/).
In addition, a python application is used for configuration of the backup capabilities via Ops Manager APIs.

# How to use

1. Install Terraform
2. provide aws credentials e.g. in /.aws/credentials
3. Run `terraform init`
4. Install python package "requests"
5. Provide relevant parameters within the file "terraform.tfvars"
6. Run `terraform apply`
7. Use output URL to access Ops Manager UI

---
