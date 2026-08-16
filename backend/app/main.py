from __future__ import annotations

import logging
from typing import Any

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, ConfigDict, Field, field_validator

from .config import ConfigurationError, get_settings
from .providers import ProviderError, get_provider

logger = logging.getLogger(__name__)

app = FastAPI(
    title="Codex Seoul Inference API",
    description="Locally testable inference API with mock, local PyTorch, and RunPod providers.",
    version="0.1.0",
)


class InferenceRequest(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)

    prompt: str = Field(min_length=1, max_length=2_000)

    @field_validator("prompt")
    @classmethod
    def reject_blank_prompt(cls, value: str) -> str:
        if not value:
            raise ValueError("prompt must not be blank")
        return value


class InferenceResponse(BaseModel):
    mode: str
    result: dict[str, Any]


@app.get("/health")
async def health() -> dict[str, Any]:
    try:
        settings = get_settings()
    except ConfigurationError as error:
        return {
            "ok": False,
            "service": "fastapi-backend",
            "error": str(error),
        }

    return {
        "ok": True,
        "service": "fastapi-backend",
        "inferenceMode": settings.inference_mode,
        "providerConfigured": settings.provider_configured,
    }


@app.post("/v1/inference", response_model=InferenceResponse)
async def inference(request: InferenceRequest) -> InferenceResponse:
    try:
        settings = get_settings()
        provider = get_provider(settings)
        result = await provider.generate(request.prompt)
    except ConfigurationError as error:
        raise HTTPException(status_code=503, detail=str(error)) from error
    except ProviderError as error:
        logger.exception("Inference provider failed")
        raise HTTPException(status_code=502, detail=str(error)) from error

    return InferenceResponse(mode=settings.inference_mode, result=result)
