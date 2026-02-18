# StayCircle

A full-stack Airbnb-like app. This repo contains a working end-to-end slice, including authentication, property CRUD, bookings with concurrency controls and workflow, payments, and real-time property chat (WS + REST) with optional Redis fan-out.

Open URLs (after starting services)
- Frontend: http://localhost:3000
- Backend (Swagger UI): http://localhost:8000/docs
- Healthcheck: http://localhost:8000/healthz

--------------------------------------------------------------------------------

Quickstart

Option A) Local Dev (no containers)
Prereqs
- Python 3.10+ (recommended)
- Node.js 18+ (recommended)
- Uses SQLite by default (no MySQL required)

Backend (Terminal A)
- cd backend
- python3 -m venv .venv && source .venv/bin/activate
- pip3 install --upgrade pip
- pip3 install -r requirements.txt
- export DATABASE_URL=sqlite:///./data.db   # optional; default already SQLite for local
- uvicorn app.main:app --reload --port 8000
- Backend runs at http://localhost:8000
- In SQLite mode, tables are auto-created at startup (Alembic optional)

Frontend (Terminal B)
- cd frontend
- npm install
- npm run dev
- Frontend runs at http://localhost:3000

Option B) Docker Compose (recommended)

Prepare env
- cp .env.example .env

Build Docker Image(s)
- make dev-build  # or: make prod-build

Development (hot reload)
- make dev-up
- make dev-logs            # tail logs
- make dev-down            # stop stack
- Note: dev stack runs two backend containers:
  - backend → http://localhost:8000
  - backend2 → http://localhost:8001
  Enable Redis to see cross-process WS fan-out.

Production-like demo
- make prod-up
- make prod-logs
- make prod-down

Utilities
- make ps                  # show running containers (names, images, ports)
- make clean               # prune dangling images/volumes

--------------------------------------------------------------------------------

Configuration (Environment Variables)

Defined via .env (see .env.example for comments and defaults)

Frontend (Next.js)
- NEXT_PUBLIC_API_BASE_URL
  - Default: http://localhost:8000
  - Used by browser to call backend

Backend (FastAPI)
- CORS_ORIGINS
  - Default: http://localhost:3000
  - Comma-separated list of allowed origins for the frontend
- UVICORN_WORKERS
  - Dev compose default: 1
  - Prod compose default: 4
- DATABASE_URL
  - Compose default (dev/prod): mysql+pymysql://staycircle:staycircle@mysql:3306/staycircle
  - Local fallback (non-container): sqlite:///./data.db
  - Legacy prod (volume-based SQLite): sqlite:////data/data.db
- STAYCIRCLE_JWT_SECRET
  - Secret for JWT signing (set a stronger local value; code has a dev fallback)

MySQL (Compose)
- MYSQL_DB=staycircle
- MYSQL_USER=staycircle
- MYSQL_PASSWORD=staycircle
- MYSQL_ROOT_PASSWORD=devroot
- Service name mysql, port 3306 (dev binds 3306:3306)

Redis (optional, used for rate limiting and chat fan‑out)
- REDIS_ENABLED
  - Default: false
  - When true: enables fixed-window rate limiting and chat Pub/Sub fan-out (Sprint 9C)
- REDIS_URL
  - Default (Compose): redis://redis:6379/0
- RATE_LIMIT_WINDOW_SECONDS
  - Default: 60
- RATE_LIMIT_LOGIN_PER_WINDOW
  - Default: 10
- RATE_LIMIT_SIGNUP_PER_WINDOW
  - Default: 5
- RATE_LIMIT_WRITE_PER_WINDOW
  - Default: 30

Booking holds
- HOLD_MINUTES
  - Default: 15
  - Hold window for pending_payment bookings; a sweeper thread cancels expired holds

Payments (Stripe)
- STRIPE_SECRET_KEY
  - When set and stripe SDK is available, real PaymentIntents are created in Stripe test mode
  - When unset, payments operate in deterministic offline mode (no network; useful for local/CI)
- STRIPE_WEBHOOK_SECRET
  - Required to validate /payments/webhook events when Stripe is enabled

Per-file sources of truth
- docker-compose.dev.yml and docker-compose.prod.yml
- backend/app/main.py (CORS, healthz, router mounts, SQLite-only create_all)
- backend/app/routes/auth.py, properties.py, bookings.py, messages.py, chat_ws.py
- backend/app/payments.py (Stripe enable/disable, payment_info + finalize flows, webhook)
- backend/app/sweepers.py (expiry of pending_payment holds)
- backend/app/alembic.ini, backend/app/alembic/env.py, backend/app/alembic/versions/
- Makefile for task shortcuts

--------------------------------------------------------------------------------

API & Features (Summary)

Health
- GET /healthz → 200: {"status": "ok"}

Auth
- POST /auth/signup → returns {"access_token","token_type","user":{"id","email","role"}}
- POST /auth/login  → returns same shape

Properties
- GET /api/v1/properties → list properties
- POST /api/v1/properties (landlord only) → create property

Bookings
- POST /api/v1/bookings (tenant only) → create booking (overlap-safe)
- GET /api/v1/bookings/me (auth) → role-aware list
- DELETE /api/v1/bookings/{id} → cancel
- POST /api/v1/bookings/{id}/approve (landlord owner)
- POST /api/v1/bookings/{id}/decline (landlord owner)
- Workflow notes:
  - Only confirmed bookings block availability; pending_* do not
  - Holds and expiry sweepers handle pending_payment

Payments (v1)
- GET /api/v1/bookings/{booking_id}/payment_info → ensure PI exists and return client_secret + expires_at
- POST /api/v1/bookings/{booking_id}/finalize_payment → finalize when webhooks are unavailable
- POST /payments/webhook → validate and idempotently confirm booking on payment_intent.succeeded
- Stripe test flow with offline fallback when STRIPE_SECRET_KEY is not set

Messages (Chat History)
- GET /api/v1/messages
  - Query: property_id (required), limit (default 50; 1..100), since_id (optional)
  - AuthZ: landlords must own the property; tenants allowed
  - Returns: [MessageRead] ordered asc

WebSocket Chat (Real-time)
- WS /ws/chat/property/{property_id}
  - Auth on connect: JWT via Authorization header or token query param
  - Validation: trimmed text, max 1000 chars
  - Behavior: persist then broadcast {id, property_id, sender_id, text, created_at}
  - Throttling: per-connection token-bucket (1 msg/s, burst 5)
  - Fan-out: optional Redis Pub/Sub (when REDIS_ENABLED=true)

OpenAPI (interactive)
- http://localhost:8000/docs
