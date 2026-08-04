# DCJewelry AWS Infrastructure

Terraform configuration for deploying the DCJewelry application infrastructure on AWS.

## Architecture

```text
Internet ------------------> Frontend EC2 + EIP (public subnet)

Administrator IP ----------> Control Node EC2 + EIP (public subnet)
                                  | SSH / Ansible
                                  +------------------------+
                                  |                        |
                           Frontend EC2            Backend EC2 (private subnet)
                                                            |
                                                            | MySQL 3306
                                                            v
                                                   RDS MySQL (private subnet)
```

The configuration creates:

- A VPC with public and private subnets across two Availability Zones
- An Internet Gateway for public subnets and a NAT Gateway for private subnet outbound access
- A frontend EC2 instance with an Elastic IP
- A backend EC2 instance in a private subnet
- A Control Node EC2 with an Elastic IP for SSH/Ansible access
- A private, encrypted MySQL RDS instance
- Security groups that limit SSH to the Control Node path and MySQL to the backend
- An EC2 key pair from `keypair/key.pub`

## Directory structure

```text
.
|-- main.tf
|-- versions.tf
|-- variable.tf
|-- terraform.tfvars.example
|-- backend.hcl.example
|-- output.tf
|-- keypair/
`-- modules/
    |-- networking/
    |-- security/
    |-- compute/
    `-- database/
```

## Requirements

- Terraform 1.5+
- AWS CLI configured with credentials
- An AWS account with permission to create VPC, EC2, RDS, NAT Gateway and security group resources
- An SSH public key at `keypair/key.pub`
- An existing private S3 bucket for Terraform state

## Configuration

Create your local configuration files from the templates:

```powershell
Copy-Item terraform.tfvars.example terraform.tfvars
Copy-Item backend.hcl.example backend.hcl
```

Edit `terraform.tfvars` before deployment. Set `control_node_cidr` to your own public IP with a `/32` suffix, for example `203.0.113.10/32`.

Set a real RDS password in `db_password`. Keep `terraform.tfvars` local; it is ignored by Git.

Edit `backend.hcl` with the name of the existing S3 bucket used for remote Terraform state. Keep it local too; it is ignored by Git.

RDS sizing and storage settings are editable through `db_instance_class`, `db_allocated_storage`, `db_storage_type`, `db_engine_version`, and `db_multi_az`.

## Deploy

```powershell
terraform init -backend-config backend.hcl
terraform fmt -recursive
terraform validate
terraform plan -out=tfplan --var-file "terraform.tfvars"
terraform apply tfplan
```

To remove the infrastructure:

```powershell
terraform destroy --var-file "terraform.tfvars"
```

The RDS instance uses `skip_final_snapshot = true`, which is suitable for a lab environment but should be changed before production use.

## Outputs

After applying, retrieve public IPs with:

```powershell
terraform output
```

The RDS instance is private and should be accessed only by the backend through its RDS endpoint.

## Security notes

- Keep `keypair/key` and all database passwords private.
- `terraform.tfvars`, `backend.hcl`, and Terraform plan files are ignored by Git. Do not force-add them.
- SSH is permitted only from `control_node_cidr` to the Control Node, then from the Control Node to Frontend and Backend.
- RDS port 3306 is restricted to the backend private security group.
- Use the encrypted S3 remote backend and state locking for all shared environments.
