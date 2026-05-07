import { z } from "zod";

export const decideRequestSchema = z.object({
  prompt: z.string().trim().min(1).optional(),
  input: z.string().trim().min(1),
  channel: z.enum(["web", "whatsapp", "email"]).catch("web"),
  user: z.object({
    id: z.union([z.string(), z.number()]).optional(),
    timezone: z.string().trim().min(1).default("America/Montevideo")
  }).default({ timezone: "America/Montevideo" }),
  context: z.record(z.string(), z.unknown()).optional()
}).passthrough();

export type DecideRequest = z.infer<typeof decideRequestSchema>;
