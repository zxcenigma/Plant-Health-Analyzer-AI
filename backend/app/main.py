from fastapi import FastAPI
import uvicorn

from backend.settings import settings
from backend.app.api.v1.main_router import main_router

app = FastAPI()

app.include_router(main_router)

if __name__ == "__main__":
    uvicorn.run(
        "backend.app.main:app",
        host=settings.HOST,
        port=int(settings.PORT),
        reload=True,
    )
