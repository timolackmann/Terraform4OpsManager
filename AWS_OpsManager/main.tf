terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.53"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "979559056307_Solution-Architects.User"
  region  = var.region
}

data "aws_ami" "AWSlinux2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0.20210721.2-x86_64-gp2"]
  }

  owners = ["amazon"] # Canonical
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
    },
    {
      description      = "Queryable Backup Port"
      from_port        = 25999
      to_port          = 25999
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
  ami                    = data.aws_ami.AWSlinux2.id
  instance_type          = var.instancetype
  vpc_security_group_ids = [aws_security_group.OpsManager.id]
  key_name               = var.keyName
  user_data = templatefile("${path.module}/opsManager_user_data.sh", {
    username  = var.opsManagerUser
    password  = var.opsManagerPass
    firstName = var.opsManagerFirstname
    lastName  = var.opsManagerLastname
  })
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


data "external" "agentInfo" {

  program = ["python3", "${path.module}/opsmanager_config.py"]

  query = {
    host        = aws_instance.OpsManager.public_dns
    internalDns = aws_instance.OpsManager.private_dns
    username    = var.opsManagerUser
    password    = var.opsManagerPass
    firstname   = var.opsManagerFirstname
    lastname    = var.opsManagerLastname
  }
}

output "UI_URL" {
  description = "Ops Manager URL"
  value       = "https://${aws_instance.OpsManager.public_dns}:8443"

}


# Agent nodes for MongoDB Deployments
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
  ami                    = data.aws_ami.AWSlinux2.id
  instance_type          = var.agentInstancetype
  vpc_security_group_ids = [aws_security_group.AgentNode.id]
  key_name               = var.keyName
  count                  = var.agentNodecount
  user_data = templatefile("${path.module}/agentNode_user_data.sh", {
    mmsBaseUrl = "http://${aws_instance.OpsManager.public_dns}:8080"
    mmsGroupId = data.external.agentInfo.result["mmsGroupId"]
    mmsApiKey  = data.external.agentInfo.result["mmsApiKey"]
    mmsBaseUrl = "http://${aws_instance.OpsManager.public_dns}:8080"
  })
  tags = {
    Name      = "${var.initials}_Agent",
    owner     = var.ownerName,
    expire-on = var.expire_on,
    purpose   = var.purpose
  }
}
