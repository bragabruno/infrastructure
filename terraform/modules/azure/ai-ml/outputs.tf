output "openai_endpoint" {
  value = azurerm_cognitive_account.openai.endpoint
}

output "openai_deployment_name" {
  value = azurerm_cognitive_deployment.gpt4.name
}

output "foundry_workspace_id" {
  value = azurerm_machine_learning_workspace.foundry.id
}

output "keyvault_uri" {
  value = azurerm_key_vault.main.vault_uri
}

output "ml_service_identity_id" {
  value = azurerm_user_assigned_identity.ml_service.id
}

output "ml_service_principal_id" {
  value = azurerm_user_assigned_identity.ml_service.principal_id
}
