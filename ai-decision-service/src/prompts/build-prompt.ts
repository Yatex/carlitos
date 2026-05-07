import type { DecideRequest } from "../schemas/request.js";

export function buildDecisionPrompt(input: DecideRequest): string {
  const now = new Date().toISOString();

  return [
    `Fecha actual UTC: ${now}`,
    `Zona horaria del usuario: ${input.user.timezone}`,
    `Canal: ${input.channel}`,
    "",
    "Mensaje del usuario:",
    input.input,
    "",
    "Si el mensaje menciona fechas relativas como hoy o mañana, usá la zona horaria del usuario para razonar y devolvé remind_at en ISO8601 cuando tengas suficiente certeza.",
    "Si el usuario pide buscar algo que ya guardó, usá search_memory.",
    "Si el usuario solo comparte contexto, guardalo como save_memory_note."
  ].join("\n");
}
