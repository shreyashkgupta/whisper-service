

variable "region" {
    type = string
    description = "AWS region to deploy in"
    default = "us-west-2"
}

variable "instance_name" {
    type = string
    description = "Name of the Instance"
    default = "Whisper-Demo_ec2"
}

variable "instance_type" {
    type = string
    description = "Type of Ec2 Instance"
    default = "t2.micro"
}

variable "autoscaling_capacity" {
    type = number
    description = "Desired capacity of auto scaling group"
    default = 1
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

variable "instance_state" {
    type = string
    description = "Instance state"
    default = "running"
}

variable "env_file_content" {
    type = string
    description = "Environment file content"
    default = ""
}


terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  # TODO: Update your region
  region = var.region
}


resource "aws_security_group" "ingress-all-test" {
  name   = "allow-all-sg-${var.instance_name}"

  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
  }

  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
  }

  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
  }

  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 3000
    to_port   = 3000
    protocol  = "tcp"
  }


  // Terraform removes the default rule
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "security_group_${var.instance_name}"
  }
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type

  vpc_security_group_ids = ["${aws_security_group.ingress-all-test.id}"]
  tags = {
    Name = var.instance_name
  }
  associate_public_ip_address = true


  # subnet_id = "${aws_subnet.subnet-uno.id}"

  user_data = <<EOF
#!/bin/bash
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt install docker.io -y
# sudo usermod -a -G docker ubuntu
sudo service docker start
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version
# Get git repo
cd /home/ubuntu
pwd
sudo git clone https://github.com/shreyashkgupta/whisper-service.git code_files
cd /home/ubuntu/code_files
sudo sh -c echo "${var.env_file_content}" > .env

# Pull and run your Docker image
sudo docker-compose -f docker-compose.yml build
sudo docker-compose -f docker-compose.yml up -d

  EOF

}

resource "aws_eip" "custom_eip" {
  instance = aws_instance.web.id
}

resource "aws_ec2_instance_state" "web" {
  instance_id = aws_instance.web.id
  state = var.instance_state
}
