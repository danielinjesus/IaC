# 30여명이 수강하는 Azure 기반 강의를 위한 인프라 관리 코드

### Terraform을 활용한 선언형 인프라 관리
- Azure 30여개의 계정과, 계정별 할당된 Resource Group을 생성</h5>
- 수강생 본인의 Resource Group에만 권한을 부여하여 수겅생간 혼란을 방지
- Azure VM, ML Workspace Compute Instance를 자동으로 생성하는 테라폼 코드</font>
### Python을 활용한 Azure 인프라 관리 (Azure-Utils폴더)
- 모든 리소스, 리소스 그룹을 삭제하는 Python Code
- ML Workspace의 모든 Compute Instance를 재가동 및 정지시키는 Python 코드
### 계정 관리
- Python은 .env파일로 관리 (.env.example 파일을 .env로 파일명 변경 후 내용 채워야 함)
- Terraform은 terraform.tfvars.example 파일을 terraform.tfvars로 바꾸고 구독아이디 등 변수값을 채워야 함
- Github Actions 사용하여 yaml파일을 작성할 경우 Github Secrets 사용 예정임
