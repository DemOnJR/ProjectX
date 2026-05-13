from fastapi import FastAPI

VERSION = "0.1.2"

app = FastAPI(title="ProjectX API", version=VERSION)


@app.get("/")
def read_root() -> dict[str, str]:
    return {"message": "Hello World from ProjectX"}


@app.get("/healthz")
def healthz() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/version")
def version() -> dict[str, str]:
    return {"version": VERSION}
