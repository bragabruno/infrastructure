resource "azurerm_cognitive_account" "openai" {
  name                = "${var.project_name}-${var.environment}-openai"
  location            = var.location
  resource_group_name = var.resource_group_name
  kind                = "OpenAI"
  sku_name            = var.openai_sku

  custom_subdomain_name = "${var.project_name}-${var.environment}"

  tags = {
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
  }
}

resource "azurerm_cognitive_deployment" "gpt4" {
  name                 = var.gpt4_deployment_name
  cognitive_account_id = azurerm_cognitive_account.openai.id

  model {
    format  = "OpenAI"
    name    = "gpt-4"
    version = var.gpt4_model_version
  }

  sku {
    name     = "Standard"
    capacity = var.gpt4_capacity
  }
}

resource "azurerm_key_vault" "main" {
  name                = "${var.project_name}-${var.environment}-kv"
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  enable_rbac_authorization = true

  tags = {
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
  }
}

resource "azurerm_key_vault_secret" "openai_key" {
  name         = "AZURE-OPENAI-KEY"
  value        = azurerm_cognitive_account.openai.primary_access_key
  key_vault_id = azurerm_key_vault.main.id

  lifecycle {
    ignore_changes = [value]
  }
}

resource "azurerm_key_vault_secret" "openai_endpoint" {
  name         = "AZURE-OPENAI-ENDPOINT"
  value        = azurerm_cognitive_account.openai.endpoint
  key_vault_id = azurerm_key_vault.main.id
}

resource "azurerm_machine_learning_workspace" "foundry" {
  name                    = "${var.project_name}-${var.environment}-foundry"
  location                = var.location
  resource_group_name     = var.resource_group_name
  application_insights_id = azurerm_application_insights.foundry.id
  key_vault_id            = azurerm_key_vault.main.id
  storage_account_id      = azurerm_storage_account.foundry.id

  identity {
    type = "SystemAssigned"
  }

  tags = {
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
  }
}

resource "azurerm_application_insights" "foundry" {
  name                = "${var.project_name}-${var.environment}-ai"
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = "web"

  tags = {
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
  }
}

resource "azurerm_storage_account" "foundry" {
  name                     = replace("${var.project_name}${var.environment}sa", "-", "")
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
  }
}

resource "azurerm_user_assigned_identity" "ml_service" {
  name                = "${var.project_name}-${var.environment}-ml-service"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = {
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
  }
}

resource "azurerm_role_assignment" "ml_service_openai" {
  scope                = azurerm_cognitive_account.openai.id
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id         = azurerm_user_assigned_identity.ml_service.principal_id
}

data "azurerm_client_config" "current" {}
