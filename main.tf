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
}

module "web_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = "mydev"
  cidr = "10.0.0.0/16"

  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = false
  enable_vpn_gateway = false

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  name               = "my-alb"
  load_balancer_type = "application"

  vpc_id  = module.web_vpc.vpc_id
  subnets = module.web_vpc.public_subnets

  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "Allow HTTP web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"

      forward = {
        target_group_key = "web-instance"
      }
    }
  }

  target_groups = {
    web-instance = {
      name_prefix       = "web"
      protocol          = "HTTP"
      port              = 80
      target_type       = "instance"
      create_attachment = false

      health_check = {
        enabled             = true
        path                = "/"
        port                = "traffic-port"
        healthy_threshold   = 2
        unhealthy_threshold = 2
        timeout             = 5
        interval            = 30
        matcher             = "200"
      }
    }
  }

  tags = {
    Environment = "dev"
    Project     = "Terraform-Learning"
  }
}

resource "aws_security_group" "web_instance_sg" {
  name_prefix = "web-instance-sg-"
  description = "Allow HTTP traffic from ALB to EC2"
  vpc_id      = module.web_vpc.vpc_id

  ingress {
    description     = "Allow HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [module.alb.security_group_id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-instance-sg"
  }
}

module "autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "9.2.1"

  name = "web-asg"

  min_size         = 1
  max_size         = 2
  desired_capacity = 1

  vpc_zone_identifier = module.web_vpc.public_subnets

  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template_name        = "web-asg-template"
  launch_template_description = "Launch template for web ASG"
  update_default_version      = true

  image_id        = data.aws_ami.app_ami.id
  instance_type   = var.instance_type
  security_groups = [aws_security_group.web_instance_sg.id]

  user_data = base64encode(<<-EOF
#!/bin/bash
dnf update -y
dnf install -y httpd
systemctl start httpd
systemctl enable httpd
echo "Hello from Terraform Auto Scaling behind ALB" > /var/www/html/index.html
EOF
  )

  traffic_source_attachments = {
    web_alb = {
      traffic_source_identifier = module.alb.target_groups["web-instance"].arn
      traffic_source_type       = "elbv2"
    }
  }

  tags = {
    Environment = "dev"
    Project     = "Terraform-Learning"
  }
}