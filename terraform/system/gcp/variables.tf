variable "image" {
  default = "ddollar/convox"
}

variable "name" {
  type = string
}

variable "node_type" {
  default = "n1-standard-1"
}

variable "preemptible" {
  default = true
}

variable "region" {
  default = "us-east1"
}

variable "release" {
  default = ""
}

variable "syslog" {
  default = ""
}

variable "whitelist" {
  default = "0.0.0.0/0"
}
