import type { Decision } from "../schemas/decision.js";
import type { DecideRequest } from "../schemas/request.js";

const WEEKDAYS: Record<string, number> = {
  domingo: 0,
  lunes: 1,
  martes: 2,
  miercoles: 3,
  miércoles: 3,
  jueves: 4,
  viernes: 5,
  sabado: 6,
  sábado: 6
};

export function maybeResolveLocalDecision(request: DecideRequest): Decision | null {
  const normalized = request.input.trim();

  const googleDecision = maybeResolveGoogleDecision(normalized);
  if (googleDecision) {
    return googleDecision;
  }

  const reminderMatch = normalized.match(/^record[aá]me\s+(.+?)(?:\s+(hoy|mañana|pasado mañana|lunes|martes|miércoles|miercoles|jueves|viernes|sábado|sabado|domingo))?(?:\s+a\s+las\s+(\d{1,2})(?::(\d{2}))?)?$/i);
  if (reminderMatch) {
    return {
      action: "create_reminder",
      arguments: {
        title: reminderMatch[1].trim(),
        body: normalized,
        ...compact({ remind_at: parseSpanishDate(reminderMatch[2], reminderMatch[3], reminderMatch[4]) })
      },
      confidence: 0.84,
      reply: null,
      reasoning_summary: "Comando local de recordatorio en español."
    };
  }

  const addListItemMatch = normalized.match(/agreg[aá]\s+(.+?)\s+a\s+la\s+lista\s+del?\s+(.+)/i);
  if (addListItemMatch) {
    return {
      action: "add_list_item",
      arguments: {
        content: addListItemMatch[1].trim(),
        list_title: addListItemMatch[2].trim()
      },
      confidence: 0.86,
      reply: null,
      reasoning_summary: "Comando local para sumar un item a una lista."
    };
  }

  const saveNoteMatch = normalized.match(/guard[aá]\s+(?:que\s+)?(.+)/i);
  if (saveNoteMatch) {
    const content = saveNoteMatch[1].trim();
    return {
      action: "save_memory_note",
      arguments: {
        title: truncate(content, 64),
        content,
        source: "assistant"
      },
      confidence: 0.8,
      reply: null,
      reasoning_summary: "Comando local para guardar contexto personal."
    };
  }

  if (/\b(briefing|resumen diario|resumen de lo importante)\b/i.test(normalized)) {
    return {
      action: "schedule_daily_briefing",
      arguments: {
        enabled: true,
        delivery_time: "08:00",
        timezone: request.user.timezone
      },
      confidence: 0.72,
      reply: null,
      reasoning_summary: "Comando local para activar briefing diario."
    };
  }

  const searchMatch = normalized.match(/(?:busc[aá]|qu[eé]\s+(?:era|fue)|d[oó]nde\s+guard[eé])\s+(.+)/i);
  if (searchMatch) {
    return {
      action: "search_memory",
      arguments: { query: searchMatch[1].trim() },
      confidence: 0.7,
      reply: null,
      reasoning_summary: "Comando local para buscar en la memoria."
    };
  }

  return null;
}

function maybeResolveGoogleDecision(normalized: string): Decision | null {
  const sendEmailMatch = normalized.match(/(?:mand[aá]|envi[aá])\s+(?:un\s+)?(?:mail|email|correo)\s+a\s+([\w.+-]+@[\w.-]+\.\w+)\s+(?:que\s+diga|diciendo|mensaje|con\s+el\s+texto)\s+(.+)/i);
  if (sendEmailMatch) {
    return {
      action: "send_email",
      arguments: {
        to: sendEmailMatch[1].trim(),
        body: sendEmailMatch[2].trim()
      },
      confidence: 0.74,
      reply: null,
      reasoning_summary: "Comando local para enviar un correo desde Gmail."
    };
  }

  const gmailSearchMatch = normalized.match(/(?:busc[aá]|le[eé]|revis[aá]|mir[aá]|mostrame|ver)\s+(?:mis\s+)?(?:mails|emails|correos|gmail)(?:\s+(?:sobre|de|con|por)\s+(.+))?/i);
  if (gmailSearchMatch) {
    return {
      action: "search_gmail",
      arguments: { query: gmailQuery(gmailSearchMatch[1]) },
      confidence: 0.72,
      reply: null,
      reasoning_summary: "Comando local para buscar en Gmail."
    };
  }

  const contextualGmailSearchMatch = normalized.match(/\b(?:gmail|mails|emails|correos)\b.*(?:sobre|de|con|por)\s+(.+)/i);
  if (contextualGmailSearchMatch) {
    return {
      action: "search_gmail",
      arguments: { query: gmailQuery(contextualGmailSearchMatch[1]) },
      confidence: 0.62,
      reply: null,
      reasoning_summary: "Comando local contextual para buscar en Gmail."
    };
  }

  const calendarMatch = normalized.match(/^(?:cre[aá]|agend[aá]|arm[aá])\s+(?:un\s+)?(?<kind>evento|reuni[oó]n|turno)(?:\s+(?<rest>.+))?$/i);
  if (calendarMatch?.groups) {
    const schedule = extractSpanishSchedule(calendarMatch.groups.rest || "");
    return {
      action: "create_calendar_event",
      arguments: {
        title: calendarTitle(calendarMatch.groups.kind, schedule.title),
        ...compact({ starts_at: schedule.startsAt })
      },
      confidence: schedule.startsAt ? 0.72 : 0.54,
      reply: null,
      reasoning_summary: "Comando local para crear un evento de calendario."
    };
  }

  return null;
}

export function fallbackMemoryDecision(request: DecideRequest): Decision {
  return {
    action: "save_memory_note",
    arguments: {
      title: "Mensaje guardado",
      content: request.input.trim(),
      source: "assistant"
    },
    confidence: 0.42,
    reply: null,
    reasoning_summary: "Fallback seguro: guardar el mensaje como nota de memoria."
  };
}

function parseSpanishDate(dayText?: string, hourText?: string, minuteText?: string): string | undefined {
  if (!dayText && !hourText) {
    return undefined;
  }

  const date = new Date();
  const day = (dayText || "hoy").toLowerCase();

  if (day === "mañana") {
    date.setDate(date.getDate() + 1);
  } else if (day === "pasado mañana") {
    date.setDate(date.getDate() + 2);
  } else if (WEEKDAYS[day] !== undefined) {
    const target = WEEKDAYS[day];
    let daysAhead = (target - date.getDay() + 7) % 7;
    if (daysAhead === 0) {
      daysAhead = 7;
    }
    date.setDate(date.getDate() + daysAhead);
  }

  date.setHours(Number(hourText || 9), Number(minuteText || 0), 0, 0);
  return date.toISOString();
}

function extractSpanishSchedule(text: string): { title: string; startsAt?: string } {
  const dayMatch = text.match(/\b(hoy|mañana|pasado mañana|lunes|martes|miércoles|miercoles|jueves|viernes|sábado|sabado|domingo)\b/i);
  const hourMatch = text.match(/a\s+las\s+(\d{1,2})(?::(\d{2}))?/i);
  const title = text
    .replace(/\b(hoy|mañana|pasado mañana|lunes|martes|miércoles|miercoles|jueves|viernes|sábado|sabado|domingo)\b/gi, "")
    .replace(/a\s+las\s+\d{1,2}(?::\d{2})?/gi, "")
    .trim()
    .replace(/\s+/g, " ");

  return {
    title,
    startsAt: dayMatch || hourMatch ? parseSpanishDate(dayMatch?.[1], hourMatch?.[1], hourMatch?.[2]) : undefined
  };
}

function gmailQuery(value?: string): string {
  return value?.trim().replace(/\s+/g, " ") || "newer_than:7d";
}

function calendarTitle(kind: string, detail: string): string {
  const base = /reuni/i.test(kind) ? "Reunión" : capitalize(kind);
  return detail ? `${base} ${detail}` : base;
}

function capitalize(value: string): string {
  return value.charAt(0).toUpperCase() + value.slice(1).toLowerCase();
}

function compact(values: Record<string, string | undefined>): Record<string, string> {
  return Object.fromEntries(Object.entries(values).filter(([, value]) => value !== undefined)) as Record<string, string>;
}

function truncate(value: string, maxLength: number): string {
  return value.length > maxLength ? `${value.slice(0, maxLength - 1)}…` : value;
}
