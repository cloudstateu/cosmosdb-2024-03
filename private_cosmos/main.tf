resource "random_string" "db_account_name" {
  count = var.cosmosdb_account_name == null ? 1 : 0

  length  = 20
  upper   = false
  special = false
  numeric = false
}

locals {
  cosmosdb_account_name = try(random_string.db_account_name[0].result, var.cosmosdb_account_name)
}

resource "azurerm_cosmosdb_account" "example" {
  name                      = local.cosmosdb_account_name
  location                  = var.cosmosdb_account_location
  resource_group_name       = var.resource_group_name
  offer_type                = "Standard"
  kind                      = "GlobalDocumentDB"
  enable_automatic_failover = false
  public_network_access_enabled     = false
  is_virtual_network_filter_enabled = true
  geo_location {
    location          = var.location
    failover_priority = 0
  }
  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 300
    max_staleness_prefix    = 100000
  }

  virtual_network_rule {
      id                    = azurerm_subnet.snet-ep.id
      ignore_missing_vnet_service_endpoint = false
  }
}

resource "azurerm_cosmosdb_sql_database" "main" {
  name                = var.cosmosdb_sqldb_name
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.example.name
  autoscale_settings {
    max_throughput = var.max_throughput
  }
}

resource "azurerm_cosmosdb_sql_container" "example" {
  name                  = var.sql_container_name
  resource_group_name   = var.resource_group_name
  account_name          = azurerm_cosmosdb_account.example.name
  database_name         = azurerm_cosmosdb_sql_database.main.name
  partition_key_path    = "/definition/id"
  partition_key_version = 1
  autoscale_settings {
    max_throughput = var.max_throughput
  }

  indexing_policy {
    indexing_mode = "consistent"

    included_path {
      path = "/*"
    }

    included_path {
      path = "/included/?"
    }

    excluded_path {
      path = "/excluded/?"
    }
  }

  unique_key {
    paths = ["/definition/idlong", "/definition/idshort"]
  }
}

resource "random_pet" "prefix" {
  prefix = var.prefix
  length = 1
}