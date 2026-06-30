moved {
  from = module.web_vpc
  to   = module.dev.module.web_vpc
}

moved {
  from = aws_security_group.web_instance_sg
  to   = module.dev.aws_security_group.web_instance_sg
}

moved {
  from = module.alb
  to   = module.dev.module.alb
}

moved {
  from = module.autoscaling
  to   = module.dev.module.autoscaling
}