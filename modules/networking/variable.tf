variable "config" {
  description = "VPC and subnet configuration."
  type = object({
    cidr_block         = string
    availability_zones = list(string)
    public_subnet_ips  = list(string)
    private_subnet_ips = list(string)
  })
}
