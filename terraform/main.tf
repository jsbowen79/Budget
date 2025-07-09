terraform {
  required_version = ">= 1.0"

  backend "remote" {
    organization = "jsbowen79"   
    workspaces {
      name = "budget-app-infra"
    }
  }
}

provider "aws" {
}

data "aws_eip" "static_ip" {
  public_ip = "52.200.76.169"
}


# SSH Key (public part only)
resource "aws_key_pair" "budget_key" {
  key_name   = "budget_key"
public_key = file("${path.module}/budget_key.pub")

}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "budget-vpc"
  }
}

# Create Subnet
resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "budget-subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "budget-igw"
  }
}

# Route Table
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "budget-rt"
  }
}

# Associate Route Table with Subnet
resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

# Security Group to allow SSH and HTTP
resource "aws_security_group" "budget_sg" {
  name        = "budget-sg"
  description = "Allow SSH and HTTP access"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

ingress {
    description = "SSH"
    from_port   = 30080
    to_port     = 30080
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    description = "HTTP"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "budget-sg"
  }
}

# Launch EC2 instance
resource "aws_instance" "k3s_node" {
  ami                         = "ami-08c40ec9ead489470" # Ubuntu 22.04 in us-east-1
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.budget_key.key_name
  subnet_id                   = aws_subnet.main.id
  private_ip                  = "10.0.1.10"
  vpc_security_group_ids      = [aws_security_group.budget_sg.id]
  associate_public_ip_address = true

  user_data = file("${path.module}/user-data/k3s-node.sh")

  tags = {
    Name = "cloudifyrides-k3s-node"
  }
}

resource "aws_instance" "nginx_proxy" {
  ami                    = "ami-08c40ec9ead489470"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.main.id
  key_name               = aws_key_pair.budget_key.key_name
  vpc_security_group_ids = [aws_security_group.budget_sg.id]

  user_data = file("${path.module}/user-data/nginx-proxy.sh")

  tags = {
    Name = "nginx-proxy"
  }
}


resource "aws_eip_association" "static_ip_attach" {
  instance_id   = aws_instance.nginx_proxy.id
  allocation_id = data.aws_eip.static_ip.id
}

# Output public IP so you can connect
output "instance_public_ip" {
  value = aws_instance.nginx_proxy.public_ip
}
