provider "aws"{
  region = "ap-south-1"
}

resource "aws_security_group" "example" {
  name        = "example-security-group"
  description = "security group for EC2 instance"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
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
}

resource "aws_key_pair" "tf-key-pair" {
key_name = "tf-key-pair"
public_key = tls_private_key.rsa.public_key_openssh
}
resource "tls_private_key" "rsa" {
algorithm = "RSA"
rsa_bits  = 4096
}
resource "local_file" "tf-key" {
content  = tls_private_key.rsa.private_key_pem
filename = "tf-key-pair"
}

resource "aws_instance" "example" {
  ami           = "ami-0f5ee92e2d63afc18"  
  instance_type = "t2.micro"               
  key_name      = "tf-key-pair"            
  vpc_security_group_ids = [aws_security_group.example.id]
  user_data  = file("userdata.sh")
  tags = {
    Name = "example-instance"
  }
}

output "aws_instance_public_dns" {
  value = aws_instance.example.public_dns
}
