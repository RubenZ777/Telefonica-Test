# main.tf
provider "azurerm" {
  features {}
}

resource "azurerm_role_assignment" "acr_pull" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "AcrPull"
  principal_id         = var.source_acr_client_id
}

resource "null_resource" "helm_charts_copy" {
  provisioner "local-exec" {
    command = <<EOT
      az acr helm repo add --name ${var.source_acr_server} --username ${var.source_acr_client_id} --password ${var.source_acr_client_secret}
      az acr helm repo add --name ${var.acr_server} --username $(az account show --query user.name -o tsv) --password $(az account get-access-token --resource https://${var.acr_server} --query accessToken -o tsv)
      for chart in ${jsonencode(var.charts)}; do
        az acr helm push --name ${var.acr_server} --chart $chart
      done
    EOT
  }
}

variable "acr_server" {instance.azurecr.io}
variable "acr_server_subscription" {"c9e7611c-d508-4fbf-aede-0bedfabc1560"}
variable "source_acr_client_id" {"1b2f651e-b99c-4720-9ff1-ede324b8ae30"}
variable "source_acr_client_secret" {"Zrrr8~5~F2Xiaaaa7eS.S85SXXAAfTYizZEF1cRp"}
variable "source_acr_server" {"reference.azurecr.io"}
variable "charts" {
  type = list(object({
    chart_name       = string
    chart_namespace  = string
    chart_repository = string
    chart_version    = string
    values           = list(object({
      name  = string
      value = string
    }))
    sensitive_values = list(object({
      name  = string
      value = string
    }))
  }))
}
