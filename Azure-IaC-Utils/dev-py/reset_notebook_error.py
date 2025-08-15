import os
from dotenv import load_dotenv
from azure.ai.ml import MLClient
from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient

# 환경변수 로드
load_dotenv()

# 구독 ID
subscription_id = os.getenv("AZURE_SUBSCRIPTION_ID")

# 리소스 그룹 및 워크스페이스 목록 생성
resource_groups = [f"{str(i).zfill(2)}_rg_rag" for i in range(1, 36)]  # 01_rg_rag ~ 35_rg_rag
workspaces = [f"{str(i).zfill(2)}mlworkspaceRAG" for i in range(1, 36)]  # 01mlworkspaceRAG ~ 35mlworkspaceRAG

# Azure 인증
credential = DefaultAzureCredential()

# 각 워크스페이스 처리
for rg, ws in zip(resource_groups, workspaces):
    try:
        print(f"Processing workspace: {ws} in resource group: {rg}")
        ml_client = MLClient(
            credential,
            subscription_id=subscription_id,
            resource_group_name=rg,
            workspace_name=ws
        )
        workspace_details = ml_client.workspaces.get(ws)
        storage_account_name = workspace_details.storage_account.split('/')[8]
        container_name = "azureml"
        blob_service_client = BlobServiceClient(
            account_url=f"https://{storage_account_name}.blob.core.windows.net",
            credential=credential
        )
        container_client = blob_service_client.get_container_client(container_name)
        user_prefix = f"Users/{ws.split('mlworkspace')[0]}.user_RAG/notebooks"  # 동적 경로

        # 전체 블롭 나열 (디버깅)
        print(f"Listing all blobs in {storage_account_name}/{container_name}:")
        all_blobs = container_client.list_blobs(include=['metadata'])
        for blob in all_blobs:
            print(f"  - {blob.name} (Last modified: {blob.last_modified})")

        # 특정 경로의 블롭 나열
        print(f"Listing blobs under {user_prefix}:")
        blob_list = container_client.list_blobs(name_starts_with=user_prefix)
        for blob in blob_list:
            print(f"  - {blob.name}")

        # 노트북 파일 삭제
        deleted_count = 0
        for blob in blob_list:
            if blob.name.endswith('.ipynb'):
                print(f"Deleting {blob.name} in workspace {ws}")
                container_client.delete_blob(blob.name)
                deleted_count += 1
        print(f"Completed processing workspace: {ws}. Deleted {deleted_count} .ipynb files.")
    except Exception as e:
        print(f"Error processing workspace {ws}: {str(e)}")