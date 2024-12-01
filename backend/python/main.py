import sys
import signal
import logging
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
import random

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout)
    ]
)

logger = logging.getLogger(__name__)

app = FastAPI()

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "tauri://localhost"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
async def health():
    return {"status": "healthy", "service": "python-backend"}

@app.get("/random")
async def get_random():
    return {"number": random.randint(1, 100)}

@app.get("/")
async def root():
    return {"message": "Hello from Python Backend!"}

def handle_shutdown(signum, frame):
    logger.info("Received shutdown signal, stopping server...")
    sys.exit(0)

if __name__ == "__main__":
    # Register signal handlers for graceful shutdown
    signal.signal(signal.SIGINT, handle_shutdown)
    signal.signal(signal.SIGTERM, handle_shutdown)

    try:
        logger.info("Starting Python backend server...")
        uvicorn.run(
            app, 
            host="127.0.0.1", 
            port=8000,
            log_level="info",
            access_log=True
        )
    except Exception as e:
        logger.error(f"Failed to start Python backend: {str(e)}")
        sys.exit(1)
