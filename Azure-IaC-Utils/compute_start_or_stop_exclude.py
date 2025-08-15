import sys
import asyncio
import time
import argparse
import os
from dotenv import load_dotenv
from azure.identity import DefaultAzureCredential
from azure.ai.ml import MLClient
from azure.mgmt.resource import ResourceManagementClient
from azure.core.exceptions import ClientAuthenticationError, HttpResponseError

# 환경변수 로드
load_dotenv()

# --- Configuration ---
SUBSCRIPTION_ID = os.getenv("AZURE_SUBSCRIPTION_ID")
MAX_CONCURRENT_OPERATIONS = 30 # We can increase concurrency

# --- Exclusion Configuration ---
EXCLUDE_PATTERNS = ["3", "21", "22", "23", "24", "25", "26"] 
# Add patterns to exclude (e.g., ["02", "test", "dev"])

# --- Global Semaphore ---
semaphore = asyncio.Semaphore(MAX_CONCURRENT_OPERATIONS)

def should_exclude_compute(compute_name: str, exclude_patterns: list) -> bool:
    """Check if compute should be excluded based on patterns"""
    for pattern in exclude_patterns:
        if pattern.lower() in compute_name.lower():
            return True
    return False

async def get_computes_to_action(credential: DefaultAzureCredential, workspace_info: dict, action: str) -> list:
    """
    Asynchronously scans a single workspace by running the sync SDK call in a separate thread.
    """
    workspace_name = workspace_info['name']
    resource_group = workspace_info['resource_group']
    
    # This is a synchronous function that will be run in a background thread.
    def _scan_workspace_sync():
        computes_for_action = []
        excluded_computes = []
        try:
            ml_client = MLClient(credential, SUBSCRIPTION_ID, resource_group, workspace_name)
            
            # This is a standard, blocking 'for' loop.
            for compute in ml_client.compute.list():
                if compute.type == "computeinstance":
                    current_state_simplified = compute.state.split('/')[-1]
                    
                    # Check if compute should be excluded
                    if should_exclude_compute(compute.name, EXCLUDE_PATTERNS):
                        excluded_computes.append(compute.name)
                        print(f"  [Scan] EXCLUDED: {compute.name:<30} in {workspace_name} (matches exclusion pattern)")
                        continue

                    if action == "stop" and current_state_simplified not in ["Stopped", "Stopping"]:
                        # We pass back the info needed to create the client again later
                        computes_for_action.append((workspace_name, resource_group, compute.name))
                    elif action == "start" and current_state_simplified not in ["Running", "Starting"]:
                        computes_for_action.append((workspace_name, resource_group, compute.name))
            return computes_for_action, excluded_computes
        except Exception as e:
            print(f"  [Scan] ERROR checking workspace '{workspace_name}': {e}", flush=True)
            return [], [] # Return empty lists on error

    # Run the blocking function in a separate thread to not block the event loop.
    found_computes, excluded = await asyncio.to_thread(_scan_workspace_sync)
    for ws_name, rg_name, compute_name in found_computes:
        print(f"  [Scan] Found to {action.upper()}: {compute_name:<30} in {ws_name}")
    
    return found_computes, excluded


async def manage_compute_instance_async(credential: DefaultAzureCredential, workspace_name: str, resource_group: str, compute_name: str, action: str) -> tuple:
    """Helper function to stop or start a compute instance asynchronously."""
    async with semaphore:
        start_time = time.time()
        action_str = "Stopping" if action == "stop" else "Starting"
        print(f"  [{action_str}] -> {compute_name:<30} in {workspace_name}...", flush=True)
        
        # Define the synchronous operation to run in a separate thread
        def _perform_action():
            try:
                # Create a client just for this operation
                ml_client = MLClient(credential, SUBSCRIPTION_ID, resource_group, workspace_name)

                if action == "stop":
                    poller = ml_client.compute.begin_stop(compute_name)
                else:
                    poller = ml_client.compute.begin_start(compute_name)
                
                # Use the synchronous wait() method, not await
                result = poller.result()  # This blocks until completion
                return result, None
            
            except HttpResponseError as e:
                return None, e
            except Exception as e:
                return None, e
        
        try:
            # Run the blocking operation in a separate thread
            result, error = await asyncio.to_thread(_perform_action)
            
            if error:
                if isinstance(error, HttpResponseError) and error.status_code == 409:
                    state = "stopping" if action == "stop" else "starting"
                    result_message = f"Skipped: Instance was already {state} or in the target state."
                    return compute_name, workspace_name, result_message, "skipped"
                elif isinstance(error, HttpResponseError):
                    result_message = f"Error: {error}"
                    return compute_name, workspace_name, result_message, "failed"
                else:
                    result_message = f"Unexpected Error: {error}"
                    return compute_name, workspace_name, result_message, "failed"
            
            duration = time.time() - start_time
            result_message = f"Successfully {action}ped in {duration:.2f}s"
            return compute_name, workspace_name, result_message, "success"

        except Exception as e:
            result_message = f"Unexpected Error: {e}"
            return compute_name, workspace_name, result_message, "failed"

async def main(action: str, exclude_patterns: list = None):
    global EXCLUDE_PATTERNS
    if exclude_patterns:
        EXCLUDE_PATTERNS = exclude_patterns
    
    script_start_time = time.time()
    print(f"Azure ML Compute Instance Bulk {action.capitalize()} Tool")
    print(f"Subscription: {SUBSCRIPTION_ID}")
    if EXCLUDE_PATTERNS:
        print(f"Exclusion patterns: {EXCLUDE_PATTERNS}")
    print("=" * 80)

    try:
        credential = DefaultAzureCredential()
        resource_client = ResourceManagementClient(credential, SUBSCRIPTION_ID)

        # --- PHASE 1: Concurrent Scanning ---
        print("[PHASE 1] Concurrently scanning all workspaces...")
        workspace_resources = list(resource_client.resources.list(filter="resourceType eq 'Microsoft.MachineLearningServices/workspaces'"))
        
        if not workspace_resources:
            print("No Azure ML workspaces found.")
            return

        workspaces = [{'name': ws.name, 'resource_group': ws.id.split('/')[4]} for ws in workspace_resources]
        
        scan_tasks = [get_computes_to_action(credential, ws_info, action) for ws_info in workspaces]
        results_from_scan = await asyncio.gather(*scan_tasks)
        
        # Separate computes to action and excluded computes
        all_computes_to_action = []
        all_excluded_computes = []
        for computes, excluded in results_from_scan:
            all_computes_to_action.extend(computes)
            all_excluded_computes.extend(excluded)
        
        print(f"[PHASE 1] Scan complete. Found {len(all_computes_to_action)} instances to {action}, {len(all_excluded_computes)} excluded.")
        print("=" * 80)

        # --- PHASE 2 & 3: Concurrent Actions & Real-time Logging ---
        if all_computes_to_action:
            print(f"[PHASE 2 & 3] Initiating {action} operations for {len(all_computes_to_action)} instances...")
            
            action_tasks = [
                manage_compute_instance_async(credential, workspace_name, resource_group, compute_name, action)
                for workspace_name, resource_group, compute_name in all_computes_to_action
            ]
            
            results = await asyncio.gather(*action_tasks)
            print("\n[PHASE 2 & 3] All operations have completed.")
            print("=" * 80)
            
            # --- PHASE 4: Final Sorted Report ---
            print("[PHASE 4] Final Sorted Summary Report")
            print("-" * 80)
            
            sorted_results = sorted(results, key=lambda item: (item[1].lower(), item[0].lower()))
            
            success_count, skipped_count, failed_count = 0, 0, 0
            
            for compute_name, workspace_name, message, status in sorted_results:
                print(f"  - W: {workspace_name:<20} C: {compute_name:<30} Status: {message}")
                if status == "success":
                    success_count += 1
                elif status == "skipped":
                    skipped_count += 1
                else:
                    failed_count += 1
            
            print("-" * 80)
            print(f"Summary: {success_count} Succeeded, {skipped_count} Skipped, {failed_count} Failed, {len(all_excluded_computes)} Excluded.")
            
        else:
            print(f"No compute instances found that required the '{action}' action.")

    except ClientAuthenticationError:
        print("Authentication error: Ensure you are logged in via 'az login'.")
    except Exception as e:
        print(f"A global error occurred: {e}")

    print("=" * 80)
    total_duration = time.time() - script_start_time
    print(f"Script finished in {total_duration:.2f}s.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Stop or start Azure ML compute instances concurrently.")
    parser.add_argument("action", choices=["stop", "start"], help="Action to perform")
    parser.add_argument("--exclude", nargs="+", help="Patterns to exclude from action (e.g., --exclude 02 test dev)")
    args = parser.parse_args()
    
    # For Windows, the default event loop policy can cause issues. This is a robust fix.
    if sys.platform.lower() == "win32" or sys.platform.lower() == "cygwin":
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
    
    asyncio.run(main(args.action, args.exclude))