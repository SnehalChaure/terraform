resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name        = "project-vpc"
  }
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.vpc.id
 
  cidr_block              = var.cidr_block_public_subnet_1
  availability_zone       = var.az_1
  map_public_ip_on_launch = true

  tags = {
    Name        = "project-vpc-public-subnet_1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.vpc.id

  cidr_block              = var.cidr_block_public_subnet_2
  availability_zone       = var.az_2
  map_public_ip_on_launch = true

  tags = {
    Name        = "project-vpc-public-subnet_2"
  }
}


resource "aws_subnet" "private_subnet_1" {
  vpc_id                  = aws_vpc.vpc.id

  cidr_block              = var.cidr_block_private_subnet_1
  availability_zone       = var.az_1

  tags = {
    Name        = "project-vpc-private-subnet_1"
  }
}

resource "aws_subnet" "private_subnet_2" {     
  vpc_id                  = aws_vpc.vpc.id     
                                               
  cidr_block              = var.cidr_block_private_subnet_2
  availability_zone       = var.az_2             
                                               
  tags = {                                     
    Name        = "project-vpc-private-subnet_2"
  }                                            
}

resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "project-vpc-igw"
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

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "natIP1"{
  count = "1"
  vpc = true
}

resource "aws_nat_gateway" "NATgw_1"{
  allocation_id = aws_eip.natIP1[0].id
  subnet_id = aws_subnet.public_subnet_1.id
}

resource "aws_eip" "natIP2"{
  count = "1"
  vpc = true
}

resource "aws_nat_gateway" "NATgw_2"{
  allocation_id = aws_eip.natIP2[0].id
  subnet_id = aws_subnet.public_subnet_2.id
}

resource "aws_route_table" "private_1" {
  vpc_id = aws_vpc.vpc.id
  route{
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.NATgw_1.id
    }
  tags = {
    Name = "private-route-table_1"
  }
}

resource "aws_route_table" "private_2" {
  vpc_id = aws_vpc.vpc.id
  route{
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.NATgw_2.id
    }
  tags = {
    Name = "private-route-table_2"
  }
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_1.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_2.id
}

# security group for load balancer
resource "aws_security_group" "elb_sg" {
  name        = "alb_sg"
  description = "for ALB"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    description = "HTTP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
 
 tags = {
    Name = "alb_sg"
  } 
}

resource "aws_security_group" "webserver_sg" {
  name        = "privateSG"
  description = "Security group for private EC2 instances"

  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
   from_port   = 0
   to_port     = 0
   protocol    = "-1"
   security_groups = [aws_security_group.elb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create ALB
resource "aws_lb" "ALB-tf" {
  name              = "ALB-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups  = [aws_security_group.elb_sg.id]
  subnets          = [aws_subnet.public_subnet_1.id,aws_subnet.public_subnet_2.id]
  tags = {
        name  = "AppLoadBalancer-tf"
       }
}

# Create ALB Listener
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.ALB-tf.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.TG-tf.arn
  }
}

resource "aws_lb_target_group" "TG-tf" {
  name     = "TargetGroup-tf"
  depends_on = ["aws_vpc.vpc"]
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.vpc.id}"
  health_check {
    interval            = 70
    path                = "/index.html"
    port                = 80
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 60
    protocol            = "HTTP"
    matcher             = "200,202"
  }
}


resource "aws_launch_configuration" "webserver-launch-config" {
  name_prefix   = "webserver-launch-config"
  image_id      =  var.ami_id
  instance_type = "t2.micro"
  key_name = var.keyname
  security_groups = ["${aws_security_group.webserver_sg.id}"]
  
  root_block_device {
            volume_type = "gp2"
            volume_size = 8
            encrypted   = true
        }

  lifecycle {
            create_before_destroy = true
     }
  user_data = filebase64("${path.module}/init_webserver.sh")
}

resource "aws_autoscaling_group" "ASG-tf" {
  name       = "ASG-tf"
  desired_capacity   = 1
  max_size           = 2
  min_size           = 1
  force_delete       = true
  depends_on         = ["aws_lb.ALB-tf"]
  target_group_arns  =  ["${aws_lb_target_group.TG-tf.arn}"]
  health_check_type  = "EC2"
  launch_configuration = aws_launch_configuration.webserver-launch-config.name
  vpc_zone_identifier = ["${aws_subnet.private_subnet_1.id}","${aws_subnet.private_subnet_2.id}"]

 tag {
       key                 = "Name"
       value               = "ASG-tf"
       propagate_at_launch = true
    }
}

output "alb_dns" {
  value = aws_lb.ALB-tf.dns_name
}
