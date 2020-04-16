variable "client_id" {}
variable "client_secret" {}
variable "mariadb_admin_user" {}
variable "mariadb_admin_pass" {}

variable "agent_count" {
    default = 3
}

variable "ssh_public_key" {
    default = "./id_rsa.pub"
}

variable "dns_prefix" {
    default = "coviddata"
}

variable cluster_name {
    default = "aks-coviddata"
}

variable resource_group_name {
    default = "rg-coviddata"
}

variable location {
    default = "westeurope"
}

variable log_analytics_workspace_name {
    default = "coviddata-log-analytics-ws"
}

# refer https://azure.microsoft.com/global-infrastructure/services/?products=monitor for log analytics available regions
variable log_analytics_workspace_location {
    default = "westeurope"
}

# refer https://azure.microsoft.com/pricing/details/monitor/ for log analytics pricing 
variable log_analytics_workspace_sku {
    default = "PerGB2018"
}
