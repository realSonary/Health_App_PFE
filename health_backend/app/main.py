from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from .core.config import settings
from .core.database import create_tables
from .api.v1.router import api_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: create database tables (non-fatal — server still serves if DB is unavailable)
    try:
        await create_tables()
        print(f"[OK] {settings.APP_NAME} started - DB tables ready")
    except Exception as e:
        print(f"[WARN] DB connection failed: {e}")
        print("  Server is running but DB endpoints will fail until DB is reachable.")
        print("  Fix DATABASE_URL in .env and restart.")
    yield
    # Shutdown
    print(f"[OK] {settings.APP_NAME} shutting down")


app = FastAPI(
    title=settings.APP_NAME,
    description="AI-powered health tracking API",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# API routes
app.include_router(api_router, prefix=settings.API_V1_PREFIX)


@app.get("/health", tags=["Health Check"])
async def health_check():
    return {"status": "ok", "app": settings.APP_NAME, "version": "1.0.0"}


@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    if settings.DEBUG:
        return JSONResponse(
            status_code=500,
            content={"detail": str(exc), "type": type(exc).__name__},
        )
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal server error"},
    )
