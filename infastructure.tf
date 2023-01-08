terraform { 
backend "s3" { 
    bucket = "kthamel-gitlab-tfstate" 
    key = "terraform.tfstate" 
    region = "us-east-1" 
    }

required_providers {
    aws = {
    source = "hashicorp/aws"
    version = "~> 4.24.0"
        }
    }
}
provider "aws" {
    region = "us-east-1"
}

resource "aws_vpc" "iac-vpc" {
    cidr_block = "172.31.0.0/16"
    instance_tenancy = "default"
    enable_dns_hostnames = "true"
    enable_dns_support = "true"
    
    tags = {
    Name = "iac-vpc"
    }
}

resource "aws_instance" "iac-demo-ec2" {
    ami = "ami-090fa75af13c156b4"
    instance_type = "t2.micro"
    associate_public_ip_address = true
    subnet_id = aws_subnet.iac-subnet.id
    security_groups = [aws_security_group.iac-sg.id]

    tags = {
    Name = "iac-demo-ec2"
    }
}

resource "aws_subnet" "iac-subnet" {
    vpc_id = aws_vpc.iac-vpc.id
    cidr_block = "172.31.1.0/24"
    
    tags = {
    Name = "iac-subnet"
    }
}

resource "aws_internet_gateway" "iac-igw" {
    vpc_id = aws_vpc.iac-vpc.id
    tags = {
    Name = "iac-igw"
    }
}

resource "aws_route_table" "iac-route-table" {
    vpc_id = aws_vpc.iac-vpc.id
    route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.iac-igw.id
    }
}

resource "aws_security_group" "iac-sg" {
    name = "iac-sg"
    description = "Allow TLS inbound traffic"
    vpc_id = aws_vpc.iac-vpc.id
    ingress {
    description = "For ssh"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
    Name = "allow_traffic"
    }
}

resource "aws_main_route_table_association" "iac-rt-association" {
    vpc_id = aws_vpc.iac-vpc.id
    route_table_id = aws_route_table.iac-route-table.id
}