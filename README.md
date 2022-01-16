# Simple Terraform Applications for Azure

## Contents

* [Azure VM Instance](https://github.com/aytemuryakup/terraform/tree/main/az_vm "Azure VM Instance")
* [Azure Multi VM Instance](https://github.com/aytemuryakup/terraform/tree/main/az_multi_vm "Azure VM Instance")

### General Usage

**Terraform Plan**
```
$ terraform init
$ terraform plan --out tfplan
$ terraform apply tfplan
```

**Terraform Destroy**
```
$ terraform destroy --auto-approve 
```
