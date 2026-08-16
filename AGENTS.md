# Codex Seoul Hackathon Working Agreement

## Mission

Build the smallest reliable product that proves value for one clearly defined user. The event deliverables are a working MVP, a public service or repository link, a demo video, a Codex Build Log, and Value & Viability notes.

## Repository map

- `frontend/`: independent Next.js app, including pages, components, server routes, configuration, and Node dependencies.
- `backend/`: independent FastAPI app, inference providers, Python dependencies, and API tests.
- `infra/docker/`: combined production image used by the current AWS deployment path.
- `infra/aws/`: AWS ECS Express Mode infrastructure.
- `infra/runpod/`: optional RunPod Serverless worker.
- `docs/`: team decisions and submission evidence.
- `scripts/`: readiness, deployment, budget, and cleanup commands.

## How to work

1. Before implementing a feature, state the target user, the user-visible outcome, and the acceptance check.
2. Prefer one complete vertical flow over several disconnected screens.
3. Keep third-party secrets on the server. Never add real keys, credentials, tokens, or `.env.local` to Git.
4. Keep RunPod optional. The core product must still boot and expose `/api/health` without GPU configuration.
5. Use the existing AWS ECS Express Mode path unless the team explicitly decides to change infrastructure.
6. After a meaningful build milestone, add a concise entry to `docs/CODEX_BUILD_LOG.md`: request, plan, changes, verification, failure/recovery, and evidence.
7. Record product-scope decisions in `docs/VALUE_VIABILITY.md`, not only in chat.

## Definition of done

- The primary user flow works from a clean browser.
- Empty, loading, success, and failure states are understandable.
- `npm test` and `npm run build` pass.
- `/api/health` returns HTTP 200.
- Secrets are absent from tracked files and client-side code.
- The deployed URL works on a phone and an unsigned browser session.
- Build Log and Value & Viability reflect the delivered version.

## Common commands

```bash
npm run dev
npm test
npm run build
npm run check
npm run deploy:aws
```

When reporting work to the team, lead with what now works, name remaining risk plainly, and include the exact verification performed.

<!-- BEGIN:nextjs-agent-rules -->

# This is NOT the Next.js you know

This version has breaking changes — APIs, conventions, and file structure may all differ from your training data. Read the relevant guide in `node_modules/next/dist/docs/` (resolved from this file's directory; in monorepos the `next` package may not be visible from the repo root) before writing any code. Heed deprecation notices.

This block is written and re-added by `next dev` — verify at `frontend/node_modules/next/dist/server/lib/generate-agent-files.js`. Removing it from a diff only re-creates the uncommitted change; committing it with your work keeps the tree clean.

<!-- END:nextjs-agent-rules -->
