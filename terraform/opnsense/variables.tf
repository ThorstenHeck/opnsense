
variable "IMAGE" {
    type    = string
    default = "opnsense"
}

variable "HCLOUD_TOKEN" {
  type = string
}

variable "OPNSENSE_ROOT_PASSWORD" {
  type = string
}

variable "SSH_KEY" {
  type = string
}
