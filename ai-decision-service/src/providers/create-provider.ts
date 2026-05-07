import type { AppConfig } from "../config.js";

import type { DecisionProvider } from "./base-provider.js";
import { MockDecisionProvider } from "./mock-provider.js";
import { VercelAiDecisionProvider } from "./vercel-ai-provider.js";

interface LoggerLike {
  warn?: (payload: Record<string, unknown>, message?: string) => void;
}

export function createDecisionProvider(config: AppConfig, logger: LoggerLike = {}): DecisionProvider {
  if (config.provider !== "vercel") {
    return new MockDecisionProvider();
  }

  if (config.modelProvider === "gateway" && !config.aiGatewayApiKey && !process.env.VERCEL) {
    logger.warn?.({ event: "ai.provider.missing_gateway_key" }, "VERCEL_AI_GATEWAY_API_KEY missing; using local Carlitos fallback provider.");
    return new MockDecisionProvider();
  }

  if (config.modelProvider === "openai" && !config.openAiApiKey) {
    logger.warn?.({ event: "ai.provider.missing_openai_key" }, "OPENAI_API_KEY missing; using local Carlitos fallback provider.");
    return new MockDecisionProvider();
  }

  return new VercelAiDecisionProvider(config);
}
