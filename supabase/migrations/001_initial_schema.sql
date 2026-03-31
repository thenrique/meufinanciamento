-- Habilitar extensões necessárias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Tabela de perfis (estende auth.users do Supabase)
CREATE TABLE profiles (
  id            UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  full_name     TEXT,
  avatar_url    TEXT,
  is_premium    BOOLEAN DEFAULT FALSE,
  premium_since TIMESTAMPTZ,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

-- Financiamentos
CREATE TABLE loans (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  bank_name           TEXT NOT NULL,
  loan_type           TEXT NOT NULL CHECK (loan_type IN ('SAC', 'PRICE')),
  total_amount        NUMERIC(15,2) NOT NULL CHECK (total_amount > 0),
  outstanding_balance NUMERIC(15,2) NOT NULL CHECK (outstanding_balance > 0),
  interest_rate_year  NUMERIC(8,6) NOT NULL CHECK (interest_rate_year > 0 AND interest_rate_year < 30),
  start_date          DATE NOT NULL,
  term_months         INTEGER NOT NULL CHECK (term_months >= 12 AND term_months <= 420),
  remaining_months    INTEGER NOT NULL CHECK (remaining_months >= 1),
  insurance_monthly   NUMERIC(10,2) DEFAULT 0 CHECK (insurance_monthly >= 0),
  fgts_last_use       DATE,
  estimated_salary    NUMERIC(12,2),
  is_active           BOOLEAN DEFAULT TRUE,
  created_at          TIMESTAMPTZ DEFAULT NOW(),
  updated_at          TIMESTAMPTZ DEFAULT NOW()
);

-- Histórico de simulações
CREATE TABLE simulations_history (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  loan_id               UUID REFERENCES loans(id) ON DELETE SET NULL,
  extra_monthly         NUMERIC(12,2) DEFAULT 0,
  extra_one_time        NUMERIC(12,2) DEFAULT 0,
  months_saved          INTEGER,
  total_interest_saved  NUMERIC(15,2),
  payoff_date_base      DATE,
  payoff_date_simulated DATE,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

-- Cache de taxas BCB (TR e Selic)
CREATE TABLE rates_cache (
  series_code TEXT PRIMARY KEY,
  series_name TEXT,
  rate_value  NUMERIC(10,6) NOT NULL,
  reference_date DATE,
  fetched_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Inserir valores default históricos
INSERT INTO rates_cache (series_code, series_name, rate_value, reference_date) VALUES
  ('226', 'TR Mensal', 0.0170, CURRENT_DATE),
  ('11',  'Selic',    10.5000, CURRENT_DATE);

-- Transações / Pagamentos
CREATE TABLE transactions (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  provider         TEXT DEFAULT 'mercadopago',
  external_id      TEXT UNIQUE,
  preference_id    TEXT,
  payment_method   TEXT CHECK (payment_method IN ('pix', 'credit_card', 'debit_card', NULL)),
  amount           NUMERIC(10,2) NOT NULL,
  status           TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'failed', 'refunded')),
  metadata         JSONB,
  created_at       TIMESTAMPTZ DEFAULT NOW(),
  confirmed_at     TIMESTAMPTZ
);

-- Insights do Conselheiro
CREATE TABLE advisor_insights (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  loan_id      UUID REFERENCES loans(id) ON DELETE SET NULL,
  insight_type TEXT NOT NULL,
  title        TEXT NOT NULL,
  body         TEXT NOT NULL,
  urgency      TEXT DEFAULT 'medium' CHECK (urgency IN ('low', 'medium', 'high')),
  data         JSONB,
  action_label TEXT,
  action_url   TEXT,
  is_read      BOOLEAN DEFAULT FALSE,
  is_dismissed BOOLEAN DEFAULT FALSE,
  generated_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at   TIMESTAMPTZ
);

-- Analytics de funil
CREATE TABLE analytics_events (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID REFERENCES profiles(id) ON DELETE SET NULL,
  event_type  TEXT NOT NULL,
  metadata    JSONB,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX idx_loans_user_id ON loans(user_id);
CREATE INDEX idx_loans_active ON loans(user_id, is_active);
CREATE INDEX idx_simulations_user_id ON simulations_history(user_id);
CREATE INDEX idx_simulations_loan_id ON simulations_history(loan_id);
CREATE INDEX idx_transactions_user_id ON transactions(user_id);
CREATE INDEX idx_transactions_external_id ON transactions(external_id);
CREATE INDEX idx_advisor_insights_user ON advisor_insights(user_id, is_dismissed, generated_at);
CREATE INDEX idx_analytics_events_user ON analytics_events(user_id, event_type);
CREATE INDEX idx_analytics_events_type ON analytics_events(event_type, created_at);

-- Row Level Security (RLS)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE loans ENABLE ROW LEVEL SECURITY;
ALTER TABLE simulations_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE advisor_insights ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics_events ENABLE ROW LEVEL SECURITY;

-- Políticas RLS: usuários só veem seus próprios dados
CREATE POLICY "Usuários veem seu próprio perfil"
  ON profiles FOR ALL USING (auth.uid() = id);

CREATE POLICY "Usuários gerenciam seus financiamentos"
  ON loans FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Usuários veem seu histórico de simulações"
  ON simulations_history FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Usuários veem suas transações"
  ON transactions FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Usuários veem seus insights"
  ON advisor_insights FOR ALL USING (auth.uid() = user_id);

-- Trigger para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_loans_updated_at
  BEFORE UPDATE ON loans
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Trigger para criar perfil automaticamente ao cadastrar usuário
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, full_name, avatar_url)
  VALUES (
    NEW.id,
    NEW.raw_user_meta_data->>'full_name',
    NEW.raw_user_meta_data->>'avatar_url'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();
