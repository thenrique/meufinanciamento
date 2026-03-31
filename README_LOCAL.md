# Local Development Setup (Lightweight)

## Prerequisites

- **Flutter 3.22+**
- **Node.js 18+**
- **Docker + Docker Compose**
- **Supabase account** (remote, not local emulator)

## Quick Start

### Terminal 1: Backend (Lightweight)
```bash
cd backend
docker-compose up -d backend
# Wait 10 seconds for startup
# Backend will be available at: http://localhost:8000
```

### Terminal 2: Website
```bash
cd web
npm install
npm run dev
# Website will be available at: http://localhost:3000
```

### Terminal 3: Mobile App
```bash
cd mobile
flutter pub get
flutter run -d chrome
# App opens in Chrome
```

## Environment Variables

Create `.env` files in each directory (`backend/`, `web/`, `mobile/`):
- Copy from `.env.example` in each directory
- Update with your values

**Key variables:**
- `SUPABASE_URL` - Your Supabase project URL
- `SUPABASE_ANON_KEY` - Your Supabase anon key
- `STRIPE_KEY` - Stripe public key (for future payment integration)

## Database Setup

This project uses **Supabase remote** (no local emulator).

### Running Migrations

1. Log in to [Supabase Dashboard](https://supabase.com/dashboard)
2. Open your project → **SQL Editor**
3. Copy and paste each migration file in order:
   - `001_initial_schema.sql`
   - `002_auth_setup.sql`
   - `003_profiles.sql`
   - `004_transactions.sql`
4. Execute each migration

## Troubleshooting

| Issue | Solution |
|-------|----------|
| **PC is slow** | Don't run all 3 terminals simultaneously. Start backend first, wait 10s, then web, then mobile. |
| **Blank screens in mobile** | Run `flutter clean` then `flutter run -d chrome` again. |
| **API connection errors** | Check backend logs: `docker logs meufinanciamento-backend-1` |
| **Port already in use** | Change ports in `docker-compose.yml` or npm scripts if needed. |
| **Supabase connection fails** | Verify `SUPABASE_URL` and `SUPABASE_ANON_KEY` in `.env` files. |

## Testing

### Backend
```bash
cd backend
python -m pytest
```

### Mobile
```bash
cd mobile
flutter test
```

## Stopping

### Terminal 1 (Backend)
```bash
docker-compose down
```

### Other Terminals
- Press `Ctrl+C` to stop dev servers

## Key Files

- **Backend config:** `backend/app/main.py`
- **Frontend config:** `mobile/lib/main.dart`
- **API constants:** `mobile/lib/features/*/providers.dart`
- **Docker config:** `backend/docker-compose.yml`
- **Web config:** `web/next.config.js`

---

**Need help?** Check the main README.md or ask the team.
