from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import random
import uvicorn

app = FastAPI()

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, replace with specific origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "python-backend"}

@app.get("/hello")
async def hello():
    return {"message": "Hello from Python Backend!"}

@app.get("/random")
async def get_random_number():
    return {"number": random.randint(1, 100)}

def start():
    uvicorn.run(app, host="127.0.0.1", port=8000)

if __name__ == "__main__":
    start()
