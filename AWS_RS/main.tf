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

variable "node_count" {
  type        = number
  description = "How many nodes should be provisioned"
}

variable "mmsGroupId" {
  type        = string
  description = "mms GroupId"
}

variable "mmsApiKey" {
  type        = string
  description = "mmsApiKey"
}
variable "mmsBaseUrl" {
  type        = string
  description = "mmsBaseUrl"
}


data "template_file" "config" {
  template = file("${path.module}/agent_config.tpl")
  vars = {
    mmsGroupId = "${var.mmsGroupId}"
    mmsApiKey  = "${var.mmsApiKey}"
    mmsBaseUrl = "${var.mmsBaseUrl}"
  }
}

data "template_file" "install_script" {
  template = file("${path.module}/install_script.tpl")
  vars = {
    mmsBaseUrl = "${var.mmsBaseUrl}"
  }
}

resource "aws_security_group" "ReplicaSet" {
  name        = "${var.initials}_RS"
  description = "Allow ingress for RS"

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
      description      = "RDP"
      from_port        = 3389
      to_port          = 3389
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = null
      prefix_list_ids  = null
      security_groups  = null
      self             = null
    },
    {
      description      = "MongoDB Connection"
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

resource "aws_instance" "Replica" {
  ami                    = "ami-0453cb7b5f2b7fca2"
  instance_type          = var.instancetype
  vpc_security_group_ids = [aws_security_group.ReplicaSet.id]
  key_name               = var.keyName
  count                  = var.node_count

  tags = {
    Name      = "${var.initials}_RS",
    owner     = var.ownerName,
    expire-on = var.expire_on,
    purpose   = var.purpose
  }
  provisioner "file" {
    content     = data.template_file.config.rendered
    destination = "/home/ec2-user/automation-agent.config"
    connection {
      host        = coalesce(self.public_ip, self.private_ip)
      agent       = true
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.keyPath)
    }
  }

  provisioner "file" {
    content     = data.template_file.install_script.rendered
    destination = "/home/ec2-user/install_script.sh"
    connection {
      host        = coalesce(self.public_ip, self.private_ip)
      agent       = true
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.keyPath)
    }

  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ec2-user/install_script.sh",
      "./install_script.sh"
    ]
    connection {
      host        = coalesce(self.public_ip, self.private_ip)
      agent       = true
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.keyPath)
    }

  }
}



