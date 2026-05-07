import { fallbackMemoryDecision } from "../services/local-decisions.js";

import type { DecisionProvider, ProviderDecisionInput, ProviderDecisionResult } from "./base-provider.js";

export class MockDecisionProvider implements DecisionProvider {
  async decide(input: ProviderDecisionInput): Promise<ProviderDecisionResult> {
    return {
      rawDecision: fallbackMemoryDecision(input.request),
      metadata: {
        provider: "mock"
      }
    };
  }
}
