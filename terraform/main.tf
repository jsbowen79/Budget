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
  region = "us-east-1"
}

# SSH Key (public part only)
resource "aws_key_pair" "budget_key" {
  key_name   = "budget-key"
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
  ami                         = "ami-0c02fb55956c7d316" # Ubuntu 22.04 in us-east-1
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.budget_key.key_name
  subnet_id                   = aws_subnet.main.id
  vpc_security_group_ids      = [aws_security_group.budget_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "budget-k3s-node"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update -y",
      "curl -sfL https://get.k3s.io | sh -",
      "sudo chmod 644 /etc/rancher/k3s/k3s.yaml"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("../keys/budget_key")
      host        = self.public_ip
    }
  }
}

resource "aws_eip_association" "static_ip_attach" {
  instance_id   = aws_instance.k3s_node.id
  allocation_id = aws_eip.static_ip.id
}

# Output public IP so you can connect
output "instance_public_ip" {
  value = aws_instance.k3s_node.public_ip
}
