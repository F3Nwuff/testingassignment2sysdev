variable "region" {
  type    = string
  default = "us-east-1"
}

variable "key_name" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}
