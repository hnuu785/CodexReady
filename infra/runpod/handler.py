"""Minimal RunPod Serverless worker.

Replace `process` with the team's model inference while keeping the handler contract.
"""

from __future__ import annotations

import time
from typing import Any

import runpod
import torch


def process(payload: dict[str, Any]) -> dict[str, Any]:
    prompt = payload.get("prompt")
    if not isinstance(prompt, str) or not prompt.strip():
        raise ValueError("input.prompt must be a non-empty string")
    if len(prompt) > 2_000:
        raise ValueError("input.prompt must be 2,000 characters or fewer")

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    started = time.perf_counter()

    # A small, bounded operation proves that the selected device is usable.
    matrix = torch.randn((512, 512), device=device)
    checksum = float((matrix @ matrix).mean().item())
    if device.type == "cuda":
        torch.cuda.synchronize()

    elapsed_ms = round((time.perf_counter() - started) * 1_000, 2)
    gpu_name = torch.cuda.get_device_name(0) if torch.cuda.is_available() else None

    return {
        "message": f"Worker received: {prompt.strip()}",
        "device": str(device),
        "gpu": gpu_name,
        "benchmark_ms": elapsed_ms,
        "checksum": round(checksum, 6),
    }


def handler(job: dict[str, Any]) -> dict[str, Any]:
    payload = job.get("input", {})
    if not isinstance(payload, dict):
        raise ValueError("input must be a JSON object")
    return process(payload)


if __name__ == "__main__":
    runpod.serverless.start({"handler": handler})
