variable "AWS_REGION" {
  default = "ap-south-1"
}

variable "cidr_block"{
  default = "10.0.0.0/16"
}

variable "cidr_block_public_subnet_1"{
  default = "10.0.1.0/24"
}

variable "cidr_block_public_subnet_2"{
  default = "10.0.2.0/24"
}

variable "cidr_block_private_subnet_1"{
  default = "10.0.3.0/24"         
}

variable "cidr_block_private_subnet_2"{
  default = "10.0.4.0/24"
}


variable "az_1"{
  default = "ap-south-1a"
}

variable "az_2"{
  default = "ap-south-1b"
}  
variable "ami_id"{
  default = "ami-0f5ee92e2d63afc18"
}

variable "keyname"{
  default = "webapp"
  }

