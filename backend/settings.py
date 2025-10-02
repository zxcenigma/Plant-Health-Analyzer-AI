from pydantic_settings import (
    BaseSettings,
    SettingsConfigDict,
)

from pathlib import Path


ENV_FILE = (Path(__file__).parent / ".env").resolve()


class Settings(BaseSettings):
    HOST: str
    PORT: str
    v1: str = "/v1"
    model_config = SettingsConfigDict(env_file=str(ENV_FILE),
                                      env_file_encoding="utf-8",
                                      extra="ignore")


settings = Settings()