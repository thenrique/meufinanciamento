# 📋 Plano: Sistema de Inscrição com Trial 7 Dias + Cancelamento

## 🎯 Objetivo
Implementar fluxo de inscrição gratuita por 7 dias (sem cartão), bloqueio automático após período, e cancelamento de assinatura sem burocracia.

## ✅ Já Temos
- ✅ **Supabase Auth** (signUp, signIn, signOut)
- ✅ **OAuth** (Google, Apple)
- ✅ **Email/Senha** (signInWithEmail, signUpWithEmail)
- ✅ **Auth Service** completo em `core/auth_service.dart`
- ✅ **Onboarding Screen** para login/registro

## 🔍 O Que Falta
- ❌ Criar `user_subscriptions` table (Supabase)
- ❌ Auto-trigger trial (7 dias) quando signup
- ❌ Bloqueio automático após expiration
- ❌ Tela de paywall (quando trial expires)
- ❌ Botão cancelar assinatura
- ❌ UI de countdown (dias restantes)

---

## 📊 Database Schema (Novo)

### Tabela: `user_subscriptions`
```sql
CREATE TABLE user_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  status TEXT DEFAULT 'active', -- 'active', 'expired', 'cancelled'
  plan TEXT DEFAULT 'trial', -- 'trial', 'premium'
  started_at TIMESTAMP DEFAULT now(),
  expires_at TIMESTAMP DEFAULT now() + INTERVAL '7 days',
  trial_extended BOOLEAN DEFAULT false,
  stripe_customer_id TEXT,
  cancelled_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);
```

### RLS Policy (user vê apenas sua subscription)
```sql
ALTER TABLE user_subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users see own subscription"
  ON user_subscriptions FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users update own subscription"
  ON user_subscriptions FOR UPDATE
  USING (auth.uid() = user_id);
```

### Trigger: Auto-create subscription on signup
```sql
-- Será criado via Supabase function ou via backend
-- Quando user faz signUp, backend chama:
-- POST /api/subscriptions/init-trial
```

---

## 🛠️ Tasks (Ondas)

### **ONDA 1: Backend Foundation** (3 tasks)
- [ ] `db-user-subscriptions` - Criar tabelas + RLS + migration SQL
- [ ] `subscriptions-models` - Pydantic models (UserSubscription, TrialStatus)
- [ ] `subscriptions-validator` - Validators (trial expirado?, ativo?, etc)

### **ONDA 2: Backend API** (4 tasks)
- [ ] `auth-signup-integration` - Modificar signUp para auto-criar trial
- [ ] `subscription-endpoints` - GET /user/subscription, POST /subscription/extend
- [ ] `subscription-check` - Middleware para bloquear acesso se expirado
- [ ] `cancellation-endpoint` - DELETE /subscription (soft delete)

### **ONDA 3: Frontend Mobile** (5 tasks)
- [ ] `subscription-provider` - Riverpod provider para subscription status
- [ ] `trial-counter-widget` - Countdown visual (dias restantes)
- [ ] `paywall-screen` - Tela de bloqueio após trial (upgrade CTA)
- [ ] `cancel-subscription` - Settings com botão "Cancelar Assinatura"
- [ ] `auth-check-trial` - Integrar trial check no home screen

### **ONDA 4: Git + Docs + Otimização** (3 tasks)
- [ ] `git-init-commit` - git init + commit inicial (sem LFS)
- [ ] `readme-local-setup` - Documentar setup local leve
- [ ] `docker-optimization` - Otimizar docker-compose

---

## 🎯 User Stories

### **Story 1: Signup → Trial**
```
1. User clica "Começar" no site
2. Onboarding screen (email + senha)
3. Backend: signUp + cria user_subscriptions (7 dias)
4. App abre com "7 dias grátis" no home
5. Countdown visual regressivo
```

### **Story 2: Trial Expira → Paywall**
```
1. 7 dias passam
2. Next login ou home screen
3. Tela: "Sua trial expirou" + "Upgrade para continuar"
4. 2 opções: "Ver planos" (future: Stripe) ou "OK"
5. Acesso bloqueado até pagamento
```

### **Story 3: Cancelamento**
```
1. User vai em Settings → "Sua Assinatura"
2. Clica "Cancelar Assinatura"
3. Dialog: "Tem certeza?"
4. POST /subscription → status = 'cancelled'
5. App bloqueia acesso (paywall novamente)
6. Email confirmação
```

---

## 🔧 Implementação Leve (PC não trava)

### **Estratégia:**
1. **Não rodar tudo junto**
   - Backend: `docker-compose up -d backend` (light)
   - Web: `npm run dev` (local, sem docker)
   - Mobile: `flutter run -d chrome` (isolado)

2. **Database Leve**
   - Supabase: usar remote (não local emulator)
   - Migrations via SQL simples

3. **Desabilitar Heavy Stuff**
   - Backend: menos logging
   - Mobile: desabilitar hot reload pesado

4. **Git Workflow**
   - `git init` + commit inicial
   - Sem LFS
   - .gitignore completo

---

## 📝 Configurações Finais ✅

1. ✅ **Payment gateway**: Stripe (futura integração)
2. ✅ **Preço da assinatura**: R$ 14,90/mês
3. ✅ **Extensão do trial**: 1x (user pode estender mais 7 dias 1 vez)
4. ✅ **Reativação**: Sim, user pode reativar após cancelar
5. ✅ **Email verification**: Não (friction zero)

---

## ⏱️ Timeline Estimado

- **ONDA 1:** ~25 min (paralelo)
- **ONDA 2:** ~30 min (paralelo)
- **ONDA 3:** ~40 min (paralelo)
- **ONDA 4:** ~20 min
- **Total:** ~1.5-2 horas

---

## 📂 Arquivos que Serão Criados/Modificados

### Backend
- `backend/supabase/migrations/004_user_subscriptions.sql` (NEW)
- `backend/app/finance/models/subscription.py` (NEW)
- `backend/app/finance/validators/subscription_validator.py` (NEW)
- `backend/app/finance/router.py` (MODIFY - adicionar endpoints)
- `backend/app/auth.py` (MODIFY - auto-create trial)

### Frontend
- `mobile/lib/models/subscription.dart` (NEW)
- `mobile/lib/features/subscription/providers.dart` (NEW)
- `mobile/lib/features/subscription/widgets/trial_counter.dart` (NEW)
- `mobile/lib/features/subscription/screens/paywall_screen.dart` (NEW)
- `mobile/lib/features/settings/screens/settings_screen.dart` (MODIFY)

### Config
- `.gitignore` (UPDATE)
- `README_LOCAL.md` (NEW - setup leve)
- `docker-compose.yml` (OPTIMIZE)

---

## 🚀 Próximo Passo?

Confirme as 5 perguntas acima e podemos começar a implementação!
