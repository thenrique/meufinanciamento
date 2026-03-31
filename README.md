# Amortizador Pro

Conselheiro financeiro de amortização de financiamentos imobiliários brasileiros.

## Estrutura do projeto

```
meufinanciamento/
├── backend/        # API FastAPI (Python)
├── mobile/         # App Flutter (Android + iOS)
├── web/            # Site Next.js (landing page + simulador)
└── supabase/       # Migrations SQL
```

---

## Pré-requisitos

| Ferramenta | Versão mínima | Download |
|------------|---------------|---------|
| Python | 3.11+ | python.org |
| Flutter | 3.x | flutter.dev |
| Node.js | 18+ | nodejs.org |
| Git | qualquer | git-scm.com |

---

## 1. Configurar o Supabase

1. Acesse [supabase.com](https://supabase.com) e crie um projeto gratuito
2. Vá em **SQL Editor** e cole o conteúdo de `supabase/migrations/001_initial_schema.sql`
3. Execute — todas as tabelas, índices e triggers serão criados
4. Em **Authentication → Providers**, ative **Google** e **Apple**
5. Copie as credenciais:
   - `Project URL` → `SUPABASE_URL`
   - `anon public` → `SUPABASE_KEY`
   - `service_role` → `SUPABASE_SERVICE_KEY`

---

## 2. Rodar o Backend (FastAPI)

```bash
cd backend

# Copiar e preencher as variáveis de ambiente
cp .env.example .env
# Edite o .env com suas chaves reais

# Instalar dependências
pip install -r requirements.txt

# Rodar em modo desenvolvimento
uvicorn app.main:app --reload --port 8000
```

A API estará disponível em `http://localhost:8000`
Documentação interativa em `http://localhost:8000/docs`

### Variáveis obrigatórias no `.env`

```env
SUPABASE_URL=https://xxxx.supabase.co
SUPABASE_KEY=eyJ...
SUPABASE_SERVICE_KEY=eyJ...
MP_ACCESS_TOKEN=APP_USR-...
MP_WEBHOOK_SECRET=...
ENVIRONMENT=dev
```

### Variáveis opcionais

```env
OPENAI_API_KEY=sk-...     # Para insights com IA (pode deixar vazio no início)
SENTRY_DSN=https://...    # Monitoramento de erros (pode deixar vazio)
```

---

## 3. Rodar o Site (Next.js)

```bash
cd web
npm install
npm run dev
```

O site estará em `http://localhost:3000`

---

## 4. Rodar o App Flutter

```bash
cd mobile
flutter pub get

# Com emulador Android ou iOS aberto:
flutter run \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ... \
  --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

> **Importante:** no emulador Android, use `10.0.2.2` para acessar o `localhost` da máquina.
> No iOS Simulator, use `127.0.0.1` normalmente.

---

## 5. Rodar tudo com Docker (alternativa)

```bash
# Preencher backend/.env antes
cp backend/.env.example backend/.env

docker-compose up --build
```

- Backend: `http://localhost:8000`
- Site: `http://localhost:3000`

---

## Testar os endpoints manualmente

Com o backend rodando, acesse `http://localhost:8000/docs` para a interface Swagger.

### Fluxo básico de teste:

1. **Health check:** `GET /health` → deve retornar `{"status": "ok"}`
2. **Taxas BCB:** `GET /rates/current` → retorna TR e Selic atuais
3. **Auth:** Login via Supabase no app Flutter ou site
4. **Criar financiamento:** `POST /loans` com token JWT
5. **Simular:** `POST /simulate` com `loan_id` e `extra_monthly`
6. **Insights:** `GET /advisor/insights` para ver os conselhos

---

## Deploy em produção

### Backend → Railway (recomendado)
1. Conecte o repositório no [railway.app](https://railway.app)
2. Selecione a pasta `backend/`
3. Configure as variáveis de ambiente no painel
4. Deploy automático a cada push

### Site → Vercel (recomendado)
1. Conecte o repositório no [vercel.com](https://vercel.com)
2. Selecione a pasta `web/`
3. Deploy automático

### App → Lojas
```bash
# Android
flutter build appbundle --dart-define=...

# iOS
flutter build ipa --dart-define=...
```

---

## Mercado Pago (pagamentos)

1. Crie conta em [mercadopago.com.br](https://mercadopago.com.br)
2. Em **Credenciais**, copie o `Access Token` de **teste**
3. Configure o webhook: URL = `https://sua-api.com/payment/webhook`
4. Para testar pagamentos: use os [cartões de teste do MP](https://www.mercadopago.com.br/developers/pt/docs/checkout-api/integration-test/test-cards)
