import { config as loadDotEnv } from "dotenv";
import path from "node:path";
import { z } from "zod";

import { ConfigurationError } from "./lib/errors.js";

loadDotEnv();
loadDotEnv({ path: path.resolve(process.cwd(), "..", ".env"), override: false });

const providerSchema = z.enum(["mock", "vercel"]);
const modelProviderSchema = z.enum(["gateway", "openai"]);

const appConfigSchema = z.object({
  provider: providerSchema.default("mock"),
  host: z.string().trim().min(1).default("0.0.0.0"),
  port: z.coerce.number().int().min(1).max(65535).default(8787),
  modelProvider: modelProviderSchema.default("gateway"),
  model: z.string().trim().min(1).default("openai/gpt-5-mini"),
  timeoutMs: z.coerce.number().int().min(1000).max(120000).default(25000),
  maxRetries: z.coerce.number().int().min(0).max(5).default(1),
  temperature: z.coerce.number().min(0).max(1).default(0),
  logPrompts: z.coerce.boolean().default(false),
  aiGatewayApiKey: z.string().trim().min(1).optional(),
  aiGatewayBaseUrl: z.string().trim().url().optional(),
  openAiApiKey: z.string().trim().min(1).optional(),
  openAiBaseUrl: z.string().trim().url().optional()
});

export type AppConfig = z.infer<typeof appConfigSchema>;

export function loadConfig(env: NodeJS.ProcessEnv = process.env): AppConfig {
  const parsed = appConfigSchema.safeParse({
    provider: emptyToUndefined(env.CARLITOS_AI_PROVIDER || env.AI_PROVIDER),
    host: emptyToUndefined(env.CARLITOS_AI_HOST),
    port: emptyToUndefined(env.CARLITOS_AI_PORT || env.PORT),
    modelProvider: emptyToUndefined(env.CARLITOS_AI_MODEL_PROVIDER),
    model: emptyToUndefined(env.CARLITOS_AI_MODEL),
    timeoutMs: emptyToUndefined(env.CARLITOS_AI_TIMEOUT_MS),
    maxRetries: emptyToUndefined(env.CARLITOS_AI_MAX_RETRIES),
    temperature: emptyToUndefined(env.CARLITOS_AI_TEMPERATURE),
    logPrompts: emptyToUndefined(env.CARLITOS_AI_LOG_PROMPTS),
    aiGatewayApiKey: emptyToUndefined(env.VERCEL_AI_GATEWAY_API_KEY || env.AI_GATEWAY_API_KEY),
    aiGatewayBaseUrl: emptyToUndefined(env.VERCEL_AI_GATEWAY_BASE_URL || env.AI_GATEWAY_BASE_URL),
    openAiApiKey: emptyToUndefined(env.OPENAI_API_KEY),
    openAiBaseUrl: emptyToUndefined(env.OPENAI_BASE_URL)
  });

  if (!parsed.success) {
    throw new ConfigurationError(parsed.error.issues.map((issue) => issue.message).join(", ") || "Invalid Carlitos AI service configuration.");
  }

  return parsed.data;
}

function emptyToUndefined(value: string | undefined): string | undefined {
  const trimmed = value?.trim();
  return trimmed ? trimmed : undefined;
}
