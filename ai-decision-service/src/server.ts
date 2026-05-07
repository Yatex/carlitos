import Fastify from "fastify";
import type { FastifyReply, FastifyRequest } from "fastify";

import type { AppConfig } from "./config.js";
import { loadConfig } from "./config.js";
import { ConfigurationError, ProviderExecutionError } from "./lib/errors.js";
import { createDecisionProvider } from "./providers/create-provider.js";
import { decideRequestSchema } from "./schemas/request.js";
import { DecisionService } from "./services/decision-service.js";

export async function buildServer(config: AppConfig = loadConfig()) {
  const fastify = Fastify({ logger: true });
  const provider = createDecisionProvider(config, fastify.log);
  const decisionService = new DecisionService(provider);

  fastify.get("/health", async () => ({
    status: "ok",
    provider: config.provider,
    modelProvider: config.modelProvider
  }));

  fastify.post("/decide", async (request: FastifyRequest, reply: FastifyReply) => {
    const parsedRequest = decideRequestSchema.safeParse(request.body);

    if (!parsedRequest.success) {
      return reply.status(400).send({
        error: {
          code: "invalid_request",
          message: "Request body failed validation.",
          details: parsedRequest.error.flatten()
        }
      });
    }

    const decision = await decisionService.decide(parsedRequest.data);
    return reply.status(200).send(decision);
  });

  fastify.setErrorHandler((error, _request, reply) => {
    if (error instanceof ConfigurationError) {
      return reply.status(500).send({
        error: { code: "misconfigured_service", message: error.message }
      });
    }

    if (error instanceof ProviderExecutionError) {
      return reply.status(error.code === "provider_timeout" ? 504 : 502).send({
        error: { code: error.code, message: error.message }
      });
    }

    fastify.log.error({ err: error }, "Carlitos AI decision service request failed.");
    return reply.status(500).send({
      error: {
        code: "internal_error",
        message: "The AI decision service failed to complete the request."
      }
    });
  });

  return fastify;
}
