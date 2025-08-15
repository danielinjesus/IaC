import os
from azure.search.documents.indexes import SearchIndexClient
from azure.core.credentials import AzureKeyCredential
from dotenv import load_dotenv
import time

# 환경변수 로드
load_dotenv()

def delete_all_indexes():
    """
    Azure AI Search의 모든 인덱스를 삭제하는 함수
    """
    
    # 환경변수에서 Azure AI Search 서비스 정보 로드
    service_name = os.getenv("AZURE_SEARCH_SERVICE_NAME")
    admin_key = os.getenv("AZURE_SEARCH_ADMIN_KEY")
    endpoint = os.getenv("AZURE_SEARCH_ENDPOINT")
    
    # 환경변수 검증
    if not all([service_name, admin_key, endpoint]):
        raise ValueError("환경변수가 설정되지 않았습니다. .env 파일을 확인하세요.")
    
    # SearchIndexClient 생성
    credential = AzureKeyCredential(admin_key)
    client = SearchIndexClient(endpoint=endpoint, credential=credential)
    
    try:
        # 모든 인덱스 목록 가져오기
        print("인덱스 목록을 가져오는 중...")
        indexes = client.list_indexes()
        index_names = [index.name for index in indexes]
        
        if not index_names:
            print("삭제할 인덱스가 없습니다.")
            return
        
        print(f"총 {len(index_names)}개의 인덱스를 찾았습니다:")
        for name in index_names:
            print(f"  - {name}")
        
        # 사용자 확인
        confirm = input("\n정말로 모든 인덱스를 삭제하시겠습니까? (y/N): ")
        if confirm.lower() != 'y':
            print("삭제가 취소되었습니다.")
            return
        
        # 각 인덱스 삭제
        print("\n인덱스 삭제 시작...")
        deleted_count = 0
        failed_count = 0
        
        for index_name in index_names:
            try:
                print(f"삭제 중: {index_name}")
                client.delete_index(index_name)
                deleted_count += 1
                print(f"✓ {index_name} 삭제 완료")
                
                # 삭제 간격 (선택사항)
                time.sleep(0.5)
                
            except Exception as e:
                print(f"✗ {index_name} 삭제 실패: {str(e)}")
                failed_count += 1
        
        # 결과 요약
        print(f"\n=== 삭제 완료 ===")
        print(f"성공: {deleted_count}개")
        print(f"실패: {failed_count}개")
        
    except Exception as e:
        print(f"오류 발생: {str(e)}")

def delete_specific_indexes(index_names_to_delete):
    """
    특정 인덱스들만 삭제하는 함수
    
    Args:
        index_names_to_delete (list): 삭제할 인덱스 이름 목록
    """
    
    service_name = "your-search-service-name"
    admin_key = "your-admin-key"
    endpoint = f"https://{service_name}.search.windows.net"
    
    credential = AzureKeyCredential(admin_key)
    client = SearchIndexClient(endpoint=endpoint, credential=credential)
    
    try:
        print(f"다음 인덱스들을 삭제합니다: {index_names_to_delete}")
        
        for index_name in index_names_to_delete:
            try:
                print(f"삭제 중: {index_name}")
                client.delete_index(index_name)
                print(f"✓ {index_name} 삭제 완료")
            except Exception as e:
                print(f"✗ {index_name} 삭제 실패: {str(e)}")
                
    except Exception as e:
        print(f"오류 발생: {str(e)}")

def list_all_indexes():
    """
    모든 인덱스 목록을 조회하는 함수
    """
    
    service_name = "your-search-service-name"
    admin_key = "your-admin-key"
    endpoint = f"https://{service_name}.search.windows.net"
    
    credential = AzureKeyCredential(admin_key)
    client = SearchIndexClient(endpoint=endpoint, credential=credential)
    
    try:
        indexes = client.list_indexes()
        print("현재 인덱스 목록:")
        for index in indexes:
            print(f"  - {index.name} (필드 수: {len(index.fields)})")
            
    except Exception as e:
        print(f"오류 발생: {str(e)}")

if __name__ == "__main__":
    print("Azure AI Search 인덱스 관리")
    print("1. 모든 인덱스 삭제")
    print("2. 인덱스 목록 조회")
    print("3. 특정 인덱스 삭제")
    
    choice = input("선택하세요 (1-3): ")
    
    if choice == "1":
        delete_all_indexes()
    elif choice == "2":
        list_all_indexes()
    elif choice == "3":
        indexes_to_delete = input("삭제할 인덱스 이름들을 쉼표로 구분해서 입력하세요: ").split(",")
        indexes_to_delete = [name.strip() for name in indexes_to_delete]
        delete_specific_indexes(indexes_to_delete)
    else:
        print("잘못된 선택입니다.")