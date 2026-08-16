from __future__ import annotations

import os
from dataclasses import dataclass
from typing import Literal, cast

from dotenv import load_dotenv

load_dotenv(".env.local")

InferenceMode = Literal["mock", "local", "runpod"]
SUPPORTED_MODES = {"mock", "local", "runpod"}


class ConfigurationError(RuntimeError):
    """Raised when server-only inference configuration is invalid."""


@dataclass(frozen=True)
class Settings:
    inference_mode: InferenceMode
    runpod_api_key: str
    runpod_endpoint_id: str
    runpod_timeout_ms: int

    @property
    def provider_configured(self) -> bool:
        if self.inference_mode == "runpod":
            return bool(self.runpod_api_key and self.runpod_endpoint_id)
        return True


def get_settings() -> Settings:
    mode = os.getenv("INFERENCE_MODE", "mock").strip().lower()
    if mode not in SUPPORTED_MODES:
        supported = ", ".join(sorted(SUPPORTED_MODES))
        raise ConfigurationError(f"INFERENCE_MODE must be one of: {supported}")

    raw_timeout = os.getenv("RUNPOD_TIMEOUT_MS", "90000")
    try:
        configured_timeout = int(raw_timeout)
    except ValueError:
        configured_timeout = 90_000

    return Settings(
        inference_mode=cast(InferenceMode, mode),
        runpod_api_key=os.getenv("RUNPOD_API_KEY", "").strip(),
        runpod_endpoint_id=os.getenv("RUNPOD_ENDPOINT_ID", "").strip(),
        runpod_timeout_ms=min(max(configured_timeout, 1_000), 300_000),
    )
