from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .routes.api import router
from .config import settings

def create_app() -> FastAPI:
    app = FastAPI(
        title="Financial Peak API",
        description="AI-powered financial goal tracking and task generation",
        version="1.0.0"
    )
    
    # Configure CORS
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.ALLOWED_ORIGINS,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    
    # Include API routes
    app.include_router(router)
    
    return app

app = create_app()