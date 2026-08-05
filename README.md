# DCJewelry AWS Infrastructure

Terraform configuration for deploying the DCJewelry application infrastructure on AWS.

## Architecture

```text
AWS Region: ap-southeast-1
|
`-- VPC: 10.0.0.0/16
    |
    +-- Internet Gateway
    |
    +-- Public subnet 1: 10.0.1.0/24 (AZ 1)
    |   |
    |   +-- NAT Gateway + Elastic IP
    |   |   `-- Allows private resources to reach the Internet outbound
    |   |
    |   +-- Frontend EC2 + Elastic IP
    |   |   `-- Internet users -> HTTP :80 / HTTPS :443
    |   |
    |   `-- Control Node EC2 + Elastic IP
    |       `-- Administrator / GitHub Actions -> SSH :22
    |           |
    |           +-- SSH / Ansible -> Frontend EC2 :22
    |           `-- SSH / Ansible -> Backend EC2 :22
    |
    +-- Public subnet 2: 10.0.2.0/24 (AZ 2)
    |   `-- Reserved for a future Load Balancer or public HA resources
    |
    +-- Private subnet 1: 10.0.10.0/24 (AZ 1)
    |   `-- RDS DB Subnet Group
    |
    `-- Private subnet 2: 10.0.20.0/24 (AZ 2)
        |
        +-- Backend EC2
        |   `-- Receives HTTP :80 from Frontend only
        |
        `-- RDS DB Subnet Group
            `-- MySQL RDS (private and storage-encrypted)
                `-- Receives MySQL :3306 from Backend only
```

### Traffic flows

```text
Internet user -> Frontend Elastic IP :80/:443 -> Frontend EC2
                                             -> Backend EC2 private IP :80
                                             -> MySQL RDS :3306

Administrator or GitHub Actions -> Control Node Elastic IP :22
                                 -> SSH / Ansible -> Frontend and Backend
```

| Subnet | CIDR | Availability Zone | Current resources |
| --- | --- | --- | --- |
| Public subnet 1 | `10.0.1.0/24` | AZ 1 | NAT Gateway, Frontend EC2, Control Node EC2 |
| Public subnet 2 | `10.0.2.0/24` | AZ 2 | Reserved for future ALB/HA use |
| Private subnet 1 | `10.0.10.0/24` | AZ 1 | RDS DB subnet group |
| Private subnet 2 | `10.0.20.0/24` | AZ 2 | Backend EC2, RDS DB subnet group |

RDS uses both private subnets because an RDS DB subnet group must span at least two Availability Zones. With `db_multi_az = false`, only one database instance runs, but AWS still needs the two-subnet group.

The configuration creates:

- A VPC with 2 public and 2 private subnets across two Availability Zones
- An Internet Gateway for public subnets and a NAT Gateway for private subnet outbound access
- A frontend EC2 instance with an Elastic IP
- A backend EC2 instance in a private subnet
- A Control Node EC2 with an Elastic IP for SSH, Ansible, and CD access
- A private, encrypted MySQL RDS instance
- Security groups that limit Frontend -> Backend -> RDS traffic
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

Edit `terraform.tfvars` before deployment. `control_node_cidr` controls SSH access to the Control Node. For an administrator workstation, use one public IP with a `/32` suffix, for example `203.0.113.10/32`. Direct SSH from GitHub-hosted Actions may require a wider CIDR because runner IPs change; use SSH keys only and disable password login in that case.

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
- The current NAT Gateway is in AZ 1 only. This is acceptable for a lab, but production should use one NAT Gateway per AZ.
- `skip_final_snapshot = true` is suitable for a lab only; change it before production so RDS has a final snapshot on deletion.
