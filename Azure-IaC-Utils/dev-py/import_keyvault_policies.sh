#!/bin/bash

# Terraform import script for Key Vault access policies
# Run this script from your Terraform directory

# 환경변수 확인
if [ -z "$AZURE_SUBSCRIPTION_ID" ]; then
    echo "Error: AZURE_SUBSCRIPTION_ID 환경변수가 설정되지 않았습니다."
    echo "다음과 같이 설정하세요: export AZURE_SUBSCRIPTION_ID=your_subscription_id"
    exit 1
fi

echo "Starting Terraform import for Key Vault access policies..."
echo "사용 중인 구독 ID: $AZURE_SUBSCRIPTION_ID"

# Import commands for all 24 access policies
terraform import 'azurerm_key_vault_access_policy.ml_workspace_policy[0]' "/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/01_RG_RAG/providers/Microsoft.KeyVault/vaults/kv01RAGbbdspj/objectId/dcb7dc87-f75e-486d-b2a0-886e20258cb9"

terraform import 'azurerm_key_vault_access_policy.ml_workspace_policy[1]' '/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/02_RG_RAG/providers/Microsoft.KeyVault/vaults/kv02RAGrn0c6m/objectId/4e24aaac-0fc0-4d40-b67e-d654004b0ac3'

terraform import 'azurerm_key_vault_access_policy.ml_workspace_policy[2]' '/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/03_RG_RAG/providers/Microsoft.KeyVault/vaults/kv03RAGi2b79a/objectId/b06db5cb-5a60-4e0d-b41d-3a23df3bd9df'

terraform import 'azurerm_key_vault_access_policy.ml_workspace_policy[3]' '/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/04_RG_RAG/providers/Microsoft.KeyVault/vaults/kv04RAGibsglk/objectId/b49f1eeb-0b7c-4d33-bc91-d05a93fe3585'

terraform import 'azurerm_key_vault_access_policy.ml_workspace_policy[4]' '/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/05_RG_RAG/providers/Microsoft.KeyVault/vaults/kv05RAGixwqgb/objectId/c759ee4e-56c8-41bb-9e17-e887b2f16e50'

terraform import 'azurerm_key_vault_access_policy.ml_workspace_policy[5]' '/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/06_RG_RAG/providers/Microsoft.KeyVault/vaults/kv06RAGvn40fe/objectId/3e545969-6c5b-441c-b64b-b78031cd65a6'

terraform import 'azurerm_key_vault_access_policy.ml_workspace_policy[6]' '/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/07_RG_RAG/providers/Microsoft.KeyVault/vaults/kv07RAGqbt5mc/objectId/a7fb138d-45e7-40ad-aa57-113a6f9ef89a'

terraform import 'azurerm_key_vault_access_policy.ml_workspace_policy[7]' '/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/08_RG_RAG/providers/Microsoft.KeyVault/vaults/kv08RAG4dqjjs/objectId/67380d08-7bec-4430-9203-b36763eaced5'

terraform import 'azurerm_key_vault_access_policy.ml_workspace_policy[8]' '/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/09_RG_RAG/providers/Microsoft.KeyVault/vaults/kv09RAGces79n/objectId/7bc2e0f0-b4af-4e95-b40e-9dfd081cc272'

terraform import 'azurerm_key_vault_access_policy.ml_workspace_policy[9]' '/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/10_RG_RAG/providers/Microsoft.KeyVault/vaults/kv10RAG12ddb9/objectId/daeb7fd8-d05f-4e15-acb2-168650a61a4e'

terraform import 'azurerm_key_vault_access_policy.ml_workspace_policy[10]' '/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/11_RG_RAG/providers/Microsoft.KeyVault/vaults/kv11RAG18hw46/objectId/48c3a8a6-419a-43b7-9122-26d4cd26e3a1'

terraform import 'azurerm_key_vault_access_policy.ml_workspace_policy[11]' '/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/12_RG_RAG/providers/Microsoft.KeyVault/vaults/kv12RAGqozlk2/objectId/13bc0cae-386e-4fbe-8e52-eba7a1cc1774'

terraform import 'azurerm_key_vault_access_policy.ml_workspace_policy[12]' '/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/13_RG_RAG/providers/Microsoft.KeyVault/vaults/kv13RAGeywbo1/objectId/93cc91c6-93ac-4d26-a471-b75d25f33b82'

terraform import 'azurerm_key_vault_access_policy.ml_workspace_policy[13]' '/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/14_RG_RAG/providers/Microsoft.KeyVault/vaults/kv14RAGk68o80/objectId/5ad9449f-3653-4199-b612-9a84fe1c5775'

terraform import 'azurerm_key_vault_access_policy.ml_workspace_policy[14]' '/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/15_RG_RAG/providers/Microsoft.KeyVault/vaults/kv15RAGt2r28v/objectId/63dd5202-4baa-454e-849c-0e86062250cd'

terraform import 'azurerm_key_vault_access_policy.ml_workspace_policy[15]' '/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/16_RG_RAG/providers/Microsoft.KeyVault/vaults/kv16RAGjr0cbg/objectId/afba45ab-35ad-417f-a033-88bc1bedd40d'

terraform import 'azurerm_key_vault_access_policy.ml_workspace_policy[16]' '/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/17_RG_RAG/providers/Microsoft.KeyVault/vaults/kv17RAG3qz0s5/objectId/3c2b4b2e-5d3e-4036-822d-6396c749b956'

terraform import 'azurerm_key_vault_access_policy.ml_workspace_policy[17]' '/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/18_RG_RAG/providers/Microsoft.KeyVault/vaults/kv18RAGgm5lv1/objectId/1b80dc0b-9bd7-4678-aff8-d62e8da6304b'

terraform import 'azurerm_key_vault_access_policy.ml_workspace_policy[18]' '/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/19_RG_RAG/providers/Microsoft.KeyVault/vaults/kv19RAGhrt568/objectId/851bc09d-2f8f-4334-8845-acf32492eda6'

terraform import 'azurerm_key_vault_access_policy.ml_workspace_policy[19]' '/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/20_RG_RAG/providers/Microsoft.KeyVault/vaults/kv20RAGclek59/objectId/7f740e52-b30f-44cb-a006-fa3dbb113233'

terraform import 'azurerm_key_vault_access_policy.ml_workspace_policy[20]' '/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/21_RG_RAG/providers/Microsoft.KeyVault/vaults/kv21RAGgwdqnc/objectId/9fc869b7-162d-48b2-8748-219d29805b36'

terraform import 'azurerm_key_vault_access_policy.ml_workspace_policy[21]' '/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/22_RG_RAG/providers/Microsoft.KeyVault/vaults/kv22RAGfq9l4c/objectId/93301ea5-2950-457d-9914-bc1a0ff70d41'

terraform import 'azurerm_key_vault_access_policy.ml_workspace_policy[22]' '/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/23_RG_RAG/providers/Microsoft.KeyVault/vaults/kv23RAGgydnn7/objectId/043161a7-b526-4c9c-af5b-948b5e31d4c8'

echo "Import completed. Running terraform plan to verify..."
terraform plan

echo "Import script finished. Review the plan output above."