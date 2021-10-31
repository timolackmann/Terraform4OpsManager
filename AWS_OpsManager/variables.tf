variable "region" {
  type        = string
  description = "AWS Region"
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
