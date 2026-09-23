"""
Configuration Management
Handles all environment variables and application settings
"""

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Application settings from environment variables"""
    
    # WhatsApp API Configuration
    # Optional future WhatsApp transport credentials. The local prototype
    # never requires these values.
    WHATSAPP_API_TOKEN: str = ""
    WHATSAPP_PHONE_NUMBER_ID: str = ""
    WHATSAPP_BUSINESS_ACCOUNT_ID: str = ""
    WEBHOOK_VERIFY_TOKEN: str = "local-prototype"
    WHATSAPP_API_VERSION: str = "v18.0"
    WHATSAPP_API_BASE_URL: str = "https://graph.facebook.com"
    
    # Local prototype storage
    DATABASE_PATH: str = "prototype.db"
    
    # Application Configuration
    APP_HOST: str = "0.0.0.0"
    APP_PORT: int = 8000
    ENVIRONMENT: str = "development"
    LOG_LEVEL: str = "INFO"
    
    # Optional configurations
    MAX_MESSAGE_LENGTH: int = 4096
    RATE_LIMIT_MESSAGES: int = 60  # messages per minute
    SESSION_TIMEOUT: int = 3600  # seconds
    
    class Config:
        env_file = ".env"
        case_sensitive = True


# Global settings instance
settings = Settings()


def get_whatsapp_api_url() -> str:
    """Get WhatsApp API base URL"""
    return f"{settings.WHATSAPP_API_BASE_URL}/{settings.WHATSAPP_API_VERSION}/{settings.WHATSAPP_PHONE_NUMBER_ID}"
