# Carlitos AI Decision Service

Node service for turning short Carlitos messages into one safe assistant action.

Rails calls `POST /decide` through `Assistant::DecisionService`. The service uses a deterministic Spanish fallback first, then Vercel AI SDK when `AI_PROVIDER=vercel` and credentials are available. It can return memory actions plus Gmail and Google Calendar actions; Rails owns the actual side effects.

## Run

```sh
cd ai-decision-service
npm install
npm run dev
```

Default URL:

```text
http://localhost:8787/decide
```

Configure Rails:

```sh
AI_PROVIDER=vercel
CARLITOS_AI_SERVICE_URL=http://localhost:8787/decide
```

Configure the provider:

```sh
CARLITOS_AI_PROVIDER=vercel
CARLITOS_AI_MODEL_PROVIDER=gateway
CARLITOS_AI_MODEL=openai/gpt-5-mini
VERCEL_AI_GATEWAY_API_KEY=
OPENAI_API_KEY=
```

If no provider key is present, the service logs a warning and keeps working in limited local mode.
