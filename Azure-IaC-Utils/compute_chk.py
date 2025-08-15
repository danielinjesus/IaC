import sys
import os
from dotenv import load_dotenv
from azure.identity import DefaultAzureCredential
from azure.ai.ml import MLClient
from azure.mgmt.resource import ResourceManagementClient
from azure.core.exceptions import ClientAuthenticationError, HttpResponseError

# 환경변수 로드
load_dotenv()

# Enter your Azure subscription ID here.
SUBSCRIPTION_ID = os.getenv("AZURE_SUBSCRIPTION_ID")

print(f"Checking the status of compute instances in all ML workspaces under Azure subscription '{SUBSCRIPTION_ID}'.")
print("=" * 80)

try:
    # Obtain Azure credentials (requires 'az login').
    credential = DefaultAzureCredential()

    # Create a client to manage all resources in the subscription.
    resource_client = ResourceManagementClient(credential, SUBSCRIPTION_ID)

    # Find all Azure Machine Learning workspaces in the subscription.
    # 'list' returns an iterator, so convert it to a list.
    print("Searching for ML workspaces in the subscription...")
    workspaces = list(resource_client.resources.list(filter="resourceType eq 'Microsoft.MachineLearningServices/workspaces'"))

    if not workspaces:
        print("No Azure ML workspaces found in this subscription.")
        sys.exit()

    # Sort workspaces by name in ascending order.
    workspaces.sort(key=lambda x: x.name.lower())

    print(f"Found {len(workspaces)} ML workspaces. Checking compute instances for each workspace.")
    print("-" * 80)

    # Iterate through all sorted workspaces.
    for workspace in workspaces:
        # Extract resource group name from the workspace ID.
        # ID format: /subscriptions/{sub-id}/resourceGroups/{rg-name}/providers/Microsoft.MachineLearningServices/workspaces/{ws-name}
        resource_group_name = workspace.id.split('/')[4]
        workspace_name = workspace.name

        print(f"Workspace: '{workspace_name}' (Resource Group: '{resource_group_name}')")

        try:
            # Create an MLClient for the specific workspace.
            ml_client = MLClient(
                credential=credential,
                subscription_id=SUBSCRIPTION_ID,
                resource_group_name=resource_group_name,
                workspace_name=workspace_name,
            )

            found_instances = False
            # List all compute resources in the current workspace.
            for compute in ml_client.compute.list():
                # Check only for ComputeInstance type.
                if compute.type == "computeinstance":  # API returns lowercase 'computeinstance'.
                    found_instances = True
                    # Display only if state is 'Running' or 'Stopped' (remove condition to include other states).
                    if compute.state in ["Running", "Stopped"]:
                        print(f"  -> Compute Instance: {compute.name:<30} Status: {compute.state}")
                    else:  # Display other states like Creating, Deleting, Failed, etc.
                        print(f"  -> Compute Instance: {compute.name:<30} Status: {compute.state} (Warning)")

            if not found_instances:
                print(f"  -> No compute instances found in this workspace.")

        except HttpResponseError as e:
            # Handle cases where access to the workspace is denied or other API errors occur.
            print(f"  -> Error: Unable to access workspace '{workspace_name}'. (Error: {e.message})")
        except Exception as e:
            # Handle other unexpected exceptions.
            print(f"  -> Unexpected error occurred: {e}")

        print("-" * 80)

except ClientAuthenticationError:
    print("Authentication error: Ensure you are logged in via 'az login' and have access to the subscription.")
except Exception as e:
    print(f"A global error occurred during script execution: {e}")

print("All checks completed.")