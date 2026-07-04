import sys
import os
import uvicorn

# Append current directory to sys.path to resolve module imports from 'backend' correctly
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

if __name__ == "__main__":
    uvicorn.run("backend.main:app", host="0.0.0.0", port=8000, reload=True)
