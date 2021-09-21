terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.53"
    }
  }

  required_version = ">= 0.14.9"
}
variable "region" {
  type        = string
  description = "AWS Region"
}

provider "aws" {
  profile = "979559056307_Solution-Architects.User"
  region  = var.region
}

variable "instancetype" {
  type        = string
  description = "AWS Instance Type"
  default     = "t2.micro"
}

variable "expire_on" {
  type        = string
  description = "date of expiration (YYYY-MM-DD)"

  validation {
    condition     = can(regex("\\d{4}-\\d{2}-\\d{2}", var.expire_on))
    error_message = "Invalid date format was provided."
  }
}

variable "purpose" {
  type        = string
  description = "purpose (training or partner or opportunity or other)"

  validation {
    condition     = contains(["training", "partner", "opportunity", "other"], var.purpose)
    error_message = "Invalid purpose. It must be one of the following: training, partner, opportunity or other."
  }
}

variable "keyName" {
  type        = string
  description = "Name of your AWS key"
}

variable "keyPath" {
  type        = string
  description = "Full path to your AWS key"
}

variable "ownerName" {
  type        = string
  description = "your AWS owner tag (<firstname>.<lastname>)"
}

variable "initials" {
  type        = string
  description = "Provide your initials for a unique name identifier"

}

resource "aws_security_group" "OpsManager" {
  name        = "${var.initials}_OpsManater"
  description = "Allow ingress for Ops Manager"

  ingress = [
    {
      description      = "SSH Traffic"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = null
      prefix_list_ids  = null
      security_groups  = null
      self             = null
    },
    {
      description      = "HTTP"
      from_port        = 8080
      to_port          = 8080
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = null
      prefix_list_ids  = null
      security_groups  = null
      self             = null
    },
    {
      description      = "HTTPS"
      from_port        = 8443
      to_port          = 8443
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = null
      prefix_list_ids  = null
      security_groups  = null
      self             = null
    },
    {
      description      = "MongoDB Port"
      from_port        = 27017
      to_port          = 27017
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = null
      prefix_list_ids  = null
      security_groups  = null
      self             = null
    }
  ]
  egress = [
    {
      description      = "All Ports/Protocols"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids  = null
      security_groups  = null
      self             = null
    }
  ]

}

resource "aws_instance" "OpsManager" {
  ami                    = "ami-0453cb7b5f2b7fca2"
  instance_type          = var.instancetype
  vpc_security_group_ids = [aws_security_group.OpsManager.id]
  key_name               = var.keyName

  root_block_device {
    volume_size = 50
  }

  tags = {
    Name      = "${var.initials}_OpsManager",
    owner     = var.ownerName,
    expire-on = var.expire_on,
    purpose   = var.purpose
  }
}

resource "null_resource" "OpsManager_config" {
  triggers = {
    config_file = templatefile("${path.module}/opsManager_config.tpl", {
      OpsManagerUrl = "http://${aws_instance.OpsManager.public_dns}:8080"
    })
  }
  provisioner "file" {
    source      = "repo_file"
    destination = "/home/ec2-user/repo_file"
    connection {
      host        = coalesce(aws_instance.OpsManager.public_ip, aws_instance.OpsManager.private_ip)
      agent       = true
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.keyPath)
    }

  }
  provisioner "file" {
    source      = "config_file"
    destination = "/home/ec2-user/config_file"
    connection {
      host        = coalesce(aws_instance.OpsManager.public_ip, aws_instance.OpsManager.private_ip)
      agent       = true
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.keyPath)
    }

  }

  provisioner "file" {
    content     = self.triggers.config_file
    destination = "/home/ec2-user/opsmanager_config"
    connection {
      host        = coalesce(aws_instance.OpsManager.public_ip, aws_instance.OpsManager.private_ip)
      agent       = true
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.keyPath)
    }
  }

  provisioner "remote-exec" {
    script = "install_script.sh"
    connection {
      host        = coalesce(aws_instance.OpsManager.public_ip, aws_instance.OpsManager.private_ip)
      agent       = true
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.keyPath)
    }

  }
}

output "host_ip" {
  description = "Ops Manager URL"
  value = "${aws_instance.OpsManager.public_ip}:8080"

}
