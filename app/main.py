import os

from fastapi import FastAPI

app = FastAPI(title="danwah.me")


@app.get("/")
def root() -> dict[str, str]:
    return {
        "name": "danwah.me",
        "environment": os.getenv("APP_ENV", "development"),
        "version": os.getenv("APP_VERSION", "0.1.0"),
    }


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/version")
def version() -> dict[str, str]:
    return {
        "environment": os.getenv("APP_ENV", "development"),
        "version": os.getenv("APP_VERSION", "0.1.0"),
        "commit_sha": os.getenv("COMMIT_SHA", "unknown"),
    }
