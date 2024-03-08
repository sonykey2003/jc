
# AWS Vars
variable "your-jc-username" {
  type = string
}

variable "my-aws-profile" {
  type = string
}

variable "how-many-servers" {
  type = number
}

variable "AWS_REGION" {
  default = "ap-southeast-1" # AWS Singapore Region
}



# Windows Server AMI
data "aws_ami" "win2022" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }
  filter {
      name = "virtualization-type"
      values = ["hvm"]
  }
}

# API for attaining public IP
data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
  #request_body = "request body"
}

# Networking Vars
