import os
from dotenv import load_dotenv
from azure.identity import DefaultAzureCredential
from azure.mgmt.resource import ResourceManagementClient
from azure.core.exceptions import ResourceNotFoundError
import re

# 환경변수 로드
load_dotenv()

# 사용자의 구독 ID
subscription_id = os.getenv("AZURE_SUBSCRIPTION_ID") 
credential = DefaultAzureCredential()

resource_client = ResourceManagementClient(credential, subscription_id)

# API 버전 맵
API_VERSION_MAP = {
    "microsoft.cognitiveservices/accounts": "2023-05-01",
    # ⬇️ 오류 메시지에 따라 지원되는 최신 API 버전으로 수정했습니다.
    "microsoft.cognitiveservices/accounts/projects": "2025-04-01-preview", 
}

def get_api_version(res_type):
    # API 버전을 찾을 때 대소문자 구분 없이 처리
    return API_VERSION_MAP.get(res_type.lower())

print("구독 내 모든 리소스를 조회합니다...")
all_resources = list(resource_client.resources.list())
print(f"총 {len(all_resources)}개의 리소스를 찾았습니다.")

# 삭제할 리소스를 타입에 따라 분류
projects_to_delete = []
accounts_to_delete = []

# 삭제 대상 리소스 타입
target_project_type = "microsoft.cognitiveservices/accounts/projects"
target_account_type = "microsoft.cognitiveservices/accounts"

for res in all_resources:
    if res.type.lower() == target_project_type:
        projects_to_delete.append(res)
    elif res.type.lower() == target_account_type:
        accounts_to_delete.append(res)

# 1️⃣ 하위 리소스인 projects 먼저 삭제 (종속성 문제 방지)
print(f"\n--- {len(projects_to_delete)}개의 AI 프로젝트 삭제를 시작합니다 ---")
for res in projects_to_delete:
    api_version = get_api_version(res.type)
    if not api_version:
        print(f"⚠️ API 버전을 찾을 수 없음: {res.name} | 타입: {res.type}")
        continue
    
    print(f"🗑️ 프로젝트 삭제 중: {res.name} (타입: {res.type}, API: {api_version})")
    try:
        delete_op = resource_client.resources.begin_delete_by_id(res.id, api_version=api_version)
        delete_op.wait()
        print(f"✅ 프로젝트 삭제 완료: {res.name}")
    except ResourceNotFoundError:
        print(f" 이미 삭제됨: {res.name}")
    except Exception as e:
        print(f"❌ 프로젝트 삭제 실패: {res.name} → {e}")

# 2️⃣ 상위 리소스인 accounts 삭제
print(f"\n--- {len(accounts_to_delete)}개의 AI 계정(Foundry) 삭제를 시작합니다 ---")
for res in accounts_to_delete:
    api_version = get_api_version(res.type)
    if not api_version:
        print(f"⚠️ API 버전을 찾을 수 없음: {res.name} | 타입: {res.type}")
        continue

    print(f"🗑️ 계정 삭제 중: {res.name} (타입: {res.type}, API: {api_version})")
    try:
        delete_op = resource_client.resources.begin_delete_by_id(res.id, api_version=api_version)
        delete_op.wait()
        print(f"✅ 계정 삭제 완료: {res.name}")
    except ResourceNotFoundError:
        print(f" 이미 삭제됨: {res.name}")
    except Exception as e:
        print(f"❌ 계정 삭제 실패: {res.name} → {e}")

print("\n모든 작업이 완료되었습니다.")