import os
import random
import logging
import sys
import json
from typing import List
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import glob
import uvicorn

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI()

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, replace with specific origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Define request and response models
class FolderRequest(BaseModel):
    folder: str

class FolderResponse(BaseModel):
    message: str
    path: str
    files: List[str]
    folders: List[str]
    extensions: List[str]

# Define endpoints
@app.get("/health")
async def health_check():
    logger.info("Health check endpoint called.")
    return {"status": "healthy", "service": "python-backend"}

@app.get("/hello")
async def hello():
    logger.info("Hello endpoint called.")
    return {"message": "Hello from Python Backend!"}

@app.get("/random")
async def get_random_number():
    number = random.randint(1, 100)
    logger.info(f"Random number generated: {number}")
    return {"number": number}

@app.post("/explorefolder", response_model=FolderResponse)
async def explore_folder(request: FolderRequest):
    logger.info(f"Exploring folder: {request.folder}")
    files = []
    folders = []
    extensions = set()
    
    # Walk through all directories and subdirectories
    for root, dirs, filenames in os.walk(request.folder):
        # Add folders (with relative paths from the root folder)
        rel_root = os.path.relpath(root, request.folder)
        if rel_root != '.':
            folders.append(rel_root)
        folders.extend([os.path.join(rel_root, d) for d in dirs])
        
        # Add files (with absolute paths)
        for filename in filenames:
            abs_path = os.path.abspath(os.path.join(root, filename))
            files.append(abs_path)
            extensions.add(os.path.splitext(filename)[1])
    
    # Convert extensions set to list
    extensions = list(extensions)
    
    return {
        "message": "Folder explored", 
        "path": request.folder, 
        "files": files, 
        "folders": folders, 
        "extensions": extensions
    }

# Run the server
if __name__ == "__main__":
    # Default configuration
    host = "127.0.0.1"
    port = 8111

    try:
        current_dir = os.path.dirname(os.path.abspath(__file__))
        config_path = os.path.join(current_dir, 'config.json')
        
        if os.path.exists(config_path):
            with open(config_path) as config_file:
                config = json.load(config_file)
                host = config.get('python_server', {}).get('host', host)
                port = config.get('python_server', {}).get('port', port)
        else:
            logger.warning(f"Config file not found at {config_path}, using default values")

        logger.info(f"Starting server at http://{host}:{port}")
        uvicorn.run(app, host=host, port=port)
    except Exception as e:
        logger.error(f"Failed to start server: {e}")
        sys.exit(1)
