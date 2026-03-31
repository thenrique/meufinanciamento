--  ============================================================================
--  MIGRATION 002: Create Payment Records Table
--  ============================================================================
--  File: supabase/migrations/002_create_payment_records.sql
--  
--  Instructions:
--  1. Go to: https://app.supabase.com/project/cpncjeeegxrwbwbdzdwe/sql/new
--  2. Copy the SQL below (from "CREATE TABLE" to "EXECUTE FUNCTION update_updated_at()")
--  3. Paste into Supabase SQL Editor
--  4. Click "Run"
--  5. Verify success message appears
--  ============================================================================

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



--  ============================================================================
--  MIGRATION 003: Add Payment Due Date to Loans
--  ============================================================================
--  File: supabase/migrations/003_add_payment_due_date_to_loans.sql
--
--  Instructions:
--  1. Go to: https://app.supabase.com/project/cpncjeeegxrwbwbdzdwe/sql/new
--  2. Copy the SQL below
--  3. Paste into Supabase SQL Editor
--  4. Click "Run"
--  5. Verify success message appears
--  ============================================================================

-- Adicionar coluna de dia de vencimento do pagamento à tabela loans
ALTER TABLE loans ADD COLUMN payment_due_date_day INTEGER DEFAULT 10 CHECK (payment_due_date_day >= 1 AND payment_due_date_day <= 31);



--  ============================================================================
--  VERIFICATION QUERIES
--  ============================================================================
--  Run these queries after applying migrations to verify everything is correct
--  ============================================================================

-- Verify payment_records table was created
SELECT table_name FROM information_schema.tables 
WHERE table_name = 'payment_records' AND table_schema = 'public';

-- Verify payment_records columns
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'payment_records' 
ORDER BY ordinal_position;

-- Verify payment_records indexes
SELECT indexname FROM pg_indexes WHERE tablename = 'payment_records';

-- Verify payment_records RLS is enabled
SELECT tablename, rowsecurity FROM pg_tables 
WHERE schemaname = 'public' AND tablename = 'payment_records';

-- Verify payment_records RLS policies
SELECT policyname FROM pg_policies WHERE tablename = 'payment_records';

-- Verify payment_records trigger
SELECT trigger_name FROM information_schema.triggers 
WHERE event_object_table = 'payment_records';

-- Verify payment_due_date_day column was added to loans
SELECT column_name, data_type, column_default 
FROM information_schema.columns 
WHERE table_name = 'loans' AND column_name = 'payment_due_date_day';
