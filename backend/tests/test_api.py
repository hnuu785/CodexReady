import asyncio

import httpx

from backend.app.main import app


def request(method: str, path: str, **kwargs) -> httpx.Response:
    async def send() -> httpx.Response:
        transport = httpx.ASGITransport(app=app)
        async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
            return await client.request(method, path, **kwargs)

    return asyncio.run(send())


def test_health_defaults_to_mock(monkeypatch) -> None:
    monkeypatch.delenv("INFERENCE_MODE", raising=False)

    response = request("GET", "/health")

    assert response.status_code == 200
    assert response.json() == {
        "ok": True,
        "service": "fastapi-backend",
        "inferenceMode": "mock",
        "providerConfigured": True,
    }


def test_mock_inference(monkeypatch) -> None:
    monkeypatch.setenv("INFERENCE_MODE", "mock")

    response = request("POST", "/v1/inference", json={"prompt": "local flow"})

    assert response.status_code == 200
    body = response.json()
    assert body["mode"] == "mock"
    assert body["result"]["device"] == "mock"
    assert body["result"]["message"] == "Mock worker received: local flow"


def test_rejects_blank_prompt(monkeypatch) -> None:
    monkeypatch.setenv("INFERENCE_MODE", "mock")

    response = request("POST", "/v1/inference", json={"prompt": "   "})

    assert response.status_code == 422


def test_runpod_mode_requires_credentials(monkeypatch) -> None:
    monkeypatch.setenv("INFERENCE_MODE", "runpod")
    monkeypatch.delenv("RUNPOD_API_KEY", raising=False)
    monkeypatch.delenv("RUNPOD_ENDPOINT_ID", raising=False)

    response = request("POST", "/v1/inference", json={"prompt": "gpu flow"})

    assert response.status_code == 503
    assert "RUNPOD_API_KEY" in response.json()["detail"]
