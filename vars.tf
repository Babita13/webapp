variable "AMI" {
    type = map(string)
    
    default = {
        ap-south-1 = "ami-0756a1c858554433e"
        ap-south-2 = "ami-079b5e5b3971bd10d"
        us-east-1 = "ami-09d56f8956ab235b3"
        us-east-2 = "ami-0aeb7c931a5a61206"
        us-west-1 = "ami-0dc5e9ff792ec08e3"
        us-west-2 = "ami-0ee8244746ec5d6d4"
    }
}

variable "AWS_REGION" {    
    default = "ap-south-1"
}

variable "vpc_cidr" {
  description = "The CIDR block of the vpc"
  default = "10.0.0.0/16"
}

variable "public_subnets_cidr" {
  type        = list
  description = "The CIDR block for the public subnet"
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets_cidr" {
  type        = list
  description = "The CIDR block for the private subnet"
  default = ["10.0.3.0/24", "10.0.4.0/24"]
}