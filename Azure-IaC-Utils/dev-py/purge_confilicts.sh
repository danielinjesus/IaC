#!/bin/bash

# Azure ML Workspace Soft-Delete Cleanup Script
# This script handles soft-deleted Azure ML workspaces that are blocking Terraform deployment

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Azure CLI is installed and logged in
check_azure_cli() {
    print_status "Checking Azure CLI installation..."
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed. Please install it first."
        exit 1
    fi
    
    print_status "Checking Azure login status..."
    if ! az account show &> /dev/null; then
        print_error "Not logged into Azure. Please run 'az login' first."
        exit 1
    fi
    
    print_success "Azure CLI is ready"
}

# Array of workspace names and resource groups from the error
declare -a WORKSPACES=(
    "01mlworkspaceRAG:01_RG_RAG"
    "02mlworkspaceRAG:02_RG_RAG"
    "03mlworkspaceRAG:03_RG_RAG"
    "04mlworkspaceRAG:04_RG_RAG"
    "10mlworkspaceRAG:10_RG_RAG"
    "15mlworkspaceRAG:15_RG_RAG"
    "16mlworkspaceRAG:16_RG_RAG"
    "17mlworkspaceRAG:17_RG_RAG"
    "20mlworkspaceRAG:20_RG_RAG"
    "21mlworkspaceRAG:21_RG_RAG"
)

# Function to list all soft-deleted workspaces
list_soft_deleted_workspaces() {
    print_status "Listing all soft-deleted ML workspaces..."
    
    for workspace_info in "${WORKSPACES[@]}"; do
        IFS=':' read -r workspace_name resource_group <<< "$workspace_info"
        
        print_status "Checking workspace: $workspace_name in resource group: $resource_group"
        
        # Try to list soft-deleted workspaces in the resource group
        if az ml workspace list-deleted --resource-group "$resource_group" --query "[?name=='$workspace_name']" -o table 2>/dev/null | grep -q "$workspace_name"; then
            print_warning "Soft-deleted workspace found: $workspace_name"
        else
            print_status "No soft-deleted workspace found for: $workspace_name"
        fi
    done
}

# Function to purge soft-deleted workspaces
purge_soft_deleted_workspaces() {
    print_status "Starting purge of soft-deleted ML workspaces..."
    
    for workspace_info in "${WORKSPACES[@]}"; do
        IFS=':' read -r workspace_name resource_group <<< "$workspace_info"
        
        print_status "Attempting to purge workspace: $workspace_name"
        
        # Try to purge the workspace
        if az ml workspace delete --name "$workspace_name" --resource-group "$resource_group" --permanently-delete --yes 2>/dev/null; then
            print_success "Successfully purged workspace: $workspace_name"
        else
            print_warning "Could not purge workspace: $workspace_name (may not exist or already purged)"
        fi
        
        # Small delay to avoid rate limiting
        sleep 2
    done
}

# Function to recover soft-deleted workspaces
recover_soft_deleted_workspaces() {
    print_status "Starting recovery of soft-deleted ML workspaces..."
    
    for workspace_info in "${WORKSPACES[@]}"; do
        IFS=':' read -r workspace_name resource_group <<< "$workspace_info"
        
        print_status "Attempting to recover workspace: $workspace_name"
        
        # Try to recover the workspace
        if az ml workspace recover --name "$workspace_name" --resource-group "$resource_group" 2>/dev/null; then
            print_success "Successfully recovered workspace: $workspace_name"
        else
            print_warning "Could not recover workspace: $workspace_name (may not exist or already active)"
        fi
        
        # Small delay to avoid rate limiting
        sleep 2
    done
}

# Function to generate Terraform import commands
generate_terraform_imports() {
    print_status "Generating Terraform import commands..."
    
    # Get subscription ID
    SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    
    echo "# Terraform import commands for existing ML workspaces"
    echo "# Run these commands in your Terraform directory"
    echo ""
    
    local index=0
    for workspace_info in "${WORKSPACES[@]}"; do
        IFS=':' read -r workspace_name resource_group <<< "$workspace_info"
        
        echo "terraform import azurerm_machine_learning_workspace.ml_workspace[$index] \\"
        echo "  /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$resource_group/providers/Microsoft.MachineLearningServices/workspaces/$workspace_name"
        echo ""
        
        ((index++))
    done
}

# Function to generate alternative Terraform configuration with new names
generate_new_terraform_config() {
    print_status "Generating Terraform configuration with new workspace names..."
    
    cat > "ml_workspace_new_names.tf" << 'EOF'
# Alternative ML workspace configuration with new names to avoid soft-delete conflicts

locals {
  workspace_configs = [
    { name = "01mlworkspaceRAG-v2", rg = "01_RG_RAG" },
    { name = "02mlworkspaceRAG-v2", rg = "02_RG_RAG" },
    { name = "03mlworkspaceRAG-v2", rg = "03_RG_RAG" },
    { name = "04mlworkspaceRAG-v2", rg = "04_RG_RAG" },
    { name = "10mlworkspaceRAG-v2", rg = "10_RG_RAG" },
    { name = "15mlworkspaceRAG-v2", rg = "15_RG_RAG" },
    { name = "16mlworkspaceRAG-v2", rg = "16_RG_RAG" },
    { name = "17mlworkspaceRAG-v2", rg = "17_RG_RAG" },
    { name = "20mlworkspaceRAG-v2", rg = "20_RG_RAG" },
    { name = "21mlworkspaceRAG-v2", rg = "21_RG_RAG" }
  ]
}

resource "azurerm_machine_learning_workspace" "ml_workspace_new" {
  count = length(local.workspace_configs)
  
  name                = local.workspace_configs[count.index].name
  location            = azurerm_resource_group.rg[count.index].location
  resource_group_name = local.workspace_configs[count.index].rg
  
  application_insights_id = azurerm_application_insights.app_insights[count.index].id
  key_vault_id           = azurerm_key_vault.kv[count.index].id
  storage_account_id     = azurerm_storage_account.storage[count.index].id
  
  identity {
    type = "SystemAssigned"
  }
  
  tags = {
    Environment = "Production"
    Purpose     = "RAG-ML-Workspace"
  }
}
EOF
    
    print_success "Generated new Terraform configuration: ml_workspace_new_names.tf"
}

# Main menu function
show_menu() {
    echo ""
    echo "=================================="
    echo "Azure ML Workspace Cleanup Tool"
    echo "=================================="
    echo "1. List soft-deleted workspaces"
    echo "2. Purge soft-deleted workspaces (PERMANENT)"
    echo "3. Recover soft-deleted workspaces"
    echo "4. Generate Terraform import commands"
    echo "5. Generate new Terraform config (with different names)"
    echo "6. Exit"
    echo ""
}

# Main execution
main() {
    check_azure_cli
    
    while true; do
        show_menu
        read -p "Please select an option (1-6): " choice
        
        case $choice in
            1)
                list_soft_deleted_workspaces
                ;;
            2)
                print_warning "This will PERMANENTLY delete all soft-deleted workspaces!"
                read -p "Are you sure? (yes/no): " confirm
                if [[ $confirm == "yes" ]]; then
                    purge_soft_deleted_workspaces
                else
                    print_status "Operation cancelled"
                fi
                ;;
            3)
                recover_soft_deleted_workspaces
                ;;
            4)
                generate_terraform_imports
                ;;
            5)
                generate_new_terraform_config
                ;;
            6)
                print_success "Goodbye!"
                exit 0
                ;;
            *)
                print_error "Invalid option. Please select 1-6."
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

# Run the script
main