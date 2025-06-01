variable "region" {}
variable "access_key" {}
variable "secret_key" {}
variable "ami" {}
variable "instance_type" {}
variable "instance_name" {}
variable "key_name" {}
variable "sg_id" {
    type = list(string)
}
