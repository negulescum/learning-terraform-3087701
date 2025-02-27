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

data "aws_vpc" "cloud" {        # define data block for VPC
  default = true                # pulling the default values
}


resource "aws_instance" "web" {                      # Provision a aws instance (VM)
  ami           = data.aws_ami.app_ami.id            # Pulling the image from Data Block (1)
  instance_type = "t3.nano"

  tags = {
    Name = "HelloWorld"
  }
}

resource "aws_security_group" "blog" {               # Define the security group 
  name        = "blog"                               # The name that will show up in the AWS console
  description = " allow in hhtp and https . allow out everything"

  vpc_id = data.aws_vpc.cloud.id                     # On which VPC the security group should be applied
}
                
resource "aws_security_group_rule" "blog_http_in" {  # Syntax for adding rules to the security group
 type        = "ingress"
  from_port   = 80                                    # Http traffic
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]                         # Allow all IPs to access resources
  security_group_id = aws_security_group.blog.id      # The name of the security group for which these rules applies

}                     

resource "aws_security_group_rule" "blog_https_in" {
  type        = "ingress"
  from_port   = 443                                    # Https traffic
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]                          # Allow all IPs to access resources
  security_group_id = aws_security_group.blog.id
}

resource "aws_security_group_rule" "blog_everything_out" {
  type        = "egress"
  from_port   = 0                                       # Allow traffic from any port
  to_port     = 0
  protocol    = "-1"                                    # All protocols are allowed
  cidr_blocks = ["0.0.0.0/0"]                           # Allow all IPs to access resources
  security_group_id = aws_security_group.blog.id
}