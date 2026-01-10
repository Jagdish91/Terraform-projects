resource "aws_vpc" "myvpc" {
  cidr_block = var.vpc_cidr
}

resource "aws_subnet" "sub_1" {
  vpc_id = aws_vpc.myvpc.id
  cidr_block = var.sub_1_cidr
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "sub_2" {
  vpc_id = aws_vpc.myvpc.id
  cidr_block = var.sub_2_cidr
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.myvpc.id
}

resource "aws_route_table" "my_rt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  } 
}

resource "aws_route_table_association" "my_rta_1" {
  subnet_id = aws_subnet.sub_1.id
  route_table_id = aws_route_table.my_rt.id
}

resource "aws_route_table_association" "my_rta_2" {
  subnet_id = aws_subnet.sub_2.id
  route_table_id = aws_route_table.my_rt.id
}

resource "aws_security_group" "terra_sg" {
  name = "ec2-web-sg"
  description = "Allow TLS inboud traffic"
  vpc_id = aws_vpc.myvpc.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_all_ipv4_traffic" {
  security_group_id = aws_security_group.terra_sg.id
  description = "Allow HTTP from anywhere"
  cidr_ipv4 = "0.0.0.0/0"
  from_port = 80
  to_port = 80
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_from_all" {
  security_group_id = aws_security_group.terra_sg.id
  description = "Allow SSH from anywhere"
  cidr_ipv4 = "0.0.0.0/0"
  from_port = 22
  to_port = 22
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "allow_all_outbound" {
  security_group_id = aws_security_group.terra_sg.id
  description = "Allow all outbound traffic"
  cidr_ipv4 = "0.0.0.0/0"
  ip_protocol = "-1"
}

resource "aws_s3_bucket" "my_s3_bucket" {
  bucket = "my-first-bucker-terraform-project-29834347"
}

resource "aws_instance" "web-server-1" {
  ami = "ami-0ecb62995f68bb549"
  instance_type = "t3.micro"
  key_name = "prod-example"
  subnet_id = aws_subnet.sub_1.id
  vpc_security_group_ids = [aws_security_group.terra_sg.id]
  user_data = base64encode(file("userdata.sh"))
}

resource "aws_instance" "web-server-2" {
  ami = "ami-0ecb62995f68bb549"
  instance_type = "t3.micro"
  key_name = "prod-example"
  subnet_id = aws_subnet.sub_2.id
  vpc_security_group_ids = [aws_security_group.terra_sg.id]
  user_data = base64encode(file("userdata1.sh"))
}

resource "aws_alb_target_group" "web-alb-tg" {
    name = "my-web-tg"
    port = 80
    protocol = "HTTP"
    vpc_id = aws_vpc.myvpc.id
    health_check {
      path = "/"
      port = "traffic-port"
    }
}

resource "aws_alb_target_group_attachment" "alb-tg-1" {
  target_group_arn = aws_alb_target_group.web-alb-tg.arn
  target_id = aws_instance.web-server-1.id
  port = 80
}

resource "aws_alb_target_group_attachment" "alb-tg-2" {
  target_group_arn = aws_alb_target_group.web-alb-tg.arn
  target_id = aws_instance.web-server-2.id
  port = 80
}

resource "aws_alb" "web-alb" {
  name = "web-alb"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.terra_sg.id]
  subnets = [aws_subnet.sub_1.id, aws_subnet.sub_2.id]
}

resource "aws_alb_listener" "web-alb-listener" {
    load_balancer_arn = aws_alb.web-alb.arn
    port = 80
    protocol = "HTTP"

    default_action {
      target_group_arn = aws_alb_target_group.web-alb-tg.arn
      type = "forward"
    }
  
}

output "load_balancer_dns" {
  value = aws_alb.web-alb.dns_name
}
