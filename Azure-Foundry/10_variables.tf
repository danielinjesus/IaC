variable "subscription_id" {}
variable "tenant_id" {}
variable "tenant_email" {}
variable "initial_pwd" { sensitive = true }
variable "user_count" { default = 35 }
# 비밀번호는 admin.microsoft.com에서 원하는 비번으로 일괄로 변경가능합니다. 테라폼으로는 결과가 나오지 않았습니다.
variable "location" { default = "Korea Central" }
variable "roles" {
  type = list(string)
  default = [
    "Contributor",
    "Cognitive Services OpenAI Contributor",
    "Azure AI Developer"
  ]
}
variable "user_suffix" { default = "pro" }