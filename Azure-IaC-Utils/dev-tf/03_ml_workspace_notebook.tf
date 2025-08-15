# 학습자료 초기 세팅 (기존 자료 완전 삭제 후 새로 업로드)
resource "null_resource" "setup_student_notebooks" {
  count = var.create_ml_workspace && var.setup_materials_version != "none" ? var.live_workspace_count : 0

  # 오직 이 변수만 변경시 재실행
  triggers = {
    version = var.setup_materials_version
  }

  depends_on = [azurerm_machine_learning_workspace.ml_workspace]

  provisioner "local-exec" {
    interpreter = ["pwsh", "-Command"]
    command     = <<-EOT
      $ErrorActionPreference = "Stop"
      $WorkspaceName = "${azurerm_machine_learning_workspace.ml_workspace[count.index].name}"
      $ResourceGroup = "${azurerm_resource_group.rg[count.index].name}"
      
      try {
        Write-Host "=== 학습자료 초기 세팅 시작: $WorkspaceName ==="
        
        # 1. 기존 학습자료 폴더 완전 삭제
        Write-Host "기존 학습자료 삭제 중..."
        try {
          az ml datastore delete-blob --name workspacefilestore `
            --workspace-name "$WorkspaceName" `
            --resource-group "$ResourceGroup" `
            --path "student-materials" `
            --recursive true `
            --yes 2>$null
          Write-Host "기존 자료 삭제 완료"
        } catch {
          Write-Host "기존 자료 없음 또는 삭제 불필요"
        }
        
        # 2. 새로운 학습자료 업로드
        Write-Host "새로운 학습자료 업로드 중..."
        Write-Host "소스 경로: ${var.notebook_source_path}"
        
        az ml datastore upload --name workspacefilestore `
          --workspace-name "$WorkspaceName" `
          --resource-group "$ResourceGroup" `
          --subscription-id "${var.subscription_id}" `
          --path "${var.notebook_source_path}" `
          --target-path "student-materials" `
          --overwrite true
          
        Write-Host "=== ✅ $WorkspaceName 학습자료 세팅 완료 ==="
        
      } catch {
        Write-Error "❌ $WorkspaceName 학습자료 세팅 실패: $_"
        exit 1
      }
    EOT
  }
}