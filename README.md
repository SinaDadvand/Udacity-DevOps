# README.md Content Outline - HA_web_server Project

*   **Project Title & Description**
    *   **Title**: "High Availability Web Server Deployment on Azure with Packer and Terraform"
    *   **Description**: This project demonstrates the deployment of a highly available web server infrastructure on Azure using Packer, Terraform, and Azure Policy.
    *   **Key Technologies**:
        *   **Packer**: Builds a custom VM image with a pre-configured web server and a simple web page.
        *   **Terraform**: Automates the deployment of Azure resources like Virtual Machines, Load Balancer, and Network Security Groups.
        *   **Azure Policy**: Enforces governance by ensuring resource tagging and compliance.

*   **Project Overview/Goal**
    *   This project focuses on deploying a highly available web server infrastructure on Azure, ensuring fault tolerance, scalability, and governance.
    *   Key features include:
        *   **Custom VM Image**: Built using Packer with a pre-configured web server.
        *   **High Availability**: Achieved through an Azure Load Balancer and Availability Sets.
        *   **Network Security**: Implemented using Network Security Groups (NSGs).
        *   **Policy Enforcement**: Ensures all resources are tagged appropriately.
        *   **Automation**: Deployment tasks are streamlined using `Steps.yml`.

*   **Folder Structure**
    *   The project is organized as follows:

        ```
        HA_web_server/
        ├── image_variables.json    # Variables for image creation
        ├── indexed_tagged_policy.json # Enforces resource tagging
        ├── main.tf                 # Infrastructure resources
        ├── provider.tf             # Azure provider configuration
        ├── README.md               # Project documentation
        ├── server_image.json       # Packer template for custom VM images
        ├── Steps.yml               # Automates Terraform commands
        ├── variables.tf            # Input variables
        ```

    *   **image_variables.json**: Contains variables for image creation.
    *   **indexed_tagged_policy.json**: Azure Policy definitions for governance.
    *   **main.tf**: Terraform configuration file for deploying infrastructure.
    *   **provider.tf**: Configures the Azure provider for Terraform.
    *   **README.md**: Project documentation.
    *   **server_image.json**: Packer template for creating custom VM images.
    *   **Steps.yml**: YAML file to automate deployment steps.
    *   **variables.tf**: Defines input variables for Terraform.

*   **Components & Technologies**
    *   **Packer**
        *   `image_variables.json`: Contains sensitive credentials required for Packer to authenticate with Azure. Ensure this file is kept private and not committed to version control.
        *   Example usage for building the image: 
            ```bash
            packer build -var-file="image_variables.json" server_image.json
            ```
        *   Key properties in `server_image.json`:
            *   `os_type`: Specifies the operating system type (e.g., Linux).
            *   `image_publisher`, `image_offer`, `image_sku`: Define the base image from Azure Marketplace.
            *   `managed_image_resource_group_name`, `managed_image_name`: Specify the resource group and name for the custom image.
            *   `location`: Azure region where the image will be created.
            *   `vm_size`: Size of the VM used during image creation.
            *   `azure_tags`: Tags applied to the created resources.

    *   **Terraform**
        *   `main.tf`: Defines the infrastructure resources, including:
            *   Virtual Network (VNet) and Subnet.
            *   Network Security Groups (NSGs) with rules for secure access.
            *   Public IP and Load Balancer for high availability.
            *   Availability Set to ensure fault tolerance.
            *   Virtual Machines (VMs) deployed using the custom image.
        *   `variables.tf`: Contains input variables for parameterizing the Terraform configuration (e.g., resource names, regions, and sizes).
        *   `provider.tf`: Configures the Azure provider for Terraform, including authentication details.
        *   `Steps.yml`: Automates the execution of Terraform commands and other deployment steps.
        *   `terraform.tfstate`: Stores the current state of the infrastructure. This file is critical for Terraform operations and must be secured to prevent unauthorized access.

    *   **Azure Policy**
        *   `indexed_tagged_policy.json`: Defines a policy to enforce tagging on Azure resources. This ensures all resources are properly tagged for better management and governance.
        *   How it works:
            *   The policy checks if the `tags` field exists on a resource.
            *   If the `tags` field is missing, the policy denies the creation of the resource.
            *   Example snippet:
                ```json
                "if": {
                    "field": "tags",
                    "exists": "false"
                },
                "then": {
                    "effect": "deny"
                }
                ```

*   **Prerequisites**
    *   Ensure you have the following tools and accounts set up before starting:
        *   **Azure Account**: An active Azure subscription is required.
        *   **Azure CLI**: For managing Azure resources and policies.
        *   **Terraform CLI**: To deploy and manage infrastructure as code.
        *   **Packer CLI**: For building custom VM images.
        *   **Service Principal**: A service principal with the Contributor role assigned to the subscription or resource group.
        *   **Environment Variables**: Set the following environment variables for authentication in PowerShell to be used by Terraform:
             *   Open a PowerShell terminal.
            *   Use the following commands to set the required environment variables:
                ```powershell
                $env:AZURE_SUBSCRIPTION_ID = "<your_subscription_id>"
                $env:AZURE_CLIENT_ID = "<your_client_id>"
                $env:AZURE_CLIENT_SECRET = "<your_client_secret>"
                $env:AZURE_TENANT_ID = "<your_tenant_id>"
                
                # ARM environment variables for Terraform
                $env:ARM_SUBSCRIPTION_ID = $env:AZURE_SUBSCRIPTION_ID
                $env:ARM_CLIENT_ID = $env:AZURE_CLIENT_ID
                $env:ARM_CLIENT_SECRET = $env:AZURE_CLIENT_SECRET
                $env:ARM_TENANT_ID = $env:AZURE_TENANT_ID
                ```
             *   Replace `<your_subscription_id>`, `<your_client_id>`, `<your_client_secret>`, and `<your_tenant_id>` with your actual Azure credentials.
             *   These variables will be available in the current PowerShell session and can be accessed by Terraform during deployment.
        *   **Azure CLI Login**: Before deploying Azure policies or building Packer images, log into Azure using the Azure CLI:
            *   Open a terminal and run the following command:
              ```bash
              az login
              ```
            *   Follow the instructions to authenticate with your Azure account. Ensure the correct subscription is selected:
              ```bash
              az account set --subscription $env:AZURE_SUBSCRIPTION_ID
              ```
            *   Replace `<your_subscription_id>` with your Azure subscription ID.
            *   Run the following to get the name of resource group and save it as an environment variable
             ```bash
             $env:AZURE_RESOURCE_GROUP = az group list --query "[0].name" -o tsv
             ```
*   **Setup & Deployment**
    *   Follow these steps to set up and deploy the infrastructure:

    *   **Azure Policy**
        *   Open a terminal and navigate to the `Azure_policy` directory:
            ```bash
            cd Udacity-DevOps/HA_web_server
            ```
        *   Use the Azure CLI to create and apply the policy:
            *   Create the policy definition using the `indexed_tagged_policy.json` file:
                ```bash
                az policy definition create --name "EnforceTagsPolicy" --rules "indexed_tagged_policy.json" --mode All
                ```
            *   Assign the policy to a resource group or subscription:
                ```bash
                az policy assignment create --name "EnforceTagsPolicyAssignment" --policy "EnforceTagsPolicy" --scope "/subscriptions/$env:AZURE_SUBSCRIPTION_ID/resourceGroups/$env:AZURE_RESOURCE_GROUP"
                ```

    *   **Packer Image Build**
        *   Open a terminal and navigate to the `Packer_file` directory:
            ```bash
            cd Udacity-DevOps/HA_web_server
            ```
        *   Update the `image_variables.json` file with your Azure credentials and other required values.
        *   Edit the `server_image.json` file and update line 24 to set the `location` property to match the location of your Azure resource group.
        * You can find the location of the resource group via this:
            ```bash
            az group show --name $env:AZURE_RESOURCE_GROUP --query location -o tsv
            ```
        *   Run the following command to build the custom VM image:
            ```bash
            packer build -var-file="image_variables.json" server_image.json
            ```

    *   **Terraform Deployment**
        *   Open a terminal and navigate to the `Terraform` directory:
            ```bash
            cd Udacity-DevOps/HA_web_server
            ```
            *   Initialize the Terraform working directory:
                ```bash
                terraform init
                ```
        *   Generate an execution plan and save it to a file. During this step, you may need to provide input variables required by the Terraform configuration. These variables are defined in the `variables.tf` file and can be passed in multiple ways:
            *   **Option 1**: Use a `terraform.tfvars` file to define the variables. Example:
            ```hcl
            resource_group_name = "ha-web-server-rg"
            location            = "westus2"
            vm_size             = "Standard_DS1_v2"
            admin_username      = "azureuser"
            admin_password      = "P@ssw0rd123!"
            ```
            *   **Option 2**: Pass variables directly in the command line using the `-var` flag. Example:
            ```bash
            terraform plan -var="resource_group_name=ha-web-server-rg" -var="location=westus2" -var="vm_size=Standard_DS1_v2" -var="admin_username=azureuser" -var="admin_password=P@ssw0rd123!" -out=tfplan
            ```
            *   **Option 3**: Use environment variables prefixed with `TF_VAR_`. Example:
            ```bash
            export TF_VAR_resource_group_name="ha-web-server-rg"
            export TF_VAR_location="westus2"
            export TF_VAR_vm_size="Standard_DS1_v2"
            export TF_VAR_admin_username="azureuser"
            export TF_VAR_admin_password="P@ssw0rd123!"
            terraform plan -out=tfplan
            ```
        *   Plan and apply the Terraform configuration:
            ```bash
            terraform plan -out solution.plan
            terraform apply solution.plan
            ```
        *   Export the Terraform outputs to a JSON file for reference:
            ```bash
            terraform output -json > terraform_output.json
            ```

    *   **Automation**
        *   Open a terminal and navigate to the `Terraform` directory where the `Steps.yml` file is located:
            ```bash
            cd Udacity-DevOps/HA_web_server
            ```
        *   Use the `Steps.yml` file to automate the deployment process. This file contains predefined steps for running the required commands.

*   **Outputs**
    *   After deployment, you can find the following files for reference:
        *   `terraform.tfstate`: Stores the current state of the deployed infrastructure. Keep this file secure as it contains sensitive information.
        *   `terraform_output.json`: Contains the outputs of the Terraform deployment, such as resource IDs and public IP addresses.

*   **Cleanup**
    *   **Destroying the Infrastructure with Terraform**
        *   To destroy the infrastructure deployed by Terraform, follow these steps:
            1.  Navigate to the `Terraform` directory:
                ```bash
                cd HA_web_server/Terraform
                ```
            2.  Run the `terraform destroy` command:
                ```bash
                terraform destroy
                ```
        *   This command will destroy all resources managed by Terraform in your Azure subscription. Ensure you have backed up any important data before running this command.

## Security Considerations

Ensure security best practices are followed throughout the project:

* **Credential Management:**
    * Avoid committing sensitive files like `image_variables.json` to version control. Use Azure Key Vault or environment variables for secrets.
    * Use service principals with the least privilege and rotate credentials regularly.

* **Network Security:**
    * Restrict inbound traffic using NSGs and follow the principle of least privilege.
    * Regularly review NSG rules and ensure unused ports are closed.
    * Use separate subnets for different requirements.

* **Packer Security:**
    * Use trusted base images and secure provisioning scripts.
    * Scan VM images for vulnerabilities before deployment.

* **Terraform Security:**
    * Protect the `terraform.tfstate` file by storing it in a secure remote backend with encryption.
    * Regularly review Terraform code for security issues and avoid hardcoding secrets.

* **Azure Policy Security:**
    * Apply policies at appropriate scopes and review definitions carefully.
    * Use audit mode to identify non-compliant resources.

* **General Practices:**
    * Apply least privilege, keep tools updated, and implement logging and auditing.
    * Secure automation files like `Steps.yml` by protecting secrets and avoiding excessive privileges.

By adhering to these practices, you can enhance the security of your `HA_web_server` project.

*   **Contact/Support** (Optional)
    *   Contact sina@gmail.com
    * **Example code:**

        ```powershell
        # Example PowerShell commands to set environment variables
        $env:AZURE_SUBSCRIPTION_ID = "<your_subscription_id>"
        $env:AZURE_CLIENT_ID = "<your_client_id>"
        $env:AZURE_CLIENT_SECRET = "<your_client_secret>"
        $env:AZURE_TENANT_ID = "<your_tenant_id>"

        # Verify the environment variables are set
        echo $env:AZURE_SUBSCRIPTION_ID
        echo $env:AZURE_CLIENT_ID
        echo $env:AZURE_CLIENT_SECRET
        echo $env:AZURE_TENANT_ID
        ```      
        ``` json
              "if": {
                "field": "tags",
                "exists": "false"
              },
              "then": {
                "effect": "deny"
          }
        ```
        ```terraform
              provider "azurerm" {
                features {}
                # subscription_id = var.subscription_id # Replace with your Azure subscription ID
                # client_id       = var.client_id         # Replace with your Azure app ID (client ID)
                # client_secret   = var.client_secret    # Replace with your Azure app secret
                # tenant_id       = var.tenant_id
              }
        ```

