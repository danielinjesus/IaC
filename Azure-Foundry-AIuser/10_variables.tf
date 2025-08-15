variable "subscription_id" {}
variable "tenant_id" {}
variable "tenant_email" {}
variable "user_count" { default = 25 }
variable "initial_pwd" { sensitive = true }
# 비밀번호는 admin.microsoft.com에서 원하는 비번으로 일괄로 변경가능합니다. 테라폼으로는 어려움.
variable "location" { default = "Korea Central" }
variable "roles" {
  type = list(string)
  default = [
    "Contributor",
    "Cognitive Services OpenAI Contributor",
    "Azure AI Developer"
  ]
}
variable "user_suffix" { default = "LC" }