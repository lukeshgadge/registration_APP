provider "aws" {
  region = "ap-southeast-2"

}

locals {
  project_name = "fortune"

  default_tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}


module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = local.project_name
  cidr = "10.0.0.0/16"

  azs             = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true

  single_nat_gateway            = true
  one_nat_gateway_per_az        = false
  enable_vpn_gateway            = false
  manage_default_security_group = true

  tags = local.default_tags


}


resource "aws_security_group" "ssh" {
  name        = "allow_tls-fortune}"
  description = "Allow TLS inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "TLS from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "TLS from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "TLS from VPC"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "TLS from VPC"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "TLS from VPC"
    from_port   = 9003
    to_port     = 9003
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "TLS from VPC"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.default_tags
}



resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "TLS from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.default_tags
}


data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}



# RSA key of size 4096 bits
resource "tls_private_key" "rsa-4096-example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key_pem" {
  content  = tls_private_key.rsa-4096-example.private_key_pem
  filename = "fortune.pem"
}


resource "aws_key_pair" "deployer" {
  key_name   = "fortune"
  public_key = tls_private_key.rsa-4096-example.public_key_openssh

}


resource "aws_instance" "jenkins_mainserver" {

  ami           = data.aws_ami.ubuntu.id
  instance_type = var.jenkins_mainserver

  availability_zone = "ap-southeast-2a"
  subnet_id         = element(module.vpc.public_subnets, 0)

  key_name                    = aws_key_pair.deployer.key_name
  security_groups             = [aws_security_group.ssh.id]
  associate_public_ip_address = true
  root_block_device {
    volume_size = "25"
  }
  iam_instance_profile = aws_iam_instance_profile.example_profile.name
  user_data = "${file("userdata.sh")}"

  connection { ## connection block tells terraform how to connect instance
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.rsa-4096-example.private_key_pem
    host        = self.public_ip
    #timeout     = "4m"
  }

  


  provisioner "local-exec" {
    command = "chmod 600 ${local_file.private_key_pem.filename}"

  }


  provisioner "remote-exec" {
    inline = ["sudo cat /var/lib/jenkins/secrets/initialAdminPassword"]
  }

}