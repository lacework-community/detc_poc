variable "subnet" {
  default = "10.0.0.0/24"
}
variable "subnet1" {
  default = "10.0.1.0/24"
}
variable "cidr_block" {
  default = "10.0.0.0/16"
}
variable "jenkins_admin" {}
variable "jenkins_admin_password" {}
variable "dockerhub_access_token" {}
variable "dockerhub_access_user" {}
variable "lw_access_account" {}
variable "lw_access_token" {}
variable "k8s_build_robot_token" {}
variable "lacework_install_script" {}
