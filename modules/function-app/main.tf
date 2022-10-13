terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~> 3.26.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "funcdeploy" {
  name     = "rg-${var.prefix}-function"
  location = var.location
}

resource "azurerm_storage_account" "funcdeploy" {
  name                     = "${var.prefix}storagemjkuyt"
  resource_group_name      = azurerm_resource_group.funcdeploy.name
  location                 = azurerm_resource_group.funcdeploy.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "funcdeploy" {
  name                  = "contents"
  storage_account_name  = azurerm_storage_account.funcdeploy.name
  container_access_type = "private"
}

resource "azurerm_application_insights" "funcdeploy" {
  name                = "${var.prefix}-appinsights"
  location            = azurerm_resource_group.funcdeploy.location
  resource_group_name = azurerm_resource_group.funcdeploy.name
  application_type    = "web"

  # https://github.com/terraform-providers/terraform-provider-azurerm/issues/1303
  tags = {
    "hidden-link:${azurerm_resource_group.funcdeploy.id}/providers/Microsoft.Web/sites/${var.prefix}func" = "Resource"
  }

}

resource "azurerm_service_plan" "funcdeploy" {
  name                = "${var.prefix}-functions-consumption-asp"
  location            = azurerm_resource_group.funcdeploy.location
  resource_group_name = azurerm_resource_group.funcdeploy.name
  sku_name = "Y1"
  os_type = "Linux"
}

resource "azurerm_linux_function_app" "funcdeploy" {
    depends_on = [
      azurerm_storage_account.funcdeploy
    ]
  name                       = "${var.prefix}funcpythonapp"
  location                   = azurerm_resource_group.funcdeploy.location
  resource_group_name        = azurerm_resource_group.funcdeploy.name
  service_plan_id        = azurerm_service_plan.funcdeploy.id
  storage_account_name       = azurerm_storage_account.funcdeploy.name
  storage_account_access_key = azurerm_storage_account.funcdeploy.primary_access_key
  app_settings = {
      "WEBSITE_RUN_FROM_PACKAGE" = "0"
      "FUNCTIONS_WORKER_RUNTIME" = "python"
      "APPINSIGHTS_INSTRUMENTATIONKEY" = "${azurerm_application_insights.funcdeploy.instrumentation_key}"
      "APPLICATIONINSIGHTS_CONNECTION_STRING" = "InstrumentationKey=${azurerm_application_insights.funcdeploy.instrumentation_key};IngestionEndpoint=https://japaneast-0.in.applicationinsights.azure.com/"
  }

  site_config {
       application_stack {
      python_version = "3.9"
    }
    }

  # Enable if you need Managed Identity
  # identity {
  #   type = "SystemAssigned"
  # }
}