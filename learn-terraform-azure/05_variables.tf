variable "subscription_id" {}
variable "tenant_email" {}

variable "user_suffix" { default = "RAG" }
variable "user_count" { default = 35 }
variable "initial_pwd" { default = "Fc1017!!" }
variable "location" { default = "Korea Central" }
variable "roles" {
  type = list(string)
  default = [
    "Contributor",
    "Cognitive Services OpenAI Contributor",
    "Azure AI Developer"
  ]
}

variable "create_ml_workspace" {
  description = "Create ML Workspace and Compute Instances"
  type        = bool
  default     = true
}

variable "ml_vm_size" {
  description = "VM size for ML Compute Instance"
  default     = "Standard_E4ds_v4"
}

variable "ml_idle_shutdown" {
  description = "Idle shutdown time for ML Compute Instance"
  default     = "PT2H" # 2 hours
}

/*
variable "courses" {
  description = "교육과정 정보"
  type = map(object({
    name          = string
    student_count = number
    location      = string
  }))
  default = {
    "01" = {
      name          = "WebDev"
      student_count = 30
      location      = "Korea Central"
    }
    "02" = {
      name          = "DataScience"
      student_count = 30
      location      = "Korea Central"
    }
    "03" = {
      name          = "AI"
      student_count = 30
      location      = "Korea Central"
    }
    "04" = {
      name          = "Cloud"
      student_count = 30
      location      = "Korea Central"
    }
    "05" = {
      name          = "Security"
      student_count = 30
      location      = "Korea Central"
    }
    "06" = {
      name          = "DevOps"
      student_count = 30
      location      = "Korea Central"
    }
  }
}
*/