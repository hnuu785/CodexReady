from __future__ import annotations

import asyncio
import time
from typing import Any, Protocol
from urllib.parse import quote

import httpx

from .config import ConfigurationError, Settings

RUNPOD_API_BASE = "https://api.runpod.ai/v2"


class ProviderError(RuntimeError):
    """Raised when an inference provider fails to complete a request."""


class InferenceProvider(Protocol):
    async def generate(self, prompt: str) -> dict[str, Any]: ...


class MockProvider:
    async def generate(self, prompt: str) -> dict[str, Any]:
        await asyncio.sleep(0)
        return {
            "message": f"Mock worker received: {prompt}",
            "device": "mock",
            "gpu": None,
            "benchmark_ms": 0,
        }


class LocalTorchProvider:
    async def generate(self, prompt: str) -> dict[str, Any]:
        return await asyncio.to_thread(self._generate_sync, prompt)

    @staticmethod
    def _generate_sync(prompt: str) -> dict[str, Any]:
        try:
            import torch
        except ImportError as error:
            raise ConfigurationError(
                "local mode requires PyTorch. Install backend/requirements-local.txt first."
            ) from error

        if torch.cuda.is_available():
            device = torch.device("cuda")
        elif hasattr(torch.backends, "mps") and torch.backends.mps.is_available():
            device = torch.device("mps")
        else:
            device = torch.device("cpu")

        started = time.perf_counter()
        matrix = torch.randn((256, 256), device=device)
        checksum = float((matrix @ matrix).mean().item())
        if device.type == "cuda":
            torch.cuda.synchronize()

        return {
            "message": f"Local worker received: {prompt}",
            "device": str(device),
            "gpu": torch.cuda.get_device_name(0) if device.type == "cuda" else None,
            "benchmark_ms": round((time.perf_counter() - started) * 1_000, 2),
            "checksum": round(checksum, 6),
        }


class RunPodProvider:
    def __init__(self, settings: Settings) -> None:
        if not settings.runpod_api_key or not settings.runpod_endpoint_id:
            raise ConfigurationError(
                "runpod mode requires RUNPOD_API_KEY and RUNPOD_ENDPOINT_ID."
            )
        self._api_key = settings.runpod_api_key
        self._endpoint_id = settings.runpod_endpoint_id
        self._timeout_ms = settings.runpod_timeout_ms

    async def generate(self, prompt: str) -> dict[str, Any]:
        url = (
            f"{RUNPOD_API_BASE}/{quote(self._endpoint_id, safe='')}/runsync"
            f"?wait={self._timeout_ms}"
        )
        timeout = httpx.Timeout((self._timeout_ms + 5_000) / 1_000)

        try:
            async with httpx.AsyncClient(timeout=timeout) as client:
                response = await client.post(
                    url,
                    headers={
                        "authorization": self._api_key,
                        "content-type": "application/json",
                    },
                    json={"input": {"prompt": prompt}},
                )
        except httpx.TimeoutException as error:
            raise ProviderError("RunPod inference timed out.") from error
        except httpx.HTTPError as error:
            raise ProviderError("RunPod could not be reached.") from error

        if response.is_error:
            raise ProviderError(f"RunPod returned HTTP {response.status_code}.")

        try:
            body = response.json()
        except ValueError as error:
            raise ProviderError("RunPod returned a non-JSON response.") from error

        if not isinstance(body, dict):
            raise ProviderError("RunPod returned an unexpected response shape.")
        return body


def get_provider(settings: Settings) -> InferenceProvider:
    if settings.inference_mode == "mock":
        return MockProvider()
    if settings.inference_mode == "local":
        return LocalTorchProvider()
    return RunPodProvider(settings)
