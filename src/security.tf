resource "azurerm_resource_group" "sec_rg" {
  name     = format("%s-sec-rg", local.project)
  location = var.location

  tags = var.tags
}

# Create Key Vault
module "key_vault" {
  source              = "git::https://github.com/pagopa/azurerm.git//key_vault?ref=v1.0.33"
  name                = format("%s-kv", local.project)
  location            = azurerm_resource_group.sec_rg.location
  resource_group_name = azurerm_resource_group.sec_rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id

  tags = var.tags
}

#
# POLICIES
#

# resource "azurerm_key_vault_access_policy" "terraform_policy" {
#   key_vault_id = module.key_vault.id
#   tenant_id    = data.azurerm_client_config.current.tenant_id
#   object_id    = data.azurerm_client_config.current.object_id

#   key_permissions = ["Get", "List", "Update", "Create", "Import", "Delete",
#     "Recover", "Backup", "Restore"
#   ]
#   secret_permissions = ["Get", "List", "Set", "Delete", "Recover", "Backup",
#     "Restore"
#   ]
#   certificate_permissions = ["Get", "List", "Update", "Create", "Import",
#     "Delete", "Recover", "Backup", "Restore", "ManageContacts", "ManageIssuers",
#     "GetIssuers", "ListIssuers", "SetIssuers", "DeleteIssuers", "Purge"
#   ]

#   storage_permissions = []
# }

data "azuread_group" "adgroup_admin" {
  display_name = format("%s-adgroup-admin", local.ad_group_prefix)
}

## ad group policy ##
resource "azurerm_key_vault_access_policy" "adgroup_admin_policy" {
  key_vault_id = module.key_vault.id

  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = data.azuread_group.adgroup_admin.object_id

  key_permissions     = ["Get", "List", "Update", "Create", "Import", "Delete", ]
  secret_permissions  = ["Get", "List", "Set", "Delete", ]
  storage_permissions = []
  certificate_permissions = [
    "Get", "List", "Update", "Create", "Import",
    "Delete", "Restore", "Purge", "Recover"
  ]
}

data "azuread_group" "adgroup_contributors" {
  display_name = format("%s-adgroup-contributors", local.ad_group_prefix)
}

# ad group policy ##
resource "azurerm_key_vault_access_policy" "adgroup_contributors_policy" {
  count        = (var.env_short == "d" || var.env_short == "u") ? 1 : 0
  key_vault_id = module.key_vault.id

  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = data.azuread_group.adgroup_contributors.object_id

  key_permissions     = ["Get", "List", "Update", "Create", "Import", "Delete", ]
  secret_permissions  = ["Get", "List", "Set", "Delete", ]
  storage_permissions = []
  certificate_permissions = [
    "Get", "List", "Update", "Create", "Import",
    "Delete", "Restore", "Purge", "Recover"
  ]
}

## azure devops cert az ##
resource "azurerm_key_vault_access_policy" "cert_renew_policy" {
  count        = var.devops_service_connection_object_id == null ? 0 : 1
  key_vault_id = module.key_vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = var.devops_service_connection_object_id

  secret_permissions = [
    "Get",
    "List",
    "Set",
  ]

  certificate_permissions = [
    "Get",
    "List",
    "Import",
  ]
}
