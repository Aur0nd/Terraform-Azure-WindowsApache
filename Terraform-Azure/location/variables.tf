variable "web_server_location" {
  type = string
}

variable "web_server_rg" {
  type = string
}

variable "resource_prefix" {
  type = string
}

variable "web_server_address_space" {
  type = string
}

variable "web_server_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "web_server_count" {
  type = number
}

variable "web_server_subnets" {
  type = map
}

variable "terraform_script_version" {
  type = string
}

variable "admin_password" {
  type = string
}

variable "domain_name_label" {
  type = string
}