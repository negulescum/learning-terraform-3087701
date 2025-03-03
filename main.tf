data "aws_ami" "app_ami" {
  most_recent = true

  filter {                                            # Use a filter to find the latest bitnami-tomcat server
    name   = "name"
    values = ["bitnami-tomcat-*-x86_64-hvm-ebs-nami"]   # Deploys a Tomcat server
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["979382823631"] # Bitnami
}


# Default VPC
# data "aws_vpc" "cloud" {        # define data block for VPC
#  default = true                # pulling the default values
# }

# Terraform module which creates VPC resources on AWS.


module "vpc_blog" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs                = ["us-west-1a", "us-west-1b", "us-west-1c"]
  #  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]   # Because it is a public blog
  public_subnets     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]  

  # enable_nat_gateway = true
  # enable_vpn_gateway = true

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}







#resource "aws_instance" "blog" {                      # Provision a aws instance (VM)
#  ami           = data.aws_ami.app_ami.id            # Pulling the image from Data Block (1)
#  instance_type = "t3.nano"

#  vpc_security_group_ids = [module.securitygroup_blog.security_group_id]    # The syntax is the name of the output of the SG Module.Add the new security group module to the instance

#  subnet_id = module.vpc_blog.public_subnets[0]  # [0]= first subnet

  # mannualy defined--> vpc_security_group_ids = [aws_security_group.blog.id]  # A list [] containing a single value/multiple .The Syntax to add the security group to the Instance 
#  tags = {
#    Name = "HelloWorld"
#  }
#}

# This will replace the instance

module "autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "8.1.0"
  
  name = "blog" 
  min_size = 1                                                # How big the instance should be
  max_size = 2

  vpc_zone_identifier = module.vpc_blog.public_subnets        # specify subnets
  target_group_arns   = module.alb_blog.target_group_arns
  security_groups     = [module.securitygroup_blog.security_group_id]

  image_id               = data.aws_ami.app_ami.id       
  instance_type          = var.instance_type
}


# Application Load Balancer

module "alb_blog" {
  source = "terraform-aws-modules/alb/aws"

  load_balancer_type = "application"


  name    = "alb-blog"
  vpc_id  = "module.vpc_blog.vpc_id"
  subnets = ["module.blog_vpc.public_subnets"]
  security_groups = module.securitygroup_blog.security_group_id

   
  # Security Group
  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "HTTP web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
    all_https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      description = "HTTPS web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "10.0.0.0/16"
    }
  }

  
# Routes HTTP requests to target group

  listeners = {
    ex-http-https-redirect = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
    ex-https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = "arn:aws:iam::123456789012:server-certificate/test_cert-123456789012"

      forward = {
        target_group_key = "ex-instance"
      }
    }
  }

# Target Group (Where ALB sends traffic)

  target_groups = {
    ex-instance = {
      name_prefix      = "blog"
      protocol         = "HTTP"
      port             = 80
      target_type      = "instance"
      target_id        = "aws_instance.blog.id"
    }
  }

  tags = {
    Environment = "dev"
    Project     = "Example"
  }
}



module "securitygroup_blog" {                        # The name of the module
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"
  name    = "new_blog"                                # The name of the new security group that was defined (module)
 # vpc_id  = data.aws_vpc.cloud.id                    # On which VPC the security group should be applied

 # New VPC id from VPC module

  vpc_id = module.vpc_blog.vpc_id                     # VPC module Output syntax

# Define some rules

 
 ingress_rules = ["https-443-tcp","http-80-tcp"]
 ingress_cidr_blocks = ["0.0.0.0/0"]                  # Allow all IPs to access resources


 egress_rules       = ["all-all"]                     # Open all ports & protocols   all-all       = [-1, -1, "-1", "All protocols"]
 egress_cidr_blocks = ["0.0.0.0/0"]   

}


# resource "aws_security_group" "blog" {               # Define the security group 
# name        = "blog"                               # The name that will show up in the AWS console
# description = " allow in hhtp and https . allow out everything"

# vpc_id = data.aws_vpc.cloud.id                     # On which VPC the security group should be applied
 # }
                
# resource "aws_security_group_rule" "blog_http_in" {  # Syntax for adding rules to the security group
# type        = "ingress"
#  from_port   = 80                                    # Http traffic
#  to_port     = 80
#  protocol    = "tcp"
#  cidr_blocks = ["0.0.0.0/0"]                         # Allow all IPs to access resources
#  security_group_id = aws_security_group.blog.id      # The name of the security group for which these rules applies

# }                     

# resource "aws_security_group_rule" "blog_https_in" {
#  type        = "ingress"
#  from_port   = 443                                    # Https traffic
#  to_port     = 443
#  protocol    = "tcp"
#  cidr_blocks = ["0.0.0.0/0"]                          # Allow all IPs to access resources
#  security_group_id = aws_security_group.blog.id
# }

# resource "aws_security_group_rule" "blog_everything_out" {
#  type        = "egress"
#  from_port   = 0                                       # Allow traffic from any port
#  to_port     = 0
#  protocol    = "-1"                                    # All protocols are allowed
#  cidr_blocks = ["0.0.0.0/0"]                           # Allow all IPs to access resources
#  security_group_id = aws_security_group.blog.id
# }