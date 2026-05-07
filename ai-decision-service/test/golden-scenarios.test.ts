import assert from "node:assert/strict";
import test from "node:test";

import { DecisionService } from "../src/services/decision-service.js";
import { MockDecisionProvider } from "../src/providers/mock-provider.js";

const service = new DecisionService(new MockDecisionProvider());

test("creates a reminder from a Spanish memory command", async () => {
  const decision = await service.decide({
    input: "recordame pagar el alquiler mañana a las 10",
    channel: "whatsapp",
    user: { id: 1, timezone: "America/Montevideo" }
  });

  assert.equal(decision.action, "create_reminder");
  assert.equal(decision.arguments.title, "pagar el alquiler");
});

test("adds an item to a list", async () => {
  const decision = await service.decide({
    input: "agregá leche a la lista del súper",
    channel: "whatsapp",
    user: { id: 1, timezone: "America/Montevideo" }
  });

  assert.equal(decision.action, "add_list_item");
  assert.equal(decision.arguments.content, "leche");
  assert.equal(decision.arguments.list_title, "súper");
});

test("saves personal context", async () => {
  const decision = await service.decide({
    input: "guardá que mi DNI vence en agosto",
    channel: "web",
    user: { id: 1, timezone: "America/Montevideo" }
  });

  assert.equal(decision.action, "save_memory_note");
  assert.match(String(decision.arguments.content), /DNI/);
});
