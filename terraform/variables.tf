variable "region" {
  type = string
  default = "eu-central-1"
}

variable "cidr" {
  type = string
  default = "10.20.0.0/16"
}

variable "private_cidr" {
  type = list(string)
  default = ["10.20.1.0/24", "10.20.2.0/24"]
}

variable "public_cidr" {
  type = list(string)
  default = ["10.20.11.0/24", "10.20.22.0/24"]
}

variable "instance_type" {
  type = string
  default = "t3.micro"
}
