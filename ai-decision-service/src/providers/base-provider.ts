import type { Decision } from "../schemas/decision.js";
import type { DecideRequest } from "../schemas/request.js";

export interface ProviderDecisionInput {
  system: string;
  prompt: string;
  request: DecideRequest;
}

export interface ProviderDecisionResult {
  rawDecision: Decision;
  metadata: Record<string, unknown>;
}

export interface DecisionProvider {
  decide(input: ProviderDecisionInput): Promise<ProviderDecisionResult>;
}
