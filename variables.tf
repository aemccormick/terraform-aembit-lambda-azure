variable "aembit_tenant_id" {
  type        = string
  description = "ID of Aembit tenant."
}

variable "vpc_id" {
  type        = string
  description = "ID of AWS VPC where Aembit edge components will be deployed."
}

variable "subnet_ids" {
  type        = set(string)
  description = "List of subnet IDs where Aembit edge components will be deployed."
}

variable "aws_account_id" {
  type        = string
  description = "ID of AWS where Aembit edge components will be deployed."
}

variable "aws_region" {
  type        = string
  description = "AWS region where Aembit edge components will be deployed."
}

variable "aembit_agent_log_level" {
  type        = string
  description = "Log level of Aembit agent proxy Lambda extension."
  default     = "info"
}

variable "aembit_agent_controller_url" {
  type        = string
  description = "FQDN of Aembit Agent Controller."
}

variable "azure_tenant_id" {
  type        = string
  description = "ID of Azure Tenant"
}

variable "azure_client_id" {
  type        = string
  description = "Client ID of Azure App Registration to federate"
}

variable "azure_client_subject" {
  type        = string
  description = "Subject that Azure App Registration federated credential is configured to trust"
}
