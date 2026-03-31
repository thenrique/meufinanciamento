-- Tabela de registros de pagamentos para "Estimado x Realizado"
CREATE TABLE payment_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  loan_id UUID REFERENCES loans(id) ON DELETE CASCADE NOT NULL,
  payment_date DATE NOT NULL,
  amount_paid DECIMAL(15,2) NOT NULL CHECK (amount_paid > 0),
  payment_type TEXT NOT NULL CHECK (payment_type IN ('normal', 'extra_monthly', 'extra_one_time', 'amortization')),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices para performance
CREATE UNIQUE INDEX idx_unique_payment_per_day ON payment_records(loan_id, payment_date);
CREATE INDEX idx_payment_records_loan_id ON payment_records(loan_id);
CREATE INDEX idx_payment_records_user_id ON payment_records(user_id);
CREATE INDEX idx_payment_records_date ON payment_records(payment_date);

-- Row Level Security
ALTER TABLE payment_records ENABLE ROW LEVEL SECURITY;

-- Política RLS: usuários só veem seus próprios registros de pagamento
CREATE POLICY "Usuários gerenciam seus registros de pagamento"
  ON payment_records FOR ALL USING (auth.uid() = user_id);

-- Trigger para atualizar updated_at automaticamente
CREATE TRIGGER trg_payment_records_updated_at
  BEFORE UPDATE ON payment_records
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
