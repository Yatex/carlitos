import { SYSTEM_PROMPT } from "../prompts/system-prompt.js";
import { buildDecisionPrompt } from "../prompts/build-prompt.js";
import type { Decision } from "../schemas/decision.js";
import type { DecideRequest } from "../schemas/request.js";
import { fallbackMemoryDecision, maybeResolveLocalDecision } from "./local-decisions.js";

import type { DecisionProvider } from "../providers/base-provider.js";

export class DecisionService {
  constructor(private readonly provider: DecisionProvider) {}

  async decide(input: DecideRequest): Promise<Decision> {
    const localDecision = maybeResolveLocalDecision(input);
    if (localDecision) {
      return localDecision;
    }

    const prompt = buildDecisionPrompt(input);
    const result = await this.provider.decide({
      system: SYSTEM_PROMPT,
      prompt,
      request: input
    });

    return result.rawDecision ?? fallbackMemoryDecision(input);
  }
}
