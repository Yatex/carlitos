import assert from "node:assert/strict";
import test from "node:test";

import { buildServer } from "../src/server.js";

test("health endpoint works without AI credentials", async () => {
  const server = await buildServer({
    provider: "mock",
    host: "127.0.0.1",
    port: 8787,
    modelProvider: "gateway",
    model: "openai/gpt-5-mini",
    timeoutMs: 25000,
    maxRetries: 1,
    temperature: 0,
    logPrompts: false
  });

  const response = await server.inject({ method: "GET", url: "/health" });
  assert.equal(response.statusCode, 200);
  assert.equal(response.json().status, "ok");
});

test("decide endpoint returns a structured action", async () => {
  const server = await buildServer({
    provider: "mock",
    host: "127.0.0.1",
    port: 8787,
    modelProvider: "gateway",
    model: "openai/gpt-5-mini",
    timeoutMs: 25000,
    maxRetries: 1,
    temperature: 0,
    logPrompts: false
  });

  const response = await server.inject({
    method: "POST",
    url: "/decide",
    payload: {
      input: "recordame llamar a mamá mañana a las 9",
      channel: "whatsapp",
      user: { id: 1, timezone: "America/Montevideo" }
    }
  });

  assert.equal(response.statusCode, 200);
  assert.equal(response.json().action, "create_reminder");
});
