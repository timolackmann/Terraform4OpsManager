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

variable "opsManagerUser" {
  type        = string
  description = "Username of your Ops Manager User"
}

variable "opsManagerPass" {
  type        = string
  description = "Password of your Ops Manager User"
}

variable "opsManagerFirstname" {
  type        = string
  description = "First name of your Ops Manager User"
}

variable "opsManagerLastname" {
  type        = string
  description = "Last name of your Ops Manager User"
}

variable "agentNodecount" {
  type        = number
  description = "Number of nodes to be deployed for MongoDB Deployment"
}

variable "agentInstancetype" {
  type        = string
  description = "Instance type of agent nodes"
}

resource "aws_security_group" "OpsManager" {
  name        = "${var.initials}_OpsManager"
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

resource "null_resource" "OpsManager_configuration" {
  triggers = {
    config_file = templatefile("${path.module}/opsManager_configfile.tpl", {
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
    source      = "appDB_config_file"
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
    script = "opsmanager_install_script.sh"
    connection {
      host        = coalesce(aws_instance.OpsManager.public_ip, aws_instance.OpsManager.private_ip)
      agent       = true
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.keyPath)
    }

  }
}

data "external" "agentInfo" {
  depends_on = [null_resource.OpsManager_configuration]

  program = ["python3", "${path.module}/opsmanager_config.py"]

  query={
    host = aws_instance.OpsManager.public_dns
    internalDns = aws_instance.OpsManager.private_dns
    username = var.opsManagerUser
    password = var.opsManagerPass
    firstname = var.opsManagerFirstname
    lastname =  var.opsManagerLastname
  }
}

output "host_ip" {
  description = "Ops Manager URL"
  value = "${aws_instance.OpsManager.public_dns}:8080"

}


# Agent nodes for MongoDB Deployments

data "template_file" "agentConfig" {
  template = file("${path.module}/agent_config.tpl")
  vars = {
    mmsGroupId = data.external.agentInfo.result["mmsGroupId"]
    mmsApiKey  = data.external.agentInfo.result["mmsApiKey"]
    mmsBaseUrl = "http://${aws_instance.OpsManager.public_dns}:8080"
  }
}

data "template_file" "agent_install_script" {
  template = file("${path.module}/agent_install_script.tpl")
  vars = {
    mmsBaseUrl = "http://${aws_instance.OpsManager.public_dns}:8080"
  }
}

resource "aws_security_group" "AgentNode" {
  name        = "${var.initials}_Agents"
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

resource "aws_instance" "AgentNode" {
  ami                    = "ami-0453cb7b5f2b7fca2"
  instance_type          = var.agentInstancetype
  vpc_security_group_ids = [aws_security_group.AgentNode.id]
  key_name               = var.keyName
  count                  = var.agentNodecount

  tags = {
    Name      = "${var.initials}_Agent",
    owner     = var.ownerName,
    expire-on = var.expire_on,
    purpose   = var.purpose
  }
  provisioner "file" {
    content     = data.template_file.agentConfig.rendered
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
    content     = data.template_file.agent_install_script.rendered
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
