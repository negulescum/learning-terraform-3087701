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







resource "aws_instance" "blog" {                      # Provision a aws instance (VM)
  ami           = data.aws_ami.app_ami.id            # Pulling the image from Data Block (1)
  instance_type = "t3.nano"

  vpc_security_group_ids = [module.securitygroup_blog.security_group_id]    # The syntax is the name of the output of the SG Module.Add the new security group module to the instance

  subnet_id = module.vpc_blog.public_subnets[0]  # [0]= first subnet

  # mannualy defined--> vpc_security_group_ids = [aws_security_group.blog.id]  # A list [] containing a single value/multiple .The Syntax to add the security group to the Instance 
  tags = {
    Name = "HelloWorld"
  }
}


# Application Load Balancer

module "alb" {
  source = "terraform-aws-modules/alb/aws"

  load_balancer_type = "application"


  name    = "alb_blog"
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
    
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "10.0.0.0/16"
    }
  }

  # What traffic to listen for- HTTP traffic

  
  target_groups = {
    ex-instance = {
      name_prefix      = "blog"
      protocol         = "HTTP"
      port             = 80
      target_type      = "instance"
      target_id        = "aws_instance.blog.id"  # Tells the LB where to send the traffic
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