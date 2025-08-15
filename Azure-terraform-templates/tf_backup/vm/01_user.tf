# 테라폼 클라우드 + 패캠 강의 # 로긴이 쉽도록, 아이디명은 단순화 01, 02, ..., 35
resource "azuread_user" "rag_users" {
  count               = var.user_count
  user_principal_name = format("lc%02d%s", count.index + 1, var.tenant_email)
  display_name        = format("lc%02d", count.index + 1)
  password            = var.initial_pwd
  usage_location      = "KR"  # Add this line - using KR for South Korea based on your location
}
# 팀즈 단톡방에 한방에 추가할 수 있는 보안그룹(메일가능) 생성하기 
resource "azuread_group" "user_security_group" {
  display_name     = format("user_group_%s", var.user_suffix)
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
resource "azurerm_resource_group" "rg" { # 01_RG부터 35_RG까지 생성
  count    = var.user_count
  name     = format("%02d_RG_%s", count.index + 1, var.user_suffix)
  location = var.location
}
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