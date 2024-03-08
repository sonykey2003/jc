# AWS Auth - Using SSO profile
provider "aws" {

  profile = var.my-aws-profile
}


data "cloudinit_config" "client" {
  gzip = false
  base64_encode = false
  part {
    filename = "prep-client.ps1"
    content_type = "text/x-shellscript"
    content = templatefile(
                 "${path.module}/prep-client.ps1",
                 {
                  admin_pw = "${var.admin_pw}",
                  jc-connect-key = "${var.jc-connect-key}"
                 }
              )
  }

}

# Building the instances
resource "aws_instance" "server-farm" {
  count = var.how-many-servers

  ami = data.aws_ami.win2022.id

  instance_type = "t2.medium"

  user_data_replace_on_change = true
  associate_public_ip_address = true

  key_name               = aws_key_pair.key_pair.key_name
  get_password_data      = false

  vpc_security_group_ids = [aws_security_group.allow-rdp.id,aws_security_group.allow-internal-all.id]
  subnet_id = aws_subnet.winsrv-subnet.id

  tags = {
    Name = "winSRV202-${var.your-jc-username}-${count.index + 1}"
  }

  user_data =  data.cloudinit_config.client.rendered
}


# Orchestrated Outputs
output "Admin_Username" {
  value = "Administrator"
  
}

output "Admin_Password" {
  value = nonsensitive(var.admin_pw)
  
}

output "public_ip_info" {
  value = aws_instance.server-farm.*.public_ip
}


output "public_dns_info" {
  value = aws_instance.server-farm.*.public_dns
}


output "private_ip_info" {
  value = aws_instance.server-farm.*.private_ip
}

output "note" {
  value = "Please give it 5~10 min before RDP-ing as the win prep script is busy doing its job, go grab a coffee! :-) "
}


