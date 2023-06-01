resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name        = "project-vpc"
  }
}

resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "project-vpc-igw"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.vpc.id
 
  cidr_block              = var.cidr_block_subnet_public
  availability_zone       = var.az
  map_public_ip_on_launch = true

  tags = {
    Name        = "project-vpc-public-subnet"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.vpc.id

  cidr_block              = var.cidr_block_subnet_private
  availability_zone       = var.az

  tags = {
    Name        = "project-vpc-private-subnet"
  }
}


resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id
  route{
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ig.id
    }
  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id
  route{
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.NATgw.id
    }
  tags = {
    Name = "private-route-table"
  }
}


resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private.id
}

resource "aws_eip" "natIP"{
vpc = true
}

resource "aws_nat_gateway" "NATgw"{
  allocation_id = aws_eip.natIP.id
  subnet_id = aws_subnet.public_subnet.id
}



resource "aws_security_group" "default" {
  name        = "project-vpc-default-sg"
  description = "Default SG to alllow traffic from the VPC"
  vpc_id      = aws_vpc.vpc.id
  depends_on = [
    aws_vpc.vpc
  ]

    ingress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = "true"
  }
}

# Create security group for EC2 instances
resource "aws_security_group" "instance_sg" {
  name        = "InstanceSG"
  description = "Security group for EC2 instances"

  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "tf-key-pair" {
key_name = "tf-key-pair.pem"
public_key = tls_private_key.rsa.public_key_openssh
}
resource "tls_private_key" "rsa" {
algorithm = "RSA"
rsa_bits  = 4096
}
resource "local_file" "tf-key" {
content  = tls_private_key.rsa.private_key_pem
filename = "tf-key-pair.pem"
}

resource "aws_instance" "ec2_instance" {
  count         = var.count_num
  ami           = var.ami_id  
  instance_type = "t2.micro"
  key_name = "tf-key-pair.pem"
  subnet_id     = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.instance_sg.id]

  tags = {
    Name = "EC2Instance-${count.index + 1}"
  }
}
