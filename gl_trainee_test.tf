provider "aws" {
  profile = "default"
  region  = "eu-west-2"
}


resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"

  tags = {
    Name = "main_vpc"
  }
}

resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "main_sb"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main_gw"
  }
}

resource "aws_default_route_table" "main" {
  default_route_table_id = aws_vpc.main.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "main_rt"
  }
}

resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_default_route_table.main.id
}

resource "aws_default_security_group" "allow_web_winrm" {
  vpc_id = aws_vpc.main.id

  dynamic "ingress" {
    for_each = ["80", "443", "5985", "5986"]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_web_winrm"
  }
}


resource "aws_eip" "my_static_ip" {
  tags = {
    Name = "main_ip_nlb"
  }
}

resource "aws_lb_target_group" "main_tg" {
  name     = "tf-example-lb-tg"
  port     = 80
  protocol = "TCP"
  vpc_id   = aws_vpc.main.id
}

resource "aws_lb_target_group_attachment" "test" {
  target_group_arn = aws_lb_target_group.main_tg.arn
  target_id        = aws_instance.Web1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "test1" {
  target_group_arn = aws_lb_target_group.main_tg.arn
  target_id        = aws_instance.Web2.id
  port             = 80
}

resource "aws_lb" "main_nlb" {
  load_balancer_type = "network"

  subnet_mapping {
    subnet_id     = aws_subnet.main.id
    allocation_id = aws_eip.my_static_ip.id
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.main_nlb.arn
  port              = "80"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main_tg.arn
  }
}

resource "aws_network_interface" "main_web_1" {
  subnet_id   = aws_subnet.main.id
  private_ips = ["10.0.1.10"]
  tags = {
    Name = "primary_network_interface_web_1"
  }
  depends_on = [aws_subnet.main]
}

resource "aws_network_interface" "main_web_2" {
  subnet_id   = aws_subnet.main.id
  private_ips = ["10.0.1.11"]
  tags = {
    Name = "primary_network_interface_web_2"
  }
  depends_on = [aws_subnet.main]
}


resource "aws_instance" "Web1" {
  ami           = "ami-0b9c6280837a41207"
  instance_type = "t3.micro"
  user_data     = file("user_data.ps1")

  network_interface {
    network_interface_id = aws_network_interface.main_web_1.id
    device_index         = 0
  }

  tags = {
    Name = "Win1_Web"
  }
  depends_on = [aws_network_interface.main_web_1]

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_instance" "Web2" {
  ami           = "ami-0b9c6280837a41207"
  instance_type = "t3.micro"
  user_data     = file("user_data.ps1")

  network_interface {
    network_interface_id = aws_network_interface.main_web_2.id
    device_index         = 0
  }
  tags = {
    Name = "Win2_Web"
  }
  depends_on = [aws_network_interface.main_web_2]
  lifecycle {
    create_before_destroy = true
  }
}
