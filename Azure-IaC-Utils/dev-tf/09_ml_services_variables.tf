randomvariable "live_workspace_count" { default = 25 }
variable "ml_vm_size" { default = "Standard_E4ds_v4" }
variable "ml_idle_shutdown" { default = "PT2H" }

variable "create_ml_workspace" { default = false }

variable "start_computes" { default = false }

variable "upload_initial_notebooks" { default = false }
variable "notebook_source_path" { default = "C:/Users/aidan/OneDrive/교육강사/1회차/실습파일" }

variable "enable_azure_openai" { default = false }
variable "azure_openai_sku_name" { default = "S0" }
variable "azure_openai_gpt_model_name" { default = "gpt-4.1-nano"}
variable "azure_openai_embedding_model_name" { default = "text-embedding-3-small" }
variable "azure_openai_model_version" { default = "2025-04-14" }

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