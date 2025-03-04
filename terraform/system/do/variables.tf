variable "access_id" {
  type = string
}

variable "image" {
  default = "ddollar/convox"
}

variable "name" {
  type = string
}

variable "node_type" {
  default = "s-2vcpu-4gb"
}

variable "region" {
  default = "nyc3"
}

variable "registry_disk" {
  default = "50Gi"
}

variable "release" {
  default = ""
}

variable "secret_key" {
  type = string
}

variable "syslog" {
  default = ""
}

variable "token" {
  type = string
}

variable "whitelist" {
  default = "0.0.0.0/0"
}
