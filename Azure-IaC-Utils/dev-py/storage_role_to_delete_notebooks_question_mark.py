import os
from dotenv import load_dotenv
from azure.ai.ml import MLClient
from azure.identity import DefaultAzureCredential
from azure.mgmt.authorization import AuthorizationManagementClient
from azure.mgmt.resource import ResourceManagementClient
import uuid

# 환경변수 로드
load_dotenv()

# 구독 ID
subscription_id = os.getenv("AZURE_SUBSCRIPTION_ID")

# 사용자 Object ID (현재 사용자)
assignee_object_id = "539821cb-a649-43d9-856f-fa124a342dc3"

# 역할 이름 (ID는 동적으로 가져옴)
role_name = "Storage Blob Data Contributor"

# Azure 인증
credential = DefaultAzureCredential()

# 리소스 및 권한 관리 클라이언트 초기화
resource_client = ResourceManagementClient(credential, subscription_id)
auth_client = AuthorizationManagementClient(credential, subscription_id)

# 역할 정의 ID 가져오기
role_definition_id = None
role_definitions = auth_client.role_definitions.list(scope=f"/subscriptions/{subscription_id}")
for role in role_definitions:
    if role.role_name == role_name:
        role_definition_id = role.id
        print(f"Found role definition ID: {role_definition_id} for {role_name}")
        break

if not role_definition_id:
    raise Exception(f"Role '{role_name}' not found in subscription {subscription_id}")

# 모든 ML 워크스페이스 가져오기
ml_workspaces = resource_client.resources.list(
    filter="resourceType eq 'Microsoft.MachineLearningServices/workspaces'"
)

# 각 ML 워크스페이스 처리
for workspace in ml_workspaces:
    try:
        workspace_name = workspace.name
        resource_group = workspace.id.split('/')[4]  # 리소스 그룹 추출

        print(f"Processing workspace: {workspace_name} in resource group: {resource_group}")

        # MLClient로 워크스페이스 세부 정보 가져오기
        ml_client = MLClient(
            credential,
            subscription_id=subscription_id,
            resource_group_name=resource_group,
            workspace_name=workspace_name
        )
        workspace_details = ml_client.workspaces.get(workspace_name)
        storage_account_name = workspace_details.storage_account.split('/')[8]  # 스토리지 계정 이름 추출

        print(f"Found storage account: {storage_account_name} for {workspace_name}")

        # 역할 할당 스코프 생성
        scope = f"/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.Storage/storageAccounts/{storage_account_name}"

        # 역할 할당 확인 (중복 방지)
        existing_assignments = auth_client.role_assignments.list_for_scope(scope)
        assignment_exists = False
        for assignment in existing_assignments:
            if assignment.principal_id == assignee_object_id and assignment.role_definition_id == role_definition_id:
                assignment_exists = True
                print(f"Role already assigned for {storage_account_name}")
                break

        # 역할 할당 수행 (중복이 없으면)
        if not assignment_exists:
            auth_client.role_assignments.create(
                scope=scope,
                role_assignment_name=str(uuid.uuid4()),  # 고유 ID 생성
                parameters={
                    "principalId": assignee_object_id,
                    "roleDefinitionId": role_definition_id
                }
            )
            print(f"Successfully assigned {role_name} to {storage_account_name}")
        else:
            print(f"Skipping role assignment for {storage_account_name} (already assigned)")

    except Exception as e:
        print(f"Error processing workspace {workspace_name}: {str(e)}")

print("Role assignment process completed.")