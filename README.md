# StayCircle

A full-stack Airbnb-like booking platform with role-based authentication, concurrency-safe reservations, idempotent Stripe payments, and real-time property chat.

**Live Demo**
- Frontend: https://stay-circle-frontend.vercel.app
- Backend API (Swagger UI): https://staycircle-backend-production.up.railway.app/docs

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Next.js (TypeScript) |
| Backend | FastAPI (Python) |
| Database | MySQL (production), SQLite (local dev) |
| Cache / Pub-Sub | Redis |
| Payments | Stripe |
| Containerisation | Docker + Docker Compose |

---

## Quickstart

**Prerequisites:** Docker Desktop

```bash
cp .env.example .env
make dev-build
make dev-up
```

- Frontend: http://localhost:3000
- Backend (Swagger UI): http://localhost:8000/docs

See `.env.example` for all configuration options.

---

## Local Dev (no containers)

**Prerequisites:** Python 3.10+, Node.js 18+

```bash
# Backend
cd backend
python3 -m venv .venv && source .venv/bin/activate
pip3 install -r requirements.txt
uvicorn app.main:app --reload --port 8000

# Frontend
cd frontend
npm install && npm run dev
```

SQLite is used by default — no database setup required.

---

## Tests

```bash
cd backend && pytest
```

CI runs automatically on every push via GitHub Actions.
