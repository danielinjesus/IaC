import os
from dotenv import load_dotenv
from azure.identity import DefaultAzureCredential
from azure.mgmt.resource import ResourceManagementClient
from azure.mgmt.compute import ComputeManagementClient
from azure.mgmt.network import NetworkManagementClient
from azure.mgmt.storage import StorageManagementClient
from azure.mgmt.machinelearningservices import AzureMachineLearningWorkspaces
import time
import asyncio
from concurrent.futures import ThreadPoolExecutor

# 환경변수 로드
load_dotenv()

def force_delete_resources_in_resource_group(subscription_id, resource_group_name):
    """
    강제로 리소스 그룹 내의 모든 리소스를 삭제합니다.
    더 적극적인 삭제 방법을 사용합니다.
    """
    try:
        # Azure 인증
        credential = DefaultAzureCredential()
        resource_client = ResourceManagementClient(credential, subscription_id)
        compute_client = ComputeManagementClient(credential, subscription_id)
        network_client = NetworkManagementClient(credential, subscription_id)
        storage_client = StorageManagementClient(credential, subscription_id)
        ml_client = AzureMachineLearningWorkspaces(credential, subscription_id)
        
        print(f"리소스 그룹 '{resource_group_name}'의 리소스 강제 삭제 시작...")
        
        # 0. ML Workspace 먼저 삭제 (의존성 때문에)
        try:
            print("ML Workspace 삭제 중...")
            workspaces = list(ml_client.workspaces.list_by_resource_group(resource_group_name))
            for workspace in workspaces:
                print(f"ML Workspace 삭제: {workspace.name}")
                try:
                    # ML Workspace 삭제 (간단한 방법)
                    delete_op = ml_client.workspaces.begin_delete(
                        resource_group_name, workspace.name
                    )
                    delete_op.wait(timeout=1200)  # 20분 대기
                    print(f"  ✓ ML Workspace 삭제 완료: {workspace.name}")
                except Exception as e:
                    print(f"  ✗ ML Workspace 삭제 실패: {workspace.name} - {str(e)}")
                    # 강제 삭제 시도
                    try:
                        print(f"  ML Workspace {workspace.name} 강제 삭제 시도...")
                        time.sleep(120)  # 2분 대기
                        delete_op = ml_client.workspaces.begin_delete(
                            resource_group_name, workspace.name
                        )
                        delete_op.wait(timeout=1800)  # 30분 대기
                        print(f"  ✓ ML Workspace 강제 삭제 완료: {workspace.name}")
                    except Exception as e2:
                        print(f"  ✗ ML Workspace 강제 삭제 실패: {workspace.name} - {str(e2)}")
        except Exception as e:
            print(f"ML Workspace 처리 중 오류: {str(e)}")
        
        # 1. VM 먼저 강제 삭제
        try:
            vms = list(compute_client.virtual_machines.list(resource_group_name))
            for vm in vms:
                print(f"VM 강제 삭제: {vm.name}")
                try:
                    delete_op = compute_client.virtual_machines.begin_delete(
                        resource_group_name, vm.name, force_deletion=True
                    )
                    delete_op.wait(timeout=600)  # 10분 대기
                    print(f"  ✓ VM 삭제 완료: {vm.name}")
                except Exception as e:
                    print(f"  ✗ VM 삭제 실패: {vm.name} - {str(e)}")
        except Exception as e:
            print(f"VM 목록 조회 실패: {str(e)}")
        
        # 2. SSH 키 먼저 삭제 (의존성 해결)
        try:
            ssh_keys = list(compute_client.ssh_public_keys.list_by_resource_group(resource_group_name))
            for ssh_key in ssh_keys:
                print(f"SSH 키 삭제: {ssh_key.name}")
                try:
                    compute_client.ssh_public_keys.delete(resource_group_name, ssh_key.name)
                    print(f"  ✓ SSH 키 삭제 완료: {ssh_key.name}")
                except Exception as e:
                    print(f"  ✗ SSH 키 삭제 실패: {ssh_key.name} - {str(e)}")
        except Exception as e:
            print(f"SSH 키 처리 중 오류: {str(e)}")
        
        # 3. 네트워크 인터페이스 먼저 삭제 (NSG 의존성 해결)
        try:
            print("네트워크 인터페이스 삭제 중...")
            nics = list(network_client.network_interfaces.list(resource_group_name))
            for nic in nics:
                print(f"NIC 삭제: {nic.name}")
                try:
                    # NIC에서 NSG 연결 해제
                    if hasattr(nic, 'network_security_group') and nic.network_security_group:
                        print(f"  NIC {nic.name}에서 NSG 연결 해제 중...")
                        nic.network_security_group = None
                        network_client.network_interfaces.begin_create_or_update(
                            resource_group_name, nic.name, nic
                        ).wait()
                        time.sleep(10)  # 연결 해제 대기
                    
                    delete_op = network_client.network_interfaces.begin_delete(
                        resource_group_name, nic.name
                    )
                    delete_op.wait(timeout=300)
                    print(f"  ✓ NIC 삭제 완료: {nic.name}")
                except Exception as e:
                    print(f"  ✗ NIC 삭제 실패: {nic.name} - {str(e)}")
        except Exception as e:
            print(f"네트워크 인터페이스 처리 중 오류: {str(e)}")
        
        # 4. 네트워크 보안 그룹 강제 삭제
        try:
            print("네트워크 보안 그룹 삭제 중...")
            time.sleep(30)  # NIC 삭제 완료 대기
            
            nsgs = list(network_client.network_security_groups.list(resource_group_name))
            for nsg in nsgs:
                print(f"NSG 강제 삭제: {nsg.name}")
                try:
                    # NSG의 모든 규칙 삭제
                    if hasattr(nsg, 'security_rules'):
                        for rule in nsg.security_rules:
                            try:
                                network_client.security_rules.begin_delete(
                                    resource_group_name, nsg.name, rule.name
                                ).wait()
                            except:
                                pass
                    
                    # NSG 삭제
                    delete_op = network_client.network_security_groups.begin_delete(
                        resource_group_name, nsg.name
                    )
                    delete_op.wait(timeout=600)  # 10분 대기
                    print(f"  ✓ NSG 삭제 완료: {nsg.name}")
                except Exception as e:
                    print(f"  ✗ NSG 삭제 실패: {nsg.name} - {str(e)}")
                    # 재시도
                    try:
                        print(f"  NSG {nsg.name} 재시도 중...")
                        time.sleep(60)  # 1분 대기 후 재시도
                        delete_op = network_client.network_security_groups.begin_delete(
                            resource_group_name, nsg.name
                        )
                        delete_op.wait(timeout=600)
                        print(f"  ✓ NSG 재시도 성공: {nsg.name}")
                    except Exception as e2:
                        print(f"  ✗ NSG 재시도 실패: {nsg.name} - {str(e2)}")
        except Exception as e:
            print(f"네트워크 보안 그룹 처리 중 오류: {str(e)}")
        
        # 5. 나머지 네트워크 리소스 삭제
        try:
            # Public IP Addresses
            public_ips = list(network_client.public_ip_addresses.list(resource_group_name))
            for pip in public_ips:
                print(f"Public IP 삭제: {pip.name}")
                try:
                    delete_op = network_client.public_ip_addresses.begin_delete(
                        resource_group_name, pip.name
                    )
                    delete_op.wait(timeout=300)
                    print(f"  ✓ Public IP 삭제 완료: {pip.name}")
                except Exception as e:
                    print(f"  ✗ Public IP 삭제 실패: {pip.name} - {str(e)}")
            
            # Virtual Networks
            vnets = list(network_client.virtual_networks.list(resource_group_name))
            for vnet in vnets:
                print(f"VNet 삭제: {vnet.name}")
                try:
                    delete_op = network_client.virtual_networks.begin_delete(
                        resource_group_name, vnet.name
                    )
                    delete_op.wait(timeout=300)
                    print(f"  ✓ VNet 삭제 완료: {vnet.name}")
                except Exception as e:
                    print(f"  ✗ VNet 삭제 실패: {vnet.name} - {str(e)}")
        except Exception as e:
            print(f"네트워크 리소스 처리 중 오류: {str(e)}")
        
        # 3. 디스크 강제 삭제
        try:
            disks = list(compute_client.disks.list_by_resource_group(resource_group_name))
            for disk in disks:
                print(f"디스크 강제 삭제: {disk.name}")
                try:
                    delete_op = compute_client.disks.begin_delete(
                        resource_group_name, disk.name
                    )
                    delete_op.wait(timeout=300)
                    print(f"  ✓ 디스크 삭제 완료: {disk.name}")
                except Exception as e:
                    print(f"  ✗ 디스크 삭제 실패: {disk.name} - {str(e)}")
        except Exception as e:
            print(f"디스크 처리 중 오류: {str(e)}")
        
        # 4. 스토리지 계정 삭제
        try:
            storage_accounts = list(storage_client.storage_accounts.list_by_resource_group(resource_group_name))
            for sa in storage_accounts:
                print(f"스토리지 계정 삭제: {sa.name}")
                try:
                    storage_client.storage_accounts.delete(resource_group_name, sa.name)
                    print(f"  ✓ 스토리지 계정 삭제 완료: {sa.name}")
                except Exception as e:
                    print(f"  ✗ 스토리지 계정 삭제 실패: {sa.name} - {str(e)}")
        except Exception as e:
            print(f"스토리지 계정 처리 중 오류: {str(e)}")
        
        # 5. 남은 리소스 일반 삭제
        print(f"남은 리소스 확인 및 삭제...")
        
        # 리소스 타입별 API 버전 매핑
        API_VERSIONS = {
            'Microsoft.OperationalInsights/workspaces': '2023-09-01',
            'Microsoft.KeyVault/vaults': '2024-11-01', 
            'Microsoft.Insights/components': '2020-02-02',
            'Microsoft.Search/searchServices': '2025-05-01',
            # 기본값
            'default': '2021-04-01'
        }
        
        resources = list(resource_client.resources.list_by_resource_group(resource_group_name))
        
        for resource in resources:
            print(f"남은 리소스 삭제: {resource.name} ({resource.type})")
            try:
                resource_provider = resource.type.split('/')[0]
                resource_type = '/'.join(resource.type.split('/')[1:])
                
                # 리소스 타입에 따른 적절한 API 버전 선택
                api_version = API_VERSIONS.get(resource.type, API_VERSIONS['default'])
                
                delete_operation = resource_client.resources.begin_delete(
                    resource_group_name=resource_group_name,
                    resource_provider_namespace=resource_provider,
                    parent_resource_path='',
                    resource_type=resource_type,
                    resource_name=resource.name,
                    api_version=api_version
                )
                delete_operation.wait(timeout=300)
                print(f"  ✓ 삭제 완료: {resource.name}")
            except Exception as e:
                print(f"  ✗ 삭제 실패: {resource.name} - {str(e)}")
        
        # 6. 최종 확인
        time.sleep(10)  # 전파 대기
        final_resources = list(resource_client.resources.list_by_resource_group(resource_group_name))
        
        if final_resources:
            print(f"⚠️  여전히 {len(final_resources)}개의 리소스가 남아있습니다:")
            for resource in final_resources:
                print(f"  - {resource.name} ({resource.type})")
            return False
        else:
            print(f"✅ 리소스 그룹 '{resource_group_name}'의 모든 리소스가 삭제되었습니다.")
            return True
        
    except Exception as e:
        print(f"❌ 리소스 그룹 '{resource_group_name}' 처리 중 오류: {str(e)}")
        return False

def alternative_delete_entire_resource_group(subscription_id, resource_group_name):
    """
    대안: 리소스 그룹 전체를 삭제한 후 다시 생성
    """
    try:
        credential = DefaultAzureCredential()
        resource_client = ResourceManagementClient(credential, subscription_id)
        
        # 리소스 그룹 정보 가져오기
        rg_info = resource_client.resource_groups.get(resource_group_name)
        location = rg_info.location
        tags = rg_info.tags
        
        print(f"리소스 그룹 '{resource_group_name}' 전체 삭제 후 재생성...")
        
        # 리소스 그룹 전체 삭제
        delete_op = resource_client.resource_groups.begin_delete(resource_group_name)
        delete_op.wait(timeout=1200)  # 20분 대기
        
        # 리소스 그룹 재생성
        resource_client.resource_groups.create_or_update(
            resource_group_name,
            {
                'location': location,
                'tags': tags
            }
        )
        
        print(f"✅ 리소스 그룹 '{resource_group_name}' 재생성 완료")
        return True
        
    except Exception as e:
        print(f"❌ 리소스 그룹 '{resource_group_name}' 재생성 실패: {str(e)}")
        return False

def main():
    # Azure 구독 ID
    SUBSCRIPTION_ID = os.getenv("AZURE_SUBSCRIPTION_ID") 
    
    # # 04_RG_LC ~ 35_RG_LC 범위의 리소스 그룹 이름 생성
    # resource_groups = [f"{i:02d}_RG_LC" for i in range(4, 36)]
    
        # 변경된 코드
    resource_groups = []
    # 01_rg_pro ~ 35_rg_pro 추가
    # resource_groups.extend([f"{i:02d}_rg_pro" for i in range(1,36)])
    # 01_rg_p ~ 35_rg_p 추가  
    resource_groups.extend([f"{i:02d}_rg_p" for i in range(4,25)])    
    
    print("=== Azure 리소스 강제 삭제 도구 ===")
    print("1. 강제 삭제 (리소스 그룹 유지)")
    print("2. 리소스 그룹 삭제 후 재생성")
    
    choice = input("\n선택하세요 (1 또는 2): ")
    
    if choice not in ['1', '2']:
        print("잘못된 선택입니다.")
        return
    
    print(f"\n다음 리소스 그룹들을 처리합니다:")
    for rg in resource_groups:
        print(f"  - {rg}")
    
    confirm = input(f"\n계속 진행하시겠습니까? (y/N): ")
    if confirm.lower() != 'y':
        print("작업이 취소되었습니다.")
        return
    
    successful = 0
    failed = 0
    
    for rg_name in resource_groups:
        print(f"\n{'='*60}")
        print(f"리소스 그룹 처리 중: {rg_name}")
        print(f"{'='*60}")
        
        if choice == '1':
            success = force_delete_resources_in_resource_group(SUBSCRIPTION_ID, rg_name)
        else:
            success = alternative_delete_entire_resource_group(SUBSCRIPTION_ID, rg_name)
        
        if success:
            successful += 1
        else:
            failed += 1
        
        # 다음 처리 전 대기
        if rg_name != resource_groups[-1]:
            print("다음 리소스 그룹 처리를 위해 15초 대기...")
            time.sleep(15)
    
    print(f"\n{'='*60}")
    print("최종 결과:")
    print(f"✅ 성공: {successful}개")
    print(f"❌ 실패: {failed}개")
    print(f"📊 총 처리: {len(resource_groups)}개")
    print(f"{'='*60}")

if __name__ == "__main__":
    main()