# ======================= Networking =======================
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_name
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.vpc_name}-public-subnet"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.vpc_name}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.vpc_name}-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ======================= Security Groups =======================

# ---- Application servers ----
resource "aws_security_group" "app" {
  name        = "${var.vpc_name}-app-sg"
  description = "Application servers"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.vpc_name}-app-sg"
  }
}

# Users reach the application (HTTP / HTTPS / app port)
resource "aws_vpc_security_group_ingress_rule" "app_users" {
  for_each = toset([for p in var.app_ingress_ports : tostring(p)])

  security_group_id = aws_security_group.app.id
  description       = "Application access on port ${each.value}"
  ip_protocol       = "tcp"
  from_port         = tonumber(each.value)
  to_port           = tonumber(each.value)
  cidr_ipv4         = "0.0.0.0/0"
}

# Admin SSH
resource "aws_vpc_security_group_ingress_rule" "app_ssh" {
  security_group_id = aws_security_group.app.id
  description       = "SSH from admin"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = var.admin_cidr
}

# App servers can talk to each other on any port
resource "aws_vpc_security_group_ingress_rule" "app_self" {
  security_group_id            = aws_security_group.app.id
  description                  = "All traffic between application servers"
  ip_protocol                  = "-1"
  referenced_security_group_id = aws_security_group.app.id
}

resource "aws_vpc_security_group_egress_rule" "app_all_out" {
  security_group_id = aws_security_group.app.id
  description       = "All outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# ---- Database server ----
resource "aws_security_group" "db" {
  name        = "${var.vpc_name}-db-sg"
  description = "Database server"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.vpc_name}-db-sg"
  }
}

# Only the application servers may reach the database port
resource "aws_vpc_security_group_ingress_rule" "db_from_app" {
  security_group_id            = aws_security_group.db.id
  description                  = "Database port from application servers"
  ip_protocol                  = "tcp"
  from_port                    = var.db_port
  to_port                      = var.db_port
  referenced_security_group_id = aws_security_group.app.id
}

# Ping from application servers (troubleshooting)
resource "aws_vpc_security_group_ingress_rule" "db_icmp_from_app" {
  security_group_id            = aws_security_group.db.id
  description                  = "ICMP from application servers"
  ip_protocol                  = "icmp"
  from_port                    = -1
  to_port                      = -1
  referenced_security_group_id = aws_security_group.app.id
}

# Admin SSH
resource "aws_vpc_security_group_ingress_rule" "db_ssh" {
  security_group_id = aws_security_group.db.id
  description       = "SSH from admin"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = var.admin_cidr
}

resource "aws_vpc_security_group_egress_rule" "db_all_out" {
  security_group_id = aws_security_group.db.id
  description       = "All outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# ======================= EC2 Instances =======================

# 2 Application servers
resource "aws_instance" "app" {
  count = var.app_server_count

  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.app.id]
  associate_public_ip_address = true
  key_name                    = var.key_name
  user_data                   = file("${path.module}/user-data.sh")

  root_block_device {
    volume_size = var.volume_size
    volume_type = "gp3"
  }

  tags = {
    Name = "PRT-App-Server-${count.index + 1}"
    Role = "application"
  }

  depends_on = [aws_internet_gateway.igw]
}

# 1 Database server
resource "aws_instance" "db" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.db.id]
  associate_public_ip_address = true
  key_name                    = var.key_name
  user_data                   = file("${path.module}/user-data.sh")

  root_block_device {
    volume_size = var.volume_size
    volume_type = "gp3"
  }

  tags = {
    Name = "PRT-DB-Server"
    Role = "database"
  }

  depends_on = [aws_internet_gateway.igw]
}
