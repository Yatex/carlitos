# Codex Project Instructions

This repo is Carlitos, a Rails SaaS app for an AI personal memory assistant.

- Do not create standalone static pages for product surfaces.
- Use Rails views, controllers, models, helpers, and services.
- Keep Spanish-first UX and copy.
- Keep integration logic in services, not controllers.
- Do not hardcode API keys, Stripe price IDs, webhook secrets, or Twilio credentials.
- Reuse the existing service patterns for Resend, Stripe, Twilio, and Assistant actions.
- Keep Google login in `Authentication::*` services and Google product integrations in `Integrations::*` services.
- Gmail and Google Calendar product actions belong in `Assistant::Actions::*` and `Integrations::Google::*`; controllers should not call Google APIs directly.
- Billing tiers live in `Billing::PlanCatalog`; do not scatter plan feature lists across controllers.
- Keep controllers thin; business decisions belong in models or services.
- Admin-only product operations live under `Admin::*` controllers and require `current_user.admin_like?`.
- Only `super_admin` users should be able to change other users' roles.
- Do not copy competitor text, assets, layouts, logos, colors, or illustrations.
- Keep the landing page honest: no fake testimonials.
- Prefer PostgreSQL-native fields, including `jsonb`, for assistant metadata.
- When adding AI behavior, extend `Assistant::DecisionService`, `Assistant::ActionDispatcher`, `Assistant::Actions::*`, and the Node `ai-decision-service` contract when external AI needs to decide.
- Keep the Node AI service generic: it returns one safe action and arguments; Rails owns persistence and side effects.
- When adding WhatsApp behavior, log inbound/outbound messages with `AssistantMessage`.
- WhatsApp voice notes should flow through `AudioTranscriptionService` before assistant dispatch; missing transcription credentials must not break text messages.
- When changing billing, update Stripe webhook processing and add tests.
