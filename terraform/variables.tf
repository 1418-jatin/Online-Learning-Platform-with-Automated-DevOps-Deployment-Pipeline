variable "aws_region" {
  description = "AWS region. MUST be the region where the AMI exists."
  type        = string
  default     = "us-east-2"
}

variable "vpc_name" {
  type    = string
  default = "PRT-VPC"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "subnet_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "ami_id" {
  type    = string
  default = "ami-020ba0ae8c230ae28"
}

variable "instance_type" {
  type    = string
  default = "c7i-flex.large"
}

variable "volume_size" {
  description = "Root volume size in GB for every instance"
  type        = number
  default     = 30
}

variable "app_server_count" {
  type    = number
  default = 2
}

variable "key_name" {
  description = "Existing EC2 key pair name (needed to SSH into the servers)"
  type        = string
  default     = "ohio"
}

variable "admin_cidr" {
  description = "CIDR allowed to SSH into the servers. Change to your own IP (x.x.x.x/32) for better security."
  type        = string
  default     = "0.0.0.0/0"
}

variable "app_ingress_ports" {
  description = "Ports of the application open to users (HTTP, HTTPS, plus any app port such as 8080)"
  type        = list(number)
  default     = [80, 443, 8080]
}

variable "db_port" {
  description = "Database port (3306 = MySQL, 5432 = PostgreSQL)"
  type        = number
  default     = 3306
}
