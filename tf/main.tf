provider "azurerm" {
    version = "~>2.0"
    features {}
}

terraform {
    backend "azurerm" {
      storage_account_name = "stordeployment"
      container_name       = "tfstate"
  }
}

resource "azurerm_resource_group" "rg_coviddata" {
    name     = var.resource_group_name
    location = var.location
}

resource "random_id" "log_analytics_workspace_name_suffix" {
    byte_length = 8
}

resource "azurerm_log_analytics_workspace" "coviddata_log_analytics_ws" {
    # The WorkSpace name has to be unique across the whole of azure, not just the current subscription/tenant.
    name                = "${var.log_analytics_workspace_name}-${random_id.log_analytics_workspace_name_suffix.dec}"
    location            = var.log_analytics_workspace_location
    resource_group_name = azurerm_resource_group.rg_coviddata.name
    sku                 = var.log_analytics_workspace_sku
}

resource "azurerm_log_analytics_solution" "coviddata_log_analytics_solution" {
    solution_name         = "ContainerInsights"
    location              = azurerm_log_analytics_workspace.coviddata_log_analytics_ws.location
    resource_group_name   = azurerm_resource_group.rg_coviddata.name
    workspace_resource_id = azurerm_log_analytics_workspace.coviddata_log_analytics_ws.id
    workspace_name        = azurerm_log_analytics_workspace.coviddata_log_analytics_ws.name

    plan {
        publisher = "Microsoft"
        product   = "OMSGallery/ContainerInsights"
    }
}

resource "azurerm_kubernetes_cluster" "k8s" {
    name                = var.cluster_name
    location            = azurerm_resource_group.rg_coviddata.location
    resource_group_name = azurerm_resource_group.rg_coviddata.name
    dns_prefix          = var.dns_prefix

    linux_profile {
        admin_username = "ubuntu"

        ssh_key {
            key_data = file(var.ssh_public_key)
        }
    }

    default_node_pool {
        name            = "agentpool"
        node_count      = var.agent_count
        vm_size         = "Standard_DS1_v2"
    }

    service_principal {
        client_id     = var.client_id
        client_secret = var.client_secret
    }

    addon_profile {
        oms_agent {
        enabled                    = true
        log_analytics_workspace_id = azurerm_log_analytics_workspace.coviddata_log_analytics_ws.id
        }
    }

    tags = {
        Environment = "Development"
    }
}

## MySQL

resource "azurerm_mysql_server" "coviddata-db-server" {
  name                = "dbs-coviddata"
  location            = azurerm_resource_group.rg_coviddata.location
  resource_group_name = azurerm_resource_group.rg_coviddata.name

  sku_name = "B_Gen5_2"

  storage_profile {
    storage_mb            = 5120
    backup_retention_days = 7
    geo_redundant_backup  = "Disabled"
  }

  administrator_login          = var.mysql_admin_user
  administrator_login_password = var.mysql_admin_pass
  version                      = "10.2"
  ssl_enforcement              = "Enabled"
}

resource "azurerm_mysql_database" "coviddata-db" {
  name                = "db_covidata"
  resource_group_name = azurerm_resource_group.rg_coviddata.name
  server_name         = azurerm_mysql_server.coviddata-db-server.name
  charset             = "utf8"
  collation           = "utf8_general_ci"
}

## Container Registry
resource "azurerm_container_registry" "acr" {
  name                     = "acr-coviddata"
  resource_group_name      = azurerm_resource_group.rg_coviddata.name
  location                 = azurerm_resource_group.rg_coviddata.location
  sku                      = "Basic"
  admin_enabled            = false
}
