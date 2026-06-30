moved {
    from = module.web_vpc
    to   = module.dev.module.web_vpc
}

moved {
    from = module.web_sg
    to   = module.dev.module.web_sg
}

moved {
  from = aws_security_group.web_instance_sg
  to   = module.dev.aws_security_group.web_instance_sg
}

moved {
    from = module.web_alb
    to   = module.dev.module.web_alb
}

moved {
    from = module.web_autoscaling
    to   = module.dev.module.web_autoscaling
}

  