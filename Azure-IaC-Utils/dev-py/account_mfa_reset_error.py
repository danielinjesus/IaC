import requests
import msal
import json
import os
from dotenv import load_dotenv

# 환경변수 로드
load_dotenv()

# --- 환경변수에서 설정 로드 ---
TENANT_ID = os.getenv("AZURE_TENANT_ID")
CLIENT_ID = os.getenv("AZURE_CLIENT_ID")
CLIENT_SECRET = os.getenv("AZURE_CLIENT_SECRET")

# 대상 사용자 정보
USER_PREFIX = os.getenv("USER_PREFIX", "user_rag")
USER_DOMAIN = os.getenv("USER_DOMAIN", "@ktaiacademy.onmicrosoft.com")
USER_COUNT_START = int(os.getenv("USER_COUNT_START", "1"))
USER_COUNT_END = int(os.getenv("USER_COUNT_END", "35"))
# ----------------------------------------------------

# MSAL 클라이언트 설정
authority = f"https://login.microsoftonline.com/{TENANT_ID}"
app = msal.ConfidentialClientApplication(
    CLIENT_ID,
    authority=authority,
    client_credential=CLIENT_SECRET
)

# Graph API 토큰 요청
scope = ["https://graph.microsoft.com/.default"]
result = app.acquire_token_for_client(scopes=scope)

if "access_token" not in result:
    print("오류: 액세스 토큰을 얻지 못했습니다.")
    print(result.get("error"))
    print(result.get("error_description"))
    exit()

access_token = result['access_token']
headers = {
    'Authorization': f'Bearer {access_token}',
    'Content-Type': 'application/json'
}

def generate_user_list():
    """초기화할 사용자 UPN 목록을 생성합니다."""
    users = []
    for i in range(USER_COUNT_START, USER_COUNT_END + 1):
        # 01, 02, ... 35 형식으로 생성
        user_principal_name = f"{i:02d}_{USER_PREFIX}{USER_DOMAIN}"
        users.append(user_principal_name)
    return users

def reset_user_mfa(user_principal_name):
    """지정된 사용자의 모든 인증 방법을 삭제하고 로그인 세션을 무효화합니다."""
    print(f"--- '{user_principal_name}' 사용자의 MFA 초기화를 시작합니다. ---")

    # 1. 사용자의 모든 인증 방법 가져오기
    methods_url = f"https://graph.microsoft.com/v1.0/users/{user_principal_name}/authentication/methods"
    response = requests.get(methods_url, headers=headers)

    if response.status_code == 404:
        print(f"[실패] 사용자를 찾을 수 없습니다: {user_principal_name}")
        return

    if response.status_code != 200:
        print(f"[실패] 인증 방법을 가져오는 데 실패했습니다. 상태 코드: {response.status_code}, 내용: {response.text}")
        return
        
    methods = response.json().get('value', [])
    
    if not methods:
        print("[정보] 사용자에게 등록된 MFA 방법이 없습니다. 세션만 초기화합니다.")
    else:
        # 2. 등록된 각 인증 방법 삭제
        for method in methods:
            method_id = method.get('id')
            method_type = method.get('@odata.type').split('.')[-1]
            print(f"  - '{method_type}' (ID: {method_id}) 삭제 중...")
            
            delete_url = f"https://graph.microsoft.com/v1.0/users/{user_principal_name}/authentication/methods/{method_id}"
            delete_response = requests.delete(delete_url, headers=headers)
            
            if delete_response.status_code == 204:
                print(f"  - [성공] '{method_type}' 삭제 완료.")
            else:
                print(f"  - [실패] '{method_type}' 삭제 실패. 상태 코드: {delete_response.status_code}, 내용: {delete_response.text}")

    # 3. 사용자의 모든 로그인 세션 무효화 (가장 중요한 단계)
    # 이 작업을 통해 사용자는 모든 기기에서 로그아웃되며, 다음 로그인 시 다시 인증해야 합니다.
    print("  - 사용자의 모든 로그인 세션 무효화 중...")
    revoke_url = f"https://graph.microsoft.com/v1.0/users/{user_principal_name}/revokeSignInSessions"
    revoke_response = requests.post(revoke_url, headers=headers)
    
    if revoke_response.status_code == 204:
         print(f"[성공] '{user_principal_name}' 사용자의 MFA 초기화 및 세션 무효화가 완료되었습니다.\n")
    else:
        print(f"[실패] 세션 무효화 실패. 상태 코드: {revoke_response.status_code}, 내용: {revoke_response.text}\n")


if __name__ == "__main__":
    user_list = generate_user_list()
    print(f"총 {len(user_list)}명의 사용자에 대해 MFA 초기화를 진행합니다.")
    
    for user_upn in user_list:
        reset_user_mfa(user_upn)
        
    print("모든 작업이 완료되었습니다.")