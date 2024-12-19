import json
import os
from typing import List, Dict, Any

from dotenv import load_dotenv
from llama_index.core import SimpleDirectoryReader
import ollama
from litellm import completion, success_callback

from prefect import flow, task
from prefect.logging import get_logger

# Import Rich components
from rich.console import Console
from rich.table import Table
from rich import box
from pprint import pprint

# Initialize Rich console
console = Console()

# Initialize Prefect logger
logger = get_logger()

# Load environment variables
load_dotenv('.env.local') 

# Define model-related classes (unchanged)
class ModelDetails:
    def __init__(self, parent_model, format, family, families, parameter_size, quantization_level):
        self.parent_model = parent_model
        self.format = format
        self.family = family
        self.families = families
        self.parameter_size = parameter_size
        self.quantization_level = quantization_level

class Model:
    def __init__(self, model, modified_at, digest, size, details):
        self.model = model
        self.modified_at = modified_at
        self.digest = digest
        self.size = size
        self.details = details

class ListResponse:
    def __init__(self, models):
        self.models = models

# Global cost tracker
COST_TRACKER = {"cost": 0.0}

@task
def list_ollama_models():
    """
    Fetch and display Ollama models using Rich Table.
    """
    try:
        ollama_models = ollama.list()
        if not ollama_models.models:
            logger.warning("No Ollama models found.")
            console.print("[bold yellow]No Ollama models found.[/bold yellow]")
            return
        
        # Create a Rich table
        table = Table(title="Available Ollama Models", box=box.MINIMAL_DOUBLE_HEAD)
        table.add_column("Model Name", style="cyan", no_wrap=True)
        table.add_column("Modified At", style="magenta")
        table.add_column("Digest", style="green")
        table.add_column("Size (bytes)", justify="right", style="yellow")
        table.add_column("Param Size", justify="right", style="yellow")
        table.add_column("Quant Level", style="blue")
        table.add_column("Family", style="red")
        table.add_column("Families", style="red")

        for model in ollama_models.models:
            table.add_row(
                model.model,
                str(model.modified_at),
                model.digest,
                str(model.size),
                str(model.details.parameter_size),
                model.details.quantization_level,
                model.details.family,
                ", ".join(model.details.families)
            )
        
        console.print(table)
    except Exception as e:
        logger.error(f"Error fetching Ollama models: {e}")
        console.print(f"[bold red]Error fetching Ollama models:[/bold red] {e}")

@task
def track_cost_callback(kwargs, completion_response, start_time, end_time, stream=False):
    """
    Callback function to track and calculate the cost based on token usage.
    """
    try:
        if hasattr(completion_response, "to_dict"):
            response_dict = completion_response.to_dict()
        elif isinstance(completion_response, dict):
            response_dict = completion_response
        else:
            response_dict = json.loads(str(completion_response))

        usage = response_dict.get("usage", {})
        total_tokens = usage.get("total_tokens", 0)
        COST_TRACKER["cost"] = (total_tokens / 1000.0) * 0.003  # Example cost calculation
        logger.info(f"Calculated cost: {COST_TRACKER['cost']}")
        console.print(f"[bold green]Calculated cost:[/bold green] [yellow]{COST_TRACKER['cost']}[/yellow]")
    except Exception as e:
        logger.error(f"Error in track_cost_callback: {e}")
        console.print(f"[bold red]Error in track_cost_callback:[/bold red] {e}")

@task
def set_success_callback():
    """
    Set the global success callback for cost tracking.
    """
    try:
        # Ensure success_callback is treated as a list
        # If success_callback is a list-like structure from litellm, we can do this:
        success_callback.clear()
        success_callback.append(track_cost_callback)
        logger.info("Success callback set successfully.")
    except Exception as e:
        logger.error(f"Error setting success callback: {e}")
        console.print(f"[bold red]Error setting success callback:[/bold red] {e}")

@task
def load_documents(path: str) -> List[Dict[str, Any]]:
    """
    Load documents from the specified path.
    """
    try:
        reader = SimpleDirectoryReader(input_dir=path)
        documents = reader.load_data()
        logger.info(f"Loaded {len(documents)} documents from {path}")
        console.print(f"[bold green]Loaded {len(documents)} documents from {path}[/bold green]")
        return [{"content": d.text, **d.metadata} for d in documents]
    except Exception as e:
        logger.error(f"Error loading documents from {path}: {e}")
        console.print(f"[bold red]Error loading documents from {path}:[/bold red] {e}")
        return []

@task
def process_metadata(doc_dicts: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """
    Process metadata to remove duplicate file entries.
    """
    try:
        file_seen = set()
        metadata_list = []
        for doc in doc_dicts:
            if doc["file_path"] not in file_seen:
                file_seen.add(doc["file_path"])
                metadata_list.append(doc)
        logger.info(f"Processed metadata: {len(metadata_list)} unique documents")
        console.print(f"[bold green]Processed metadata: {len(metadata_list)} unique documents[/bold green]")
        return metadata_list
    except Exception as e:
        logger.error(f"Error processing metadata: {e}")
        console.print(f"[bold red]Error processing metadata:[/bold red] {e}")
        return []

@task
def query_summaries(
    doc_dicts: List[Dict[str, Any]],
    host: str,
    port: int,
    model: str,
    api_base: str = None,
    stream: bool = False
) -> Dict[str, Any]:
    PROMPT = f""" 
    The following is a list of file contents, along with their metadata. For each file, provide a summary of the contents. The purpose of the summary is to organize files based on their content. To this end provide a concise but informative summary. Try to make the summary as specific to the file as possible. {doc_dicts}
    
    Do not call any functions. Do not return a function call. Only return the requested JSON.
    Return a JSON object with the following schema:
    
    ```json
    {{
      "files": [
        {{
          "file_path": "path to the file including name",
          "summary": "summary of the content"
        }}
      ]
    }}
    ```
    """.strip()

    if not api_base:
        api_base = f"http://{host}:{port}"
        logger.info(f"API Base set to: {api_base}")
        console.print(f"[bold blue]API Base set to: {api_base}[/bold blue]")

    try:
        response = completion(
            model=model, 
            messages=[
                {
                    "role": "system", 
                    "content": "Always return JSON. Do not include any other text or formatting characters."
                },
                {
                    "role": "user", 
                    "content": PROMPT
                }
            ],
            api_base=api_base,
            stream=stream,
            response_format={"type": "json_object"},  # Ensures the response is JSON
            # functions=[],  # Disable function calls
            # function_call="none"  # Do not allow the LLM to return a function call
        )
    except Exception as e:
        logger.error(f"LiteLLM Error >>> {e}")
        console.print(f"[bold red]LiteLLM Error:[/bold red] {e}")
        return {"files": [], "cost": COST_TRACKER["cost"]}

    if response is None:
        logger.warning("No response received from the API.")
        console.print("[bold yellow]No response received from the API.[/bold yellow]")
        return {"files": [], "cost": COST_TRACKER["cost"]}

    try:
        response_dict = response.to_dict() if hasattr(response, "to_dict") else json.loads(str(response))
    except (TypeError, json.JSONDecodeError) as e:
        logger.error(f"Error parsing response: {e}")
        console.print(f"[bold red]Error parsing response:[/bold red] {e}")
        return {"files": [], "cost": COST_TRACKER["cost"]}

    content = response_dict.get("choices", [{}])[0].get("message", {}).get("content", "")
    print(">>>> Content summary:")
    print(content)

    try:
        summaries = json.loads(content)
        print("Summaries:")
        print(summaries)
    except json.JSONDecodeError:
        logger.error("Error decoding JSON content from summaries.")
        console.print("[bold red]Error decoding JSON content from summaries.[/bold red]")
        summaries = {"files": []}

    if isinstance(summaries, list) and summaries and isinstance(summaries[0], dict):
        summaries = summaries[0]

    usage = response_dict.get("usage", {})
    if usage and isinstance(summaries, dict):
        summaries["usage"] = {
            "completion_tokens": usage.get("completion_tokens"),
            "prompt_tokens": usage.get("prompt_tokens"),
            "total_tokens": usage.get("total_tokens")
        }

    if isinstance(summaries, dict):
        summaries["cost"] = COST_TRACKER["cost"]
    else:
        summaries = {"files": [], "cost": COST_TRACKER["cost"]}

    logger.info(f"Generated summaries for {len(summaries.get('files', []))} files with cost {summaries.get('cost')}")
    console.print(f"[bold green]Generated summaries for {len(summaries.get('files', []))} files with cost {summaries.get('cost')}[/bold green]")
    return summaries


@task
def create_file_tree(
    summaries: List[Dict[str, Any]],
    host: str,
    port: int,
    source_path: str,
    destination_path: str,
    model: str = "llama-3.1-70b-versatile",
    api_base: str = None,
    stream: bool = False
) -> List[Dict[str, str]]:
    # Define the helper function within the task
    def find_key(obj: Any, key: str) -> Any:
        if isinstance(obj, dict):
            if key in obj:
                return obj[key]
            for value in obj.values():
                result = find_key(value, key)
                if result is not None:
                    return result
        elif isinstance(obj, list):
            for item in obj:
                result = find_key(item, key)
                if result is not None:
                    return result
        return None

    PROMPT = f"""
    You will be provided with a list of source files and a summary of their contents. The source files are located in '{source_path}', and the destination directory is '{destination_path}'.
    
    For each file, propose:
    1. 'dst_path': A new file path under the destination directory with the same file name.
    2. 'dst_path_new': A new file path under the destination directory with an updated file name (e.g., adding a version number or timestamp).
    
    Follow good naming conventions and organizational best practices. Here are guidelines:
    - Group related files together.
    - Incorporate metadata such as date, version, or experiment details into folder names.
    - Use clear and descriptive names without spaces or special characters.
    - Do not change the file extension.
    - If the file is already well-named or follows a known convention, retain its name for 'dst_path'.
    
    **Example**:
    ```json
    {{
        "files": [
            {{
                "src_path": "/home/user/source/file1.txt",
                "dst_path": "/home/user/destination/2024/04/file1.txt",
                "dst_path_new": "/home/user/destination/2024/04/file1_v2.txt"
            }}
        ]
    }}
    ```
    
    **Important:** Your response **must** be a JSON object with the following schema **at the top level**:
    ```json
    {{
        "files": [
            {{
                "src_path": "original file path",
                "dst_path": "new file path under destination directory with same file name",
                "dst_path_new": "new file path under destination directory with updated file name"
            }}
        ]
    }}
    ```
    
    Do **not** wrap the "files" key inside any other keys.
    """.strip()

    if not api_base:
        api_base = f"http://{host}:{port}"
        logger.info(f"API Base set to: {api_base}")
        console.print(f"[bold blue]API Base set to: {api_base}[/bold blue]")

    try:
        response = completion(
            model=model,
            messages=[
                {"role": "system", "content": PROMPT},
                {"role": "user", "content": json.dumps(summaries)},
            ],
            api_base=api_base,
            stream=stream,
            response_format={"type": "json_object"}  # Ensures the response is JSON
        )
    except Exception as e:
        logger.error(f"LiteLLM Error >>> {e}")
        console.print(f"[bold red]LiteLLM Error:[/bold red] {e}")
        return []

    if response is None:
        logger.warning("No response received from the API.")
        console.print("[bold yellow]No response received from the API.[/bold yellow]")
        return []

    try:
        response_dict = response.to_dict() if hasattr(response, "to_dict") else json.loads(str(response))
    except (TypeError, json.JSONDecodeError) as e:
        logger.error(f"Error parsing response: {e}")
        console.print(f"[bold red]Error parsing response:[/bold red] {e}")
        return []

    content = response_dict.get("choices", [{}])[0].get("message", {}).get("content", "")

    try:
        parsed_content = json.loads(content)
        file_tree = find_key(parsed_content, "files")
        if file_tree is None:
            raise KeyError("'files' key not found in the response.")
    except (json.JSONDecodeError, KeyError) as e:
        logger.error(f"Error decoding JSON content: {e}")
        console.print(f"[bold red]Error decoding JSON content:[/bold red] {e}")
        console.print(f"[bold yellow]Raw Content:[/bold yellow]\n{content}")
        return []

    logger.info(f"Created file tree for {len(file_tree)} files")
    console.print(f"[bold green]Created file tree for {len(file_tree)} files[/bold green]")
    return file_tree

    """
    Create a file tree based on the provided summaries.
    Returns src_path, dst_path, and dst_path_new for each file.
    """
    # Define the helper function within the task
    def find_key(obj: Any, key: str) -> Any:
        if isinstance(obj, dict):
            if key in obj:
                return obj[key]
            for value in obj.values():
                result = find_key(value, key)
                if result is not None:
                    return result
        elif isinstance(obj, list):
            for item in obj:
                result = find_key(item, key)
                if result is not None:
                    return result
        return None

    PROMPT = f"""
    You will be provided with a list of source files and a summary of their contents. The source files are located in '{source_path}', and the destination directory is '{destination_path}'.
    
    For each file, propose:
    1. 'dst_path': A new file path under the destination directory with the same file name.
    2. 'dst_path_new': A new file path under the destination directory with an updated file name (e.g., adding a version number or timestamp).
    
    Follow good naming conventions and organizational best practices. Here are guidelines:
    - Group related files together.
    - Incorporate metadata such as date, version, or experiment details into folder names.
    - Use clear and descriptive names without spaces or special characters.
    - Do not change the file extension.
    - If the file is already well-named or follows a known convention, retain its name for 'dst_path'.
    
    **Example**:
    ```json
    {{
        "files": [
            {{
                "src_path": "/home/user/source/file1.txt",
                "dst_path": "/home/user/destination/2024/04/file1.txt",
                "dst_path_new": "/home/user/destination/2024/04/file1_v2.txt"
            }}
        ]
    }}
    ```
    
    **Important:** Your response **must** be a JSON object with the following schema **at the top level**:
    ```json
    {{
        "files": [
            {{
                "src_path": "original file path",
                "dst_path": "new file path under destination directory with same file name",
                "dst_path_new": "new file path under destination directory with updated file name"
            }}
        ]
    }}
    ```
    
    Do **not** wrap the "files" key inside any other keys.
    """.strip()

    if not api_base:
        api_base = f"http://{host}:{port}"
        logger.info(f"API Base set to: {api_base}")
        console.print(f"[bold blue]API Base set to: {api_base}[/bold blue]")

    try:
        response = completion(
            model=model,
            messages=[
                {"role": "system", "content": PROMPT},
                {"role": "user", "content": json.dumps(summaries)},
            ],
            api_base=api_base,
            stream=stream
        )
    except Exception as e:
        logger.error(f"LiteLLM Error >>> {e}")
        console.print(f"[bold red]LiteLLM Error:[/bold red] {e}")
        return []

    if response is None:
        logger.warning("No response received from the API.")
        console.print("[bold yellow]No response received from the API.[/bold yellow]")
        return []

    try:
        if hasattr(response, "to_dict"):
            response_dict = response.to_dict()
        elif isinstance(response, dict):
            response_dict = response
        else:
            response_dict = json.loads(str(response))
    except (TypeError, json.JSONDecodeError) as e:
        logger.error(f"Error parsing response: {e}")
        console.print(f"[bold red]Error parsing response:[/bold red] {e}")
        return []

    content = response_dict.get("choices", [{}])[0].get("message", {}).get("content", "")

    try:
        parsed_content = json.loads(content)
        file_tree = find_key(parsed_content, "files")
        if file_tree is None:
            raise KeyError("'files' key not found in the response.")
    except (json.JSONDecodeError, KeyError) as e:
        logger.error(f"Error decoding JSON content: {e}")
        console.print(f"[bold red]Error decoding JSON content:[/bold red] {e}")
        console.print(f"[bold yellow]Raw Content:[/bold yellow]\n{content}")
        return []

    logger.info(f"Created file tree for {len(file_tree)} files")
    console.print(f"[bold green]Created file tree for {len(file_tree)} files[/bold green]")
    return file_tree

@task
def concatenate_summaries_and_file_tree(
    summaries: List[Dict[str, Any]],
    file_tree: List[Dict[str, str]]
) -> List[Dict[str, Any]]:
    """
    Concatenate summaries and file_tree into a single dictionary for each file.
    """
    concatenated = []
    summary_dict = {item['file_path']: item['summary'] for item in summaries}

    for item in file_tree:
        src_path = item.get("src_path")
        dst_path = item.get("dst_path")
        dst_path_new = item.get("dst_path_new")
        summary = summary_dict.get(src_path, "No summary available.")
        concatenated.append({
            "file_path": src_path,
            "summary": summary,
            "dst_path": dst_path,
            "dst_path_new": dst_path_new
        })

    logger.info(f"Concatenated summary and file tree for {len(concatenated)} files")
    console.print(f"[bold green]Concatenated summary and file tree for {len(concatenated)} files[/bold green]")
    return concatenated

@task
def create_subdirectories(file_tree: List[Dict[str, str]]):
    """
    Create all necessary subdirectories in the destination paths.
    """
    try:
        for file in file_tree:
            dst_path = file.get("dst_path")
            dst_path_new = file.get("dst_path_new")
            
            # Extract directories from the destination paths
            dst_dir = os.path.dirname(dst_path)
            dst_new_dir = os.path.dirname(dst_path_new)
            
            # Create the directories if they don't exist
            os.makedirs(dst_dir, exist_ok=True)
            os.makedirs(dst_new_dir, exist_ok=True)
        
        logger.info("All necessary subdirectories created.")
        console.print("[bold green]All necessary subdirectories created.[/bold green]")
    except Exception as e:
        logger.error(f"Error creating subdirectories: {e}")
        console.print(f"[bold red]Error creating subdirectories:[/bold red] {e}")

@task
def display_organized_files(organized_files: List[Dict[str, str]]):
    """
    Display organized files using Rich Table.
    """
    if not organized_files:
        console.print("[bold red]No organized files to display.[/bold red]")
        return

    table = Table(title="Organized Files", box=box.MINIMAL_DOUBLE_HEAD)
    table.add_column("Source Path", style="cyan", no_wrap=True)
    table.add_column("Destination Path", style="green")

    for file in organized_files:
        table.add_row(file.get("file_path", ""), file.get("dst_path", ""))
    
    console.print(table)

@task
def display_concatenated_dict(concatenated_dict: List[Dict[str, Any]]):
    """
    Display concatenated summaries and file tree using Rich Table.
    """
    if not concatenated_dict:
        console.print("[bold red]No concatenated data to display.[/bold red]")
        return

    table = Table(title="Summaries and Organized Files", box=box.MINIMAL_DOUBLE_HEAD)
    table.add_column("File Path", style="cyan", no_wrap=True)
    table.add_column("Summary", style="green")
    table.add_column("Destination Path", style="magenta")
    table.add_column("Destination Path New", style="yellow")

    for item in concatenated_dict:
        table.add_row(
            item.get("file_path", ""), 
            item.get("summary", ""), 
            item.get("dst_path", ""), 
            item.get("dst_path_new", "")
        )
    
    console.print(table)

@flow(name="Document Processing Workflow")
def document_processing_workflow(
    source_path: str,
    destination_path: str,
    api_host: str,
    api_port: int,
    summary_model: str,
    tree_model: str,
    api_base: str = None,
    stream: bool = False
) -> Dict[str, Any]:
    """
    Orchestrates the document processing workflow: loading documents, querying summaries, creating a file tree, and concatenating results.

    Args:
        source_path (str): Path to the source documents directory.
        destination_path (str): Path to the destination directory for organized files.
        api_host (str): API host address.
        api_port (int): API port number.
        summary_model (str): Model name for summarizing documents.
        tree_model (str): Model name for creating file tree.
        api_base (str, optional): Base URL for the API. Defaults to None.
        stream (bool, optional): Whether to use streaming. Defaults to False.

    Returns:
        Dict[str, Any]: Dictionary containing summaries, file_tree, and concatenated data.
    """
    # Initial setup
    set_success_callback()
    list_ollama_models()

    # Load and process documents
    loaded_docs = load_documents(source_path)
    unique_docs = process_metadata(loaded_docs)

    # Generate summaries
    summaries = query_summaries(
        doc_dicts=unique_docs,
        host=api_host,
        port=api_port,
        model=summary_model,
        api_base=api_base,
        stream=stream
    )

    # Create file tree
    file_tree = create_file_tree(
        summaries=summaries.get("files", []),
        host=api_host,
        port=api_port,
        source_path=source_path,
        destination_path=destination_path,
        model=tree_model,
        api_base=api_base,
        stream=stream
    )

    # Create necessary subdirectories
    create_subdirectories(file_tree)

    # Concatenate summaries and file_tree
    concatenated_dict = concatenate_summaries_and_file_tree(summaries.get("files", []), file_tree)

    # Display organized files using Rich
    display_organized_files(file_tree)

    # Display concatenated summaries and file_tree
    display_concatenated_dict(concatenated_dict)

    # Return all results
    return {
        "summaries": summaries,
        "file_tree": file_tree,
        "concatenated_data": concatenated_dict
    }