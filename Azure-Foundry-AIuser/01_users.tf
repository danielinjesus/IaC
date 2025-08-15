# 테라폼 클라우드 + 패캠 강의
# 로긴이 쉽도록, 아이디명은 단순화 01, 02, ..., 35
resource "azuread_user" "rag_users" {
  count               = var.user_count
  user_principal_name = format("%02d%s", count.index + 1, var.tenant_email)
  display_name        = format("%02d", count.index + 1)
  password            = var.initial_pwd
  usage_location      = "KR"  # Add this line - using KR for South Korea based on your location
}
# 팀즈 단톡방에 한방에 추가할 수 있는 보안그룹(메일가능) 생성하기 
resource "azuread_group" "user_security_group" {
  display_name     = format("user_group_%s", var.user_suffix)
  description  = ""  # 빈 문자열로 설정
  security_enabled = true
  mail_enabled     = true  # 이것만 추가해보세요
  mail_nickname    = format("usergroup%s", lower(replace(var.user_suffix, " ", "")))
  types            = ["Unified"]
}
# 생성된 모든 사용자를 위 보안 그룹에 멤버로 추가
resource "azuread_group_member" "user_group_membership" {
  count            = var.user_count
  group_object_id  = azuread_group.user_security_group.object_id
  member_object_id = azuread_user.rag_users[count.index].object_id
}
# 01_RG부터 계정별 RG 생성
resource "azurerm_resource_group" "rg" { 
  count    = var.user_count
  name     = format("%02d_RG", count.index + 1)
  location = var.location
}
# 사용자별 RG에 역할 추가
resource "azurerm_role_assignment" "user_rg_roles" {
  for_each = {
    for pair in setproduct(range(var.user_count), var.roles) :
    # 고유한 for_each 키 생성 (예: "user00_role_Contributor")
    # 역할 이름에 공백이 있을 수 있으므로 "_"로 대체합니다.
    format("user%02d_role_%s", pair[0], replace(pair[1], " ", "_")) => {
      user_idx = pair[0] # 사용자 및 리소스 그룹 인덱스
      role     = pair[1] # 할당할 역할 이름
    }
  }
  scope                = azurerm_resource_group.rg[each.value.user_idx].id
  role_definition_name = each.value.role
  principal_id         = azuread_user.rag_users[each.value.user_idx].object_id
  depends_on           = [azuread_user.rag_users, azurerm_resource_group.rg]
}
# 이미 존재하는 00_AI_RG를 데이터 소스로 참조
data "azurerm_resource_group" "ai_rg" {
  name = "00_AI_RG"
}
# 모든 사용자에게 Azure AI User 역할 할당
resource "azurerm_role_assignment" "ai_user_role_assignments" {
  count                = var.user_count
  scope                = data.azurerm_resource_group.ai_rg.id
  role_definition_name = "Azure AI User"
  principal_id         = azuread_user.rag_users[count.index].object_id
  depends_on           = [azuread_user.rag_users]
}
# 보안 그룹에 Reader 역할도 추가 (구독 전체 읽기 권한 부여용)
# resource "azurerm_role_assignment" "subscription_reader_role" {
#   scope                = data.azurerm_subscription.current.id  # 현재 구독 범위
#   role_definition_name = "Reader"  # 읽기 전용 권한
#   principal_id         = azuread_group.user_security_group.object_id  # 대상: 보안 그룹
#   depends_on           = [azuread_group.user_security_group]  # 그룹 생성 후 실행되도록
# }