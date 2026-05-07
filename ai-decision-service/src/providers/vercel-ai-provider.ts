import { createOpenAI } from "@ai-sdk/openai";
import { createGateway, generateText, Output } from "ai";

import type { AppConfig } from "../config.js";
import { ProviderExecutionError } from "../lib/errors.js";
import { decisionSchema } from "../schemas/decision.js";

import type { DecisionProvider, ProviderDecisionInput, ProviderDecisionResult } from "./base-provider.js";

export class VercelAiDecisionProvider implements DecisionProvider {
  constructor(private readonly config: AppConfig) {}

  async decide(input: ProviderDecisionInput): Promise<ProviderDecisionResult> {
    const abortSignal = AbortSignal.timeout(this.config.timeoutMs);

    try {
      const result = await generateText({
        model: this.modelFactory()(this.config.model),
        system: input.system,
        prompt: input.prompt,
        temperature: this.config.temperature,
        maxRetries: this.config.maxRetries,
        abortSignal,
        output: Output.object({
          schema: decisionSchema,
          name: "carlitos_assistant_decision",
          description: "Exactly one Carlitos assistant action for one user message."
        })
      });

      return {
        rawDecision: result.output,
        metadata: {
          provider: "vercel",
          modelProvider: this.config.modelProvider,
          model: this.config.model,
          finishReason: result.finishReason,
          usage: result.usage
        }
      };
    } catch (error) {
      const timeout = error instanceof Error && (error.name === "AbortError" || error.name === "TimeoutError");
      throw new ProviderExecutionError(
        timeout ? "The AI provider timed out before returning a decision." : "The AI provider failed to return a decision.",
        timeout ? "provider_timeout" : "provider_error",
        { cause: error }
      );
    }
  }

  private modelFactory(): (modelId: string) => ReturnType<ReturnType<typeof createOpenAI>> {
    if (this.config.modelProvider === "openai") {
      const openai = createOpenAI({
        apiKey: this.config.openAiApiKey,
        ...(this.config.openAiBaseUrl ? { baseURL: this.config.openAiBaseUrl } : {})
      });

      return (modelId: string) => openai(modelId);
    }

    const gateway = createGateway({
      apiKey: this.config.aiGatewayApiKey,
      ...(this.config.aiGatewayBaseUrl ? { baseURL: this.config.aiGatewayBaseUrl } : {})
    });

    return (modelId: string) => gateway(modelId);
  }
}
