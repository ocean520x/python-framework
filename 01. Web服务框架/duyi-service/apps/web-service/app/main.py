# apps/web-service/main.py

from fastapi import FastAPI
from app.core.config import common_settings, web_settings

app = FastAPI(
    title=web_settings.app_name,
    docs_url=None if common_settings.environment == "production" else "/docs",
    redoc_url=None if common_settings.environment == "production" else "/redoc",
    openapi_url=(
        None if common_settings.environment == "production" else "/openapi.json"
    ),
)


from app.api.welcome import router as welcome_router

app.include_router(welcome_router)
