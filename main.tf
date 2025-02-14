data "aws_ami" "app_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["bitnami-tomcat-*-x86_64-hvm-ebs-nami"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["979382823631"] # Bitnami
}

data "aws_vpc" "default" {
default = true
}



resource "aws_instance" "blog" {
  ami           = data.aws_ami.app_ami.id
  instance_type = var.instance_type

vpc_security_group_ids = [module.blog_sg.security_group_id]     # Add this security group to our Instance. Give a list of multiple security groups that we want to apply

  tags = {
    Name = "HelloWorld"
  }
}

module "blog_sg" {
  source  = "terraform-aws-modules/security-group/aws//modules/http-80"
  version = "4.13.0"
  name    = "blog_new"
   vpc_id = data.aws_vpc.default.id

   ingress_rules       = ["http-80-tcp" , "https-443-tcp"]
   ingress_cidr_blocks = ["0.0.0.0/0"]

egress_rules       = ["all-all"]
   egress_cidr_blocks = ["0.0.0.0/0"]


}




resource "aws_security_group" "blog" {    # Security group Block which describes infrastructure security
name = "blog"                             # the name that will show up in the AWS console
description = "Allow http and https in. Allow everything out"

vpc_id = data.aws_vpc.default.id

}

 resource "aws_security_group_rule" "blog_http_in"  {     # adding rules within the security group. What gets in
  type      = "ingress"
  from_port = 80
  to_port   = 80
  protocol  = "tcp"
  cidr_blocks = ["0.0.0.0/0"]                               # Allow all IP addresses.It is a public blog

security_group_id = aws_security_group.blog.id            # telling this rule which group it belongs to

}

resource "aws_security_group_rule" "blog_https_in" {    # adding rules within the security group
  type = "ingress"
  from_port = 443
  to_port = 443
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]                                # Allow all IP addresses.It is a public blog

security_group_id = aws_security_group.blog.id               # telling this rule which group it belongs to

}

resource "aws_security_group_rule" "blog_everything_out" {   # adding rules within the security group. What comes out of the VPC
  type = "egress"
  from_port = 0                       # Allow traffic from any port
  to_port = 0                         # Allow traffic to any port
  protocol = "-1"                     # All protocols are allowed (TCP,UDP,ICMP etc )
  cidr_blocks = ["0.0.0.0/0"]          # Allow all IP addresses.It is a public blog

security_group_id = aws_security_group.blog.id # telling this rule which group it belongs to

}
