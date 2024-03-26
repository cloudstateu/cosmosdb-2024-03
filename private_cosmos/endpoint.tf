
resource "azurerm_virtual_network" "vnet01" {
  name                = var.virtual_network_name
  location            = var.cosmosdb_account_location
  resource_group_name = var.resource_group_name
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["10.0.0.4", "10.0.0.5"]
}

resource "azurerm_subnet" "snet-ep" {
  name                                           = var.subnet_name
  resource_group_name                            = var.resource_group_name
  virtual_network_name                           = azurerm_virtual_network.vnet01.name
  address_prefixes                               = ["10.0.1.0/24"]
  enforce_private_link_endpoint_network_policies = true
  service_endpoints                              = [ "Microsoft.AzureCosmosDB" ]
}

resource "azurerm_private_endpoint" "pep1" {

  name                = "cosmosdbprivateendpoint"
  location            = var.cosmosdb_account_location
  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.snet-ep.id
  
  private_service_connection {
    name                           = "cosmos-privatelink"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_cosmosdb_account.example.id
    subresource_names              = ["Sql"]
  }
}

data "azurerm_private_endpoint_connection" "private-ip1" {
 
  name                = azurerm_private_endpoint.pep1.name
  resource_group_name = var.resource_group_name
  depends_on          = [azurerm_cosmosdb_account.example]
}

resource "azurerm_private_dns_zone" "dnszone1" {
  name                = "privatelink.documents.azure.com"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "vent-link1" {
  
  name                  = "vnet-private-zone-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.dnszone1.name
  virtual_network_id    = azurerm_virtual_network.vnet01.id
}

