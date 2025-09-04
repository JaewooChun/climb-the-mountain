from pydantic_settings import BaseSettings
from typing import List
import os

class Settings(BaseSettings):
    # Server configuration
    HOST: str = "127.0.0.1"
    PORT: int = 8000
    DEBUG: bool = True
    
    # CORS configuration
    ALLOWED_ORIGINS: List[str] = [
        "http://localhost:3000",  # React dev server
        "http://127.0.0.1:3000",
        "http://localhost:8080",  # Flutter web
        "http://127.0.0.1:8080",
        "http://localhost:*",     # Flutter mobile debugging
        "*"  # Allow all origins during development
    ]
    
    # API Keys - Use absolute path to ensure .env is found  
    OPENAI_API_KEY: str = os.getenv("OPENAI_API_KEY", "")
    
    # Database (if needed later)
    DATABASE_URL: str = "sqlite:///./financial_peak.db"
    
    class Config:
        # Use absolute path to the root directory .env file
        env_file = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../.env"))
        case_sensitive = True

settings = Settings()