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

resource "aws_instance" "web" {                      # Provision a aws instance
  ami           = data.aws_ami.app_ami.id            # Pulling the image from Data Block (1)
  instance_type = "t3.nano"

  tags = {
    Name = "HelloWorld"
  }
}