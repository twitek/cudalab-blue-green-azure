#!/bin/bash
echo "
##############################################################################################################
#  _                         
# |_) _  __ __ _  _     _| _ 
# |_)(_| |  | (_|(_ |_|(_|(_|
#
# Deployment of CUDALAB EU configuration in Microsoft Azure using Terraform and Ansible
#
##############################################################################################################
"

# Stop running when command returns error
set -e

#SECRET="/ssh/secrets.tfvars"
STATE="terraform.tfstate"
PLAN="terraform.plan"
ANSIBLEWEBINVENTORY="ansible-blue/inventory/web"
ANSIBLESQLINVENTORY="ansible-blue/inventory/sql"

TODAY=`date +"%Y-%m-%d"`

set

echo ""
echo "==> Terraform init"
echo ""
terraform init terraform-blue/

echo ""
echo "==> Terraform plan"
echo ""
terraform plan -state="$STATE" --out "$PLAN" -var "ccSecret=$TF_VAR_CCSECRET" -var "password=$TF_VAR_PASSWORD" -var "ssh_key_data=$TF_VAR_SSH_KEY_DATA" terraform-blue/

echo ""
echo "==> Terraform apply"
echo ""
terraform apply "$PLAN"

echo ""
echo "==> Terraform output to Ansible web inventory"
echo ""
terraform output -state="$STATE" web_ansible_inventory > "$ANSIBLEWEBINVENTORY"

echo ""
echo "==> Terraform output to Ansible sql inventory"
echo ""
terraform output -state="$STATE" sql_ansible_inventory > "$ANSIBLESQLINVENTORY"

echo ""
echo "==> Ansible configuration web server"
echo ""
ansible-playbook ansible-blue/deploy-docker.yml -vvv -i "$ANSIBLEWEBINVENTORY"

echo ""
echo "==> Ansible configuration sql server"
echo ""
ansible-playbook ansible-blue/deploy-docker.yml -vvv -i "$ANSIBLESQLINVENTORY" --extra-vars "db_password=$TF_VAR_DB_PASSWORD"
