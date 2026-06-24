data "aws_ami" "app_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  data"aws_vpc" "default" {
    default = true
  }
}
resource "aws_instance" "web" {
  ami           = data.aws_ami.app_ami.id
  instance_type = var.instance_type
vpc_security_group_ids =[aws_security_group_web_id]

  tags = {
    Name = "HelloWorld"
  }
}
resource "aws_security_group" "web" {
  name = "web"
  description = "allow http and https in. Allow everything out"

  vpc_id = data.aws_vpc.default.id
}
resource "aws_security_group_rule" "web_http_in" {
  type       = "ingress"
  from_port  = 80
  to_port    = 80
  protocol   = "tcp"
  cidr_block =["0.0.0.0/0"]

  aws_security_group_id = aws_security_group_web_id

}

resource "aws_security_group_rule" "web_https_in" {
  type       = "ingress"
  from_port  = 443
  to_port    = 443
  protocol   = "tcp"
  cidr_block =["0.0.0.0/0"]

  aws_security_group_id = aws_security_group_web_id

}

resource "aws_security_group_rule" "web_everything_out" {
  type       = "egress"
  from_port  = 0
  to_port    = 0
  protocol   = "-"
  cidr_block =["0.0.0.0/0"]

  aws_security_group_id = aws_security_group_web_id

}