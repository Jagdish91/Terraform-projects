resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.myvpc.id
}

resource "aws_subnet" "public-subnet-1" {
  vpc_id = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a"
  tags = {
    Name = "Public_Subnet_1"
  }
}

resource "aws_subnet" "public-subnet-2" {
    vpc_id = aws_vpc.myvpc.id
    cidr_block = "10.0.2.0/24"
    map_public_ip_on_launch = true
    availability_zone = "us-east-1b"
    tags = {
      Name = "Public_Subnet_2"
    }
}

resource "aws_subnet" "private-subnet-1" {
  vpc_id = aws_vpc.myvpc.id
  cidr_block = "10.0.3.0/24"
  map_public_ip_on_launch = false
  availability_zone = "us-east-1c"
  tags = {
    Name = "Private_Subnet_1"
  }
}

resource "aws_subnet" "private-subnet-2" {
  vpc_id = aws_vpc.myvpc.id
  cidr_block = "10.0.4.0/24"
  map_public_ip_on_launch = false
  availability_zone = "us-east-1d"
  tags = {
    Name = "Private_Subent_1"
  }
}

resource "aws_security_group" "ec2-sg" {
  name = "ec2-sg"
  description = "EC2 security group- allow traffic from alb"
  vpc_id = aws_vpc.myvpc.id  
}

resource "aws_security_group_rule" "ec2-sg-allow-htpp-in" {
  type = "ingress"
  description = "Allow HTTP traffic only from ALB"
  security_group_id = aws_security_group.ec2-sg.id
  from_port = 80
  to_port = 80
  protocol = "tcp"
  source_security_group_id = aws_security_group.alb-sg.id
}

# Will add bastion host/SSH later 
/*
resource "aws_vpc_security_group_ingress_rule" "ec2-ssh-from-bastion" {
  description = "Allow SSH from Bastion Host"
  security_group_id = aws_security_group.ec2-sg.id
  from_port = 22
  to_port = 22
  ip_protocol = "tcp"
  cidr_ipv4 = "10.0.3.0/24" #change it to bastion host
}
*/

resource "aws_vpc_security_group_egress_rule" "ec2-sg-allow-all-out" {
  description = "Allow all outbound traffic"
  security_group_id = aws_security_group.ec2-sg.id
  cidr_ipv4 = "0.0.0.0/0"
  ip_protocol = "-1"
}


resource "aws_instance" "web-server-1" {
  subnet_id = aws_subnet.private-subnet-1.id
  ami = "ami-0ecb62995f68bb549"
  instance_type = "t3.micro"
  key_name = "prod-example"
  associate_public_ip_address = false
  vpc_security_group_ids = [aws_security_group.ec2-sg.id]
  user_data = base64encode(file("userdata.sh"))
}

resource "aws_instance" "web-server-2" {
  subnet_id = aws_subnet.private-subnet-2.id
  ami = "ami-0ecb62995f68bb549"
  instance_type = "t3.micro"
  key_name = "prod-example"
  associate_public_ip_address = false
  vpc_security_group_ids = [aws_security_group.ec2-sg.id]
  user_data = base64encode(file("userdata1.sh"))
  tags = {
    Name = "Web-Server-1"
  }
}

resource "aws_alb_target_group" "alb-tg" {
  name = "my-alb-tg"
  port = 80 
  protocol = "HTTP"
  vpc_id = aws_vpc.myvpc.id
  target_type = "instance"
  health_check {
    path = "/"
    port = "traffic-port"
  }
}

resource "aws_alb_target_group_attachment" "alb-tg-web-1" {
  target_group_arn = aws_alb_target_group.alb-tg.arn  
  target_id = aws_instance.web-server-1.id
  port = 80  
}

resource "aws_alb_target_group_attachment" "alb-tg-web-2" {
  target_group_arn = aws_alb_target_group.alb-tg.arn
  target_id = aws_instance.web-server-2.id
  port = 80
}

resource "aws_security_group" "alb-sg" {
  description = "Allow http inbound and outbound traffic"
  vpc_id = aws_vpc.myvpc.id  
  tags = {
    Name = "alb-sg-allow-http"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb-sg-allow-all-inboud" {
  description = "Allow all inbound traffic to ALB"
  security_group_id = aws_security_group.alb-sg.id
  ip_protocol = "tcp"
  from_port = 80
  to_port = 80
  cidr_ipv4 = "0.0.0.0/0"  
}

resource "aws_vpc_security_group_egress_rule" "alb-sg-allow-all-outbound" {
  description = "Allow all outboudn traffic from ALB"
  security_group_id = aws_security_group.alb-sg.id
  ip_protocol = "tcp"
  from_port = 0
  to_port = 65535
  cidr_ipv4 = "0.0.0.0/0"
}

resource "aws_lb" "my-alb" {
  name = "my-alb"
  internal = false
  load_balancer_type = "application"
  subnets = [aws_subnet.public-subnet-1.id, aws_subnet.public-subnet-2.id]
  security_groups = [aws_security_group.alb-sg.id]
}

resource "aws_alb_listener" "alb-listener" {
  load_balancer_arn = aws_lb.my-alb.arn
  port = 80
  protocol = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.alb-tg.arn
    type = "forward"
  }
}

resource "aws_route_table" "rt-igw" {
  vpc_id = aws_vpc.myvpc.id 

  route {
     cidr_block = aws_vpc.myvpc.cidr_block
     gateway_id = "local"
  } 

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
}

resource "aws_route_table" "private-rt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = aws_vpc.myvpc.cidr_block
    gateway_id = "local"
  }
}

resource "aws_route_table_association" "rt-igw-sub-1" {
  subnet_id = aws_subnet.public-subnet-1.id
  route_table_id = aws_route_table.rt-igw.id  
}

resource "aws_route_table_association" "rt-igw-sub-2" {
  subnet_id = aws_subnet.public-subnet-2.id 
  route_table_id = aws_route_table.rt-igw.id
}

resource "aws_route_table_association" "rt-private-3" {
  subnet_id = aws_subnet.private-subnet-1.id
  route_table_id = aws_route_table.private-rt.id
}

resource "aws_route_table_association" "rt-private-4" {
  subnet_id = aws_subnet.private-subnet-2.id
  route_table_id = aws_route_table.private-rt.id
}

output "alb-arn" {
  value = aws_lb.my-alb.dns_name
}
