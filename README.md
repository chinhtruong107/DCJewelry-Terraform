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
    |   +-- PMM Server EC2
    |   |   `-- Receives HTTPS :443 from Control Node and Backend only
    |   `-- RDS DB Subnet Group
    |
    `-- Private subnet 2: 10.0.20.0/24 (AZ 2)
        |
        +-- Backend EC2
        |   `-- Receives application HTTP :8002 from Frontend only
        |
        `-- RDS DB Subnet Group
            `-- MySQL RDS (private and storage-encrypted)
                `-- Receives MySQL :3306 from Backend only

```

### Traffic flows

```text
Internet user -> Frontend Elastic IP :80/:443 -> Frontend EC2
                                             -> Backend EC2 private IP :8002
                                             -> MySQL RDS :3306

Administrator or GitHub Actions -> Control Node Elastic IP :22
                                 -> SSH / Ansible -> Frontend, Backend and PMM Server

Administrator workstation -> SSH tunnel -> Control Node -> PMM Server :443
PMM Client on PMM Server -> MySQL RDS :3306
```

| Subnet | CIDR | Availability Zone | Current resources |
| --- | --- | --- | --- |
| Public subnet 1 | `10.0.1.0/24` | AZ 1 | NAT Gateway, Frontend EC2, Control Node EC2 |
| Public subnet 2 | `10.0.2.0/24` | AZ 2 | Reserved for future ALB/HA use |
| Private subnet 1 | `10.0.10.0/24` | AZ 1 | PMM Server, RDS DB subnet group |
| Private subnet 2 | `10.0.20.0/24` | AZ 2 | Backend EC2, RDS DB subnet group |

RDS uses both private subnets because an RDS DB subnet group must span at least two Availability Zones. With `db_multi_az = false`, only one database instance runs, but AWS still needs the two-subnet group.

The configuration creates:

- A VPC with 2 public and 2 private subnets across two Availability Zones
- An Internet Gateway for public subnets and a NAT Gateway for private subnet outbound access
- A frontend EC2 instance with an Elastic IP
- A backend EC2 instance in a private subnet
- A Control Node EC2 with an Elastic IP for SSH, Ansible, and CD access
- A private, encrypted MySQL RDS instance
- A private PMM Server for MySQL and host monitoring, with persistent Docker storage
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
    `-- monitoring/
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

Configuration is grouped by responsibility in `terraform.tfvars`: `networking`, `security`, `compute`, `database`, and `monitoring`. For example, RDS sizing and storage settings are under `database.instance_class`, `database.allocated_storage`, `database.storage_type`, `database.engine_version`, and `database.multi_az`.

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

## PMM monitoring

PMM Server is deliberately private in `10.0.10.0/24`. It has no public IP; SSH administration is permitted only from Control Node, and HTTPS is permitted only from Control Node for the SSH tunnel. The PMM Client runs on this PMM bastion and connects privately to RDS on port `3306`.

### Query Analytics evidence

The screenshot below shows PMM Query Analytics collecting query digests from the private DCJewelry RDS instance.

![PMM Query Analytics showing DCJewelry application queries](images/image1.png)

The PMM service is named `dcjewelry-rds`; use the `dcjewelry` schema filter and a recent time range in **Query Analytics → Stored metrics** to focus on application traffic.

### 1. Deploy the monitoring infrastructure

The `monitoring` section in `terraform.tfvars` defaults to a `t3.medium` instance with a 30 GiB encrypted root disk. This is a practical PMM lab baseline; it stores its data in a Docker volume and retains data for 14 days.

```powershell
terraform fmt -recursive
terraform validate
terraform plan -out=tfplan --var-file "terraform.tfvars"
terraform apply tfplan
```

Retrieve the addresses needed below:

```powershell
terraform output control_node_public_ip
terraform output backend_private_ip
terraform output pmm_private_ip
terraform output rds_endpoint
```

### 2. Open the PMM UI securely through Control Node

Run this command from your Windows workstation and keep the terminal open. Replace the key path if yours differs.

```powershell
$controlNode = terraform output -raw control_node_public_ip
$pmmPrivateIp = terraform output -raw pmm_private_ip
ssh -i .\keypair\key -N -L "8443:${pmmPrivateIp}:443" "ubuntu@$controlNode"
```

Open `https://localhost:8443`. PMM uses a self-signed certificate initially, so the browser warning is expected. Sign in as `admin` / `admin`, then change that password immediately. No PMM dashboard port is exposed to the Internet.

### 3. Install and register PMM Client on the PMM bastion

First connect to the Control Node from the workstation. Then, from the Control Node, connect to the PMM private IP with the Terraform private key:

```powershell
$controlNode = terraform output -raw control_node_public_ip
ssh -i /home/ubuntu/.ssh/key ubuntu@PMM_PRIVATE_IP
```

On the PMM bastion, install PMM Client for Ubuntu/Debian:

```bash
wget https://repo.percona.com/apt/percona-release_latest.generic_all.deb
sudo dpkg -i percona-release_latest.generic_all.deb
sudo percona-release enable pmm3-client
sudo apt update
sudo apt install -y pmm-client
```

In the PMM UI, create a service-account token at **Users and access → Service accounts**. On Backend, register the PMM Client (use the PMM private IP, not a public address):

```bash
sudo pmm-admin config --server-insecure-tls \
  --server-url=https://service_token:REPLACE_WITH_GLSA_TOKEN@PMM_PRIVATE_IP:443 \
  PMM_PRIVATE_IP generic dcjewelry-pmm-bastion
```

Create a dedicated database account using an RDS master/admin connection. Choose and store a strong password outside Git:

```sql
CREATE USER 'pmm'@'%' IDENTIFIED BY 'REPLACE_WITH_A_STRONG_PASSWORD';
GRANT SELECT, PROCESS, REPLICATION CLIENT, RELOAD ON *.* TO 'pmm'@'%';
FLUSH PRIVILEGES;
```

Then, still on the PMM bastion, add RDS MySQL. Replace all placeholders with Terraform outputs and the PMM database password:

```bash
sudo pmm-admin add mysql \
  --username=pmm \
  --password='REPLACE_WITH_PMM_DB_PASSWORD' \
  --host=RDS_ENDPOINT \
  --port=3306 \
  --service-name=dcjewelry-rds \
  --query-source=perfschema

sudo pmm-admin status
```

### 4. Enable Query Analytics for RDS MySQL

The Terraform database parameter group enables `performance_schema=1`. RDS must be rebooted once after applying this pending-reboot setting. Then enable statement history with an RDS admin connection:

```sql
UPDATE performance_schema.setup_consumers
SET ENABLED = 'YES'
WHERE NAME = 'events_statements_history_long';
```

The DCJewelry Laravel backend uses PDO emulated prepares so RDS exposes application SQL text to PMM. Re-check the consumer after an RDS reboot because this runtime setting can reset.

For a production RDS connection, use the Amazon RDS CA bundle and add `--tls --tls-ca=/path/to/rds-ca-bundle.pem`; `--server-insecure-tls` is only for the PMM Server's initial self-signed certificate in this lab.

## Security notes

- Keep `keypair/key` and all database passwords private.
- `terraform.tfvars`, `backend.hcl`, and Terraform plan files are ignored by Git. Do not force-add them.
- SSH is permitted only from `control_node_cidr` to the Control Node, then from the Control Node to Frontend, Backend, and PMM Server.
- RDS port 3306 is restricted to the Backend and PMM security groups.
- Use the encrypted S3 remote backend and state locking for all shared environments.
- The current NAT Gateway is in AZ 1 only. This is acceptable for a lab, but production should use one NAT Gateway per AZ.
- `skip_final_snapshot = true` is suitable for a lab only; change it before production so RDS has a final snapshot on deletion.
