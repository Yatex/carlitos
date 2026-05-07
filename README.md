# Carlitos

Carlitos is a Ruby on Rails SaaS app for an AI personal memory assistant that works mainly through WhatsApp. Users can capture reminders, tasks, lists, ideas, voice notes, and personal context; Carlitos organizes the information and brings it back when it matters.

## Stack

- Ruby 3.3.6
- Rails 7.1.6
- PostgreSQL
- Tailwind CSS via `tailwindcss-rails`
- Resend for transactional email
- Stripe for subscriptions
- Twilio WhatsApp integration scaffolding
- Vercel AI SDK decision service with a local fallback parser

## Local Setup

```sh
bundle install
bin/rails db:prepare
bin/rails tailwindcss:build
bin/rails server
```

Open `http://localhost:3000`.

If your shell resolves to the macOS system Ruby, prefix commands with Ruby 3.3.6:

```sh
PATH=/Users/felo/.rbenv/versions/3.3.6/bin:$PATH bin/rails server
```

## Environment

Copy `.env.example` to `.env` and fill only the services you want to test locally.

```sh
cp .env.example .env
```

Required for a normal local app boot:

- `DATABASE_URL` or local PostgreSQL matching `config/database.yml`

Optional integrations:

- `RESEND_API_KEY`
- `RESEND_FROM_EMAIL`
- `STRIPE_SECRET_KEY`
- `STRIPE_PUBLISHABLE_KEY`
- `STRIPE_WEBHOOK_SECRET`
- `STRIPE_PRICE_PRO`
- `STRIPE_PRICE_FAMILY`
- `TWILIO_ACCOUNT_SID`
- `TWILIO_AUTH_TOKEN`
- `TWILIO_WHATSAPP_FROM`
- `TWILIO_WEBHOOK_AUTH_TOKEN`
- `GOOGLE_CLIENT_ID`
- `GOOGLE_CLIENT_SECRET`
- `GOOGLE_OAUTH_REDIRECT_URI`
- `AI_PROVIDER`
- `CARLITOS_AI_SERVICE_URL`
- `CARLITOS_AI_SERVICE_TOKEN`
- `CARLITOS_AI_PROVIDER`
- `CARLITOS_AI_MODEL_PROVIDER`
- `CARLITOS_AI_MODEL`
- `OPENAI_API_KEY`
- `VERCEL_AI_GATEWAY_API_KEY`

Missing Resend, Stripe, Twilio, or AI credentials are handled gracefully in development. The app logs a clear warning and skips the external call.

## Database

PostgreSQL is the canonical database.

```sh
bin/rails db:create
bin/rails db:migrate
```

For Render or other production platforms, prefer `DATABASE_URL`.

## Demo Seed Account

Load local seed data with:

```sh
bin/rails db:seed
```

Demo login:

- Email: `demo@carlitos.test`
- Password: `password123`

The seed creates a Pro demo user with reminders, lists, memory notes, daily briefing settings, and assistant activity.

Admin login:

- Email: `admin@carlitos.test`
- Password: `password123`

The admin seed is a `super_admin`, so it can access `/admin/users` and `/admin/analytics`.

## Admin

Carlitos has three roles:

- `user`: normal product user.
- `admin`: can access admin sections and extend normal users' plans.
- `super_admin`: can extend any plan and promote other users to admin.

Admin sections:

- `/admin/users`: filter users, review role/plan/activity, extend plans manually, and update roles as super admin.
- `/admin/analytics`: platform-level metrics such as total users, paying users, early-access signups, active briefings, integrations, and content/activity counts.

## Settings Integrations

Logged-in users can manage integrations from `/settings`.

Current channels:

- Gmail
- Google Calendar
- WhatsApp

Google OAuth uses:

```sh
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
GOOGLE_OAUTH_REDIRECT_URI=
GOOGLE_GMAIL_SCOPES=
GOOGLE_CALENDAR_SCOPES=
```

If `GOOGLE_OAUTH_REDIRECT_URI` is empty, Carlitos uses the Rails callback URL:

```text
/integrations/google/callback
```

For now, Google OAuth records connection status and granted scopes, but does not persist OAuth access or refresh tokens. Add encrypted token storage before reading Gmail or Calendar data in production.

## Resend

Set:

```sh
RESEND_API_KEY=
RESEND_FROM_EMAIL=
```

Transactional email currently goes through `ResendClient` and `TransactionalEmail`:

- Welcome email placeholder
- Password reset email
- Early-access confirmation placeholder

## Stripe

Set:

```sh
STRIPE_SECRET_KEY=
STRIPE_PUBLISHABLE_KEY=
STRIPE_WEBHOOK_SECRET=
STRIPE_PRICE_FREE=
STRIPE_PRICE_PRO=
STRIPE_PRICE_FAMILY=
```

Do not commit real price IDs or keys. Billing plans are defined in `Billing::PlanCatalog`; Stripe Checkout reads `STRIPE_PRICE_PRO` for Pro and is prepared for `STRIPE_PRICE_FAMILY` when that plan is enabled.

Local webhook testing with Stripe CLI:

```sh
stripe listen --forward-to localhost:3000/stripe/webhooks
```

Copy the webhook signing secret into `STRIPE_WEBHOOK_SECRET`.

## Twilio WhatsApp

Set:

```sh
TWILIO_ACCOUNT_SID=
TWILIO_AUTH_TOKEN=
TWILIO_WHATSAPP_FROM=
TWILIO_WEBHOOK_AUTH_TOKEN=
```

Configure Twilio’s WhatsApp inbound webhook to:

```text
POST /whatsapp/inbound
```

If `TWILIO_WEBHOOK_AUTH_TOKEN` is set, include the same value in the `X-Carlitos-Webhook-Token` header.

## AI Service

Carlitos can already understand a small set of Spanish commands through the Rails fallback parser. For fuller AI behavior, run the Node decision service in `ai-decision-service`, which uses the Vercel AI SDK and keeps a deterministic local fallback so development does not depend on credentials.

Set:

```sh
AI_PROVIDER=vercel
CARLITOS_AI_SERVICE_URL=http://localhost:8787/decide
CARLITOS_AI_SERVICE_TOKEN=
```

Run the service:

```sh
cd ai-decision-service
npm install
npm run dev
```

Service env vars:

```sh
CARLITOS_AI_PROVIDER=vercel
CARLITOS_AI_MODEL_PROVIDER=gateway
CARLITOS_AI_MODEL=openai/gpt-5-mini
VERCEL_AI_GATEWAY_API_KEY=
VERCEL_AI_GATEWAY_BASE_URL=
OPENAI_API_KEY=
OPENAI_BASE_URL=
```

When no provider/service URL is configured, `Assistant::DecisionService` uses a limited local parser inside Rails. When the Node service is running without provider credentials, it also stays alive in limited local mode. Current deterministic commands include:

- `recordame pagar el alquiler mañana a las 10`
- `agregá leche a la lista del súper`
- `guardá que mi DNI vence en agosto`

The service contract is `POST /decide` with `input`, `channel`, and `user.timezone`; it returns one action such as `create_reminder`, `add_list_item`, `save_memory_note`, `schedule_daily_briefing`, or `search_memory`.

## Tests

```sh
bin/rails test
npm --prefix ai-decision-service test
```

The smoke suite covers the landing page, early access, auth, dashboard protection, billing plan display, reminders, memory notes, Stripe webhook presence, WhatsApp webhook presence, Resend safe initialization, and assistant fallback actions.

## Render Notes

- Set Ruby to `3.3.6`.
- Use PostgreSQL and provide `DATABASE_URL`.
- Build command: `bundle install && bin/rails assets:precompile`
- Start command: `bin/rails server`
- Configure all production env vars in Render, never in the repo.
