from fastapi import FastAPI

app = FastAPI(title="ProjectX API", version="0.1.0")


@app.get("/")
def read_root() -> dict[str, str]:
    return {"message": "Hello World from ProjectX"}


@app.get("/healthz")
def healthz() -> dict[str, str]:
    return {"status": "ok"}
