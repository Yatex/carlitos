import { z } from "zod";

export const decisionActionValues = [
  "create_reminder",
  "create_list",
  "add_list_item",
  "save_memory_note",
  "schedule_daily_briefing",
  "search_memory",
  "search_gmail",
  "send_email",
  "create_calendar_event",
  "unknown"
] as const;

export const decisionActionSchema = z.enum(decisionActionValues);

export const decisionSchema = z.object({
  action: decisionActionSchema,
  arguments: z.record(z.string(), z.unknown()).default({}),
  confidence: z.number().min(0).max(1),
  reply: z.string().trim().min(1).max(500).nullable().default(null),
  reasoning_summary: z.string().trim().min(1).max(280)
}).strict();

export type Decision = z.infer<typeof decisionSchema>;
