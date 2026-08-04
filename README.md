# DCJewelry AWS Infrastructure

Terraform configuration for deploying the DCJewelry application infrastructure on AWS.

## Architecture

```text
Internet
   |
Frontend EC2 (public subnet)
   |
Backend EC2 (private subnet)
   |
RDS MySQL (private subnet)
```

The configuration creates:

- A VPC with public and private subnets across two Availability Zones
- An Internet Gateway for public subnets
- A NAT Gateway for private subnet outbound access
- Public and private security groups
- A frontend EC2 instance with an Elastic IP
- A backend EC2 instance in a private subnet
- A private MySQL RDS instance
- An EC2 key pair from `keypair/key.pub`

## Directory structure

```text
.
├── main.tf
├── variable.tf
├── terraform.tfvars
├── output.tf
├── keypair/
└── modules/
    ├── networking/
    ├── security/
    ├── compute/
    └── database/
```

## Requirements

- Terraform 1.5+
- AWS CLI configured with credentials
- An AWS account with permission to create VPC, EC2, RDS, NAT Gateway and security group resources
- An SSH public key at `keypair/key.pub`

## Configuration

Do not commit database credentials. Provide them through environment variables or a local tfvars file:

```powershell
$env:TF_VAR_db_username = "admin"
$env:TF_VAR_db_password = "replace-with-a-strong-password"
```

Review `terraform.tfvars` before deployment, especially the AWS region, Availability Zones, AMI ID and instance type.

## Deploy

```powershell
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

To remove the infrastructure:

```powershell
terraform destroy
```

The RDS instance is currently configured with `skip_final_snapshot = true`, which is suitable for a lab environment but should be changed before production use.

## Outputs

After applying, Terraform displays the frontend public IP and private IP:

```powershell
terraform output
```

The RDS instance is private and should be accessed by the backend through its endpoint. It is not publicly accessible.

## Security notes

- Keep `keypair/key` and all database passwords private.
- SSH is currently open to `0.0.0.0/0` in the public security group. Restrict port 22 to your own IP before production deployment.
- RDS port 3306 is restricted to the private security group.
- Use a remote encrypted Terraform backend and state locking for team or production environments.
