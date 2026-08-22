from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_health_returns_ok() -> None:
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_root_returns_application_identity(monkeypatch) -> None:
    monkeypatch.setenv("APP_ENV", "test")
    monkeypatch.setenv("APP_VERSION", "0.1.0")

    response = client.get("/")

    assert response.status_code == 200
    assert response.json() == {
        "name": "danwah.me",
        "environment": "test",
        "version": "0.1.0",
    }


def test_version_returns_deployment_identity(monkeypatch) -> None:
    monkeypatch.setenv("APP_ENV", "test")
    monkeypatch.setenv("APP_VERSION", "0.1.0")
    monkeypatch.setenv("COMMIT_SHA", "abc123")

    response = client.get("/version")

    assert response.status_code == 200
    assert response.json() == {
        "environment": "test",
        "version": "0.1.0",
        "commit_sha": "abc123",
    }
