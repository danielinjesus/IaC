import re
import os
from dotenv import load_dotenv
from azure.identity import DefaultAzureCredential
from azure.mgmt.resource import ResourceManagementClient
from azure.core.exceptions import HttpResponseError

# 환경변수 로드
load_dotenv()

# --- ⬇️ 사용자 설정 ⬇️ ---
SUBSCRIPTION_ID = os.getenv("AZURE_SUBSCRIPTION_ID") 

# 삭제할 리소스 그룹 패턴 설정
# 01_RG_LC ~ 35_RG_LC 형태의 리소스 그룹을 찾습니다 (대소문자 무시)
PATTERN = re.compile(r"^(\d{2})_RG_LC$", re.IGNORECASE)
MIN_NUMBER = 1
MAX_NUMBER = 35
# -------------------------


def find_matching_resource_groups(resource_client):
    """패턴과 일치하는 리소스 그룹을 찾아 반환"""
    resource_groups_to_delete = []
    
    print(f"구독 ID '{SUBSCRIPTION_ID}'에서 모든 리소스 그룹을 조회합니다...")
    
    try:
        all_resource_groups = resource_client.resource_groups.list()
        
        for rg in all_resource_groups:
            match = PATTERN.match(rg.name)
            if match:
                # 패턴의 숫자 부분(XX)을 추출하여 범위 내인지 확인
                number_part = int(match.group(1))
                if MIN_NUMBER <= number_part <= MAX_NUMBER:
                    resource_groups_to_delete.append(rg)
                    print(f"발견: {rg.name} (번호: {number_part:02d})")
    
    except Exception as e:
        print(f"리소스 그룹 조회 중 오류 발생: {e}")
        return []
    
    return resource_groups_to_delete


def confirm_deletion(resource_groups):
    """사용자에게 삭제 확인을 받음"""
    if not resource_groups:
        print("\n패턴과 일치하는 삭제 대상 리소스 그룹을 찾지 못했습니다.")
        return False

    print("\n" + "="*60)
    print("🚨 [경고] 아래의 리소스 그룹들이 영구적으로 삭제될 예정입니다.")
    print("="*60)
    for rg in resource_groups:
        print(f"- {rg.name} (위치: {rg.location})")
    print("="*60)
    print(f"총 {len(resource_groups)}개의 리소스 그룹이 삭제됩니다.")
    print("="*60)

    try:
        confirm = input("\n정말로 위의 리소스 그룹들을 모두 삭제하시겠습니까? (삭제를 원하시면 'yes'를 입력하세요): ")
        return confirm.lower() == 'yes'
    except (EOFError, KeyboardInterrupt):
        print("\n입력이 취소되어 작업을 중단합니다.")
        return False


def delete_resource_groups(resource_client, resource_groups, wait_for_completion=False):
    """리소스 그룹들을 삭제"""
    print("\n--- 리소스 그룹 삭제를 시작합니다 ---")
    successful_deletions = 0
    failed_deletions = 0
    
    for i, rg in enumerate(resource_groups, 1):
        print(f"\n[{i}/{len(resource_groups)}] 🗑️ '{rg.name}' 리소스 그룹 삭제 중...")
        try:
            # 삭제는 비동기적으로 시작됩니다.
            delete_op = resource_client.resource_groups.begin_delete(rg.name)
            
            if wait_for_completion:
                print(f"  ⏳ 삭제 완료를 기다리는 중... (시간이 오래 걸릴 수 있습니다)")
                delete_op.wait()
                print(f"  ✅ '{rg.name}' 리소스 그룹이 완전히 삭제되었습니다.")
            else:
                print(f"  ✅ '{rg.name}' 리소스 그룹 삭제 요청이 성공적으로 시작되었습니다.")
            
            successful_deletions += 1
            
        except HttpResponseError as e:
            print(f"  ❌ '{rg.name}' 삭제 중 HTTP 오류 발생: {e.message}")
            failed_deletions += 1
        except Exception as e:
            print(f"  ❌ '{rg.name}' 삭제 중 예기치 않은 오류 발생: {e}")
            failed_deletions += 1

    # 결과 요약
    print(f"\n" + "="*50)
    print("📊 삭제 작업 완료 요약")
    print("="*50)
    print(f"✅ 성공: {successful_deletions}개")
    print(f"❌ 실패: {failed_deletions}개")
    print(f"📋 총 처리: {len(resource_groups)}개")
    
    if not wait_for_completion and successful_deletions > 0:
        print(f"\n💡 실제 삭제는 백그라운드에서 진행될 수 있습니다.")
        print(f"   Azure Portal에서 진행 상황을 확인할 수 있습니다.")


def main():
    """
    01_RG_LC ~ 35_RG_LC 패턴을 따르는 Azure 리소스 그룹을 찾아 삭제하는 스크립트
    (대소문자 구분 없이 매칭)
    """
    try:
        print(f"🔍 사용 중인 패턴: XX_RG_LC (범위: {MIN_NUMBER:02d}~{MAX_NUMBER:02d})")
        print(f"📝 정규표현식: {PATTERN.pattern} (대소문자 무시)")
        
        # 1. Azure 인증 및 리소스 관리 클라이언트 생성
        print(f"\n🔐 Azure 인증 중...")
        credential = DefaultAzureCredential()
        resource_client = ResourceManagementClient(credential, SUBSCRIPTION_ID)
        print(f"✅ 인증 완료")

        # 2. 패턴과 일치하는 리소스 그룹 찾기
        resource_groups_to_delete = find_matching_resource_groups(resource_client)

        # 3. 삭제 확인
        if not confirm_deletion(resource_groups_to_delete):
            print("\n작업이 사용자에 의해 취소되었습니다.")
            return
            
        # 4. 삭제 실행
        # wait_for_completion=True로 설정하면 각 삭제가 완료될 때까지 기다립니다
        delete_resource_groups(resource_client, resource_groups_to_delete, wait_for_completion=False)

    except Exception as e:
        print(f"\n❌ 스크립트 실행 중 오류가 발생했습니다: {e}")
        print("💡 다음 사항을 확인해주세요:")
        print("   - 구독 ID가 올바른지 확인")
        print("   - 'az login'을 통해 Azure에 로그인되었는지 확인")
        print("   - 필요한 권한(Contributor 또는 Owner)이 있는지 확인")


if __name__ == "__main__":
    main()