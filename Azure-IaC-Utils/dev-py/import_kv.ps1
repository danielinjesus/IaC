# Terraform import script for Key Vault access policies (PowerShell)
# Run this script from your Terraform directory

Write-Host "Starting Terraform import for Key Vault access policies..." -ForegroundColor Green

# Define the resource mappings
$resources = @(
    @{Index = 0; RG = "01_RG_RAG"; KV = "kv01RAGbbdspj"; ObjectId = "dcb7dc87-f75e-486d-b2a0-886e20258cb9"},
    @{Index = 1; RG = "02_RG_RAG"; KV = "kv02RAGrn0c6m"; ObjectId = "4e24aaac-0fc0-4d40-b67e-d654004b0ac3"},
    @{Index = 2; RG = "03_RG_RAG"; KV = "kv03RAGi2b79a"; ObjectId = "b06db5cb-5a60-4e0d-b41d-3a23df3bd9df"},
    @{Index = 3; RG = "04_RG_RAG"; KV = "kv04RAGibsglk"; ObjectId = "b49f1eeb-0b7c-4d33-bc91-d05a93fe3585"},
    @{Index = 4; RG = "05_RG_RAG"; KV = "kv05RAGixwqgb"; ObjectId = "c759ee4e-56c8-41bb-9e17-e887b2f16e50"},
    @{Index = 5; RG = "06_RG_RAG"; KV = "kv06RAGvn40fe"; ObjectId = "3e545969-6c5b-441c-b64b-b78031cd65a6"},
    @{Index = 6; RG = "07_RG_RAG"; KV = "kv07RAGqbt5mc"; ObjectId = "a7fb138d-45e7-40ad-aa57-113a6f9ef89a"},
    @{Index = 7; RG = "08_RG_RAG"; KV = "kv08RAG4dqjjs"; ObjectId = "67380d08-7bec-4430-9203-b36763eaced5"},
    @{Index = 8; RG = "09_RG_RAG"; KV = "kv09RAGces79n"; ObjectId = "7bc2e0f0-b4af-4e95-b40e-9dfd081cc272"},
    @{Index = 9; RG = "10_RG_RAG"; KV = "kv10RAG12ddb9"; ObjectId = "daeb7fd8-d05f-4e15-acb2-168650a61a4e"},
    @{Index = 10; RG = "11_RG_RAG"; KV = "kv11RAG18hw46"; ObjectId = "48c3a8a6-419a-43b7-9122-26d4cd26e3a1"},
    @{Index = 11; RG = "12_RG_RAG"; KV = "kv12RAGqozlk2"; ObjectId = "13bc0cae-386e-4fbe-8e52-eba7a1cc1774"},
    @{Index = 12; RG = "13_RG_RAG"; KV = "kv13RAGeywbo1"; ObjectId = "93cc91c6-93ac-4d26-a471-b75d25f33b82"},
    @{Index = 13; RG = "14_RG_RAG"; KV = "kv14RAGk68o80"; ObjectId = "5ad9449f-3653-4199-b612-9a84fe1c5775"},
    @{Index = 14; RG = "15_RG_RAG"; KV = "kv15RAGt2r28v"; ObjectId = "63dd5202-4baa-454e-849c-0e86062250cd"},
    @{Index = 15; RG = "16_RG_RAG"; KV = "kv16RAGjr0cbg"; ObjectId = "afba45ab-35ad-417f-a033-88bc1bedd40d"},
    @{Index = 16; RG = "17_RG_RAG"; KV = "kv17RAG3qz0s5"; ObjectId = "3c2b4b2e-5d3e-4036-822d-6396c749b956"},
    @{Index = 17; RG = "18_RG_RAG"; KV = "kv18RAGgm5lv1"; ObjectId = "1b80dc0b-9bd7-4678-aff8-d62e8da6304b"},
    @{Index = 18; RG = "19_RG_RAG"; KV = "kv19RAGhrt568"; ObjectId = "851bc09d-2f8f-4334-8845-acf32492eda6"},
    @{Index = 19; RG = "20_RG_RAG"; KV = "kv20RAGclek59"; ObjectId = "7f740e52-b30f-44cb-a006-fa3dbb113233"},
    @{Index = 20; RG = "21_RG_RAG"; KV = "kv21RAGgwdqnc"; ObjectId = "9fc869b7-162d-48b2-8748-219d29805b36"},
    @{Index = 21; RG = "22_RG_RAG"; KV = "kv22RAGfq9l4c"; ObjectId = "93301ea5-2950-457d-9914-bc1a0ff70d41"},
    @{Index = 22; RG = "23_RG_RAG"; KV = "kv23RAGgydnn7"; ObjectId = "043161a7-b526-4c9c-af5b-948b5e31d4c8"}
)

# 환경변수에서 구독 ID 읽기
$subscriptionId = $env:AZURE_SUBSCRIPTION_ID
if (-not $subscriptionId) {
    Write-Error "AZURE_SUBSCRIPTION_ID 환경변수가 설정되지 않았습니다."
    exit 1
}

# Loop through each resource and import
foreach ($resource in $resources) {
    $terraformResource = "azurerm_key_vault_access_policy.ml_workspace_policy[$($resource.Index)]"
    $azureResourceId = "/subscriptions/$subscriptionId/resourceGroups/$($resource.RG)/providers/Microsoft.KeyVault/vaults/$($resource.KV)/objectId/$($resource.ObjectId)"
    
    Write-Host "Importing resource $($resource.Index): $($resource.KV)" -ForegroundColor Yellow
    
    terraform import $terraformResource $azureResourceId
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to import resource $($resource.Index)" -ForegroundColor Red
    } else {
        Write-Host "Successfully imported resource $($resource.Index)" -ForegroundColor Green
    }
}

Write-Host "`nImport completed. Running terraform plan to verify..." -ForegroundColor Cyan
terraform plan

Write-Host "`nImport script finished. Review the plan output above." -ForegroundColor Green