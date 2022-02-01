variable "image" {
  default = "ddollar/convox"
}

variable "kubeconfig" {
  default = "~/.kube/config"
}

variable "name" {
  type = string
}

variable "release" {
  default = ""
}
