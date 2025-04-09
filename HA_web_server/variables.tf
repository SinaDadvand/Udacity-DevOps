variable "resource_group_name" {
  description = "Azure Resource Group containing resources for an Azure solution"
  default     = "AzureDevOps"
}

variable "prefix" {
  description = "The prefix which should be used for all resources in this example"
  default     = "Sina_Udacity_prj"
}

variable "instances_count" {
  description = "The number of instances to be create"
  default     = 2
}

variable "admin_username" {
  description = "The admin username for the VM being created."
  default = "azureuser"
}

variable "admin_password" {
  description = "The password for the VM being created."
  default = "P@ssw0rd1234!"
}

variable "image_version" {
  description = "The version of Packer Image for the VM being created."
  default = "1.0"
}
