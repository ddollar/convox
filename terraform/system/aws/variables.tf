variable "availability_zones" {
  default = ""
}

variable "cidr" {
  default = "10.1.0.0/16"
}

variable "idle_timeout" {
  type    = number
  default = 3600

  validation {
    condition     = var.idle_timeout > 0 && var.idle_timeout < 4001
    error_message = "The idle_timeout must be a value between 1 and 4000."
  }
}

variable "image" {
  default = "ddollar/convox"
}

variable "name" {
  type = string
}

variable "node_disk" {
  default = 20
}

variable "node_type" {
  default = "t3.small"
}

variable "private" {
  default = true
}

variable "release" {
  default = ""
}

variable "region" {
  default = "us-east-1"
}

variable "syslog" {
  default = ""
}

variable "whitelist" {
  default = "0.0.0.0/0"
}
