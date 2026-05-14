from collections.abc import AsyncGenerator
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.responses import JSONResponse

VERSION = "0.4.0"

_ready = False


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    global _ready
    _ready = True
    try:
        yield
    finally:
        _ready = False


app = FastAPI(title="ProjectX API", version=VERSION, lifespan=lifespan)


@app.get("/")
def read_root() -> dict[str, str]:
    return {"message": "Hello World from ProjectX"}


@app.get("/live")
def live() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/ready", response_model=None)
def ready() -> JSONResponse | dict[str, str]:
    if not _ready:
        return JSONResponse(status_code=503, content={"status": "not ready"})
    return {"status": "ok"}


@app.get("/healthz")
def healthz() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/version")
def version() -> dict[str, str]:
    return {"version": VERSION}
