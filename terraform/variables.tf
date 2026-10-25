variable "aws_region" {
  description = "AWS region for this lab"
  type        = string
  default     = "ap-south-1"
}

variable "ssh_key_name" {
  description = "Existing EC2 key pair name (not local PEM filename)"
  type        = string
}

variable "instance_type" {
  description = "Instance type; 4 GiB RAM recommended for Kubernetes"
  type        = string
  default     = "t3.medium"
}
