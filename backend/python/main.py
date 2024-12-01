import sys
import logging
from fastapi import FastAPI
import uvicorn

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

@app.get("/health")
async def health():
    return {"status": "healthy"}

@app.get("/")
async def root():
    return {"message": "Hello from Python Backend!"}

if __name__ == "__main__":
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
