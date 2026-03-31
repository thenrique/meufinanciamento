'use client';

import { useState, FormEvent } from 'react';
import { calculate, type FinanceInput, type FinanceResult } from '@/lib/finance';
import { formatCurrency, formatDate } from '@/lib/utils';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';

interface FormState {
  balance: string;
  annualRate: string;
  months: string;
  system: 'SAC' | 'PRICE';
  extraMonthly: string;
}

interface FormErrors {
  balance?: string;
  annualRate?: string;
  months?: string;
}

function validateForm(form: FormState): FormErrors {
  const errors: FormErrors = {};
  if (!form.balance || Number(form.balance.replace(',', '.')) <= 0)
    errors.balance = 'Informe um saldo devedor válido.';
  if (!form.annualRate || Number(form.annualRate.replace(',', '.')) <= 0)
    errors.annualRate = 'Informe a taxa de juros anual.';
  if (!form.months || Number(form.months) < 1)
    errors.months = 'Informe o prazo restante em meses.';
  return errors;
}

export function SimulatorForm() {
  const [form, setForm] = useState<FormState>({
    balance: '',
    annualRate: '',
    months: '',
    system: 'SAC',
    extraMonthly: '',
  });
  const [errors, setErrors] = useState<FormErrors>({});
  const [result, setResult] = useState<FinanceResult | null>(null);
  const [loading, setLoading] = useState(false);

  function handleChange(e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) {
    setForm((prev) => ({ ...prev, [e.target.name]: e.target.value }));
    setErrors((prev) => ({ ...prev, [e.target.name]: undefined }));
  }

  function handleSubmit(e: FormEvent) {
    e.preventDefault();
    const errs = validateForm(form);
    if (Object.keys(errs).length > 0) {
      setErrors(errs);
      return;
    }

    setLoading(true);
    setTimeout(() => {
      const input: FinanceInput = {
        balance: parseFloat(form.balance.replace(',', '.')),
        annualRate: parseFloat(form.annualRate.replace(',', '.')),
        months: parseInt(form.months, 10),
        system: form.system,
        extraMonthly: parseFloat(form.extraMonthly.replace(',', '.') || '0') || 0,
      };
      const res = calculate(input);
      setResult(res);
      setLoading(false);
    }, 50);
  }

  return (
    <>
      <Card className="mb-8">
        <form onSubmit={handleSubmit} noValidate className="space-y-5">
          <Input
            id="balance"
            name="balance"
            label="Saldo devedor (R$)"
            placeholder="Ex.: 250000"
            value={form.balance}
            onChange={handleChange}
            error={errors.balance}
            hint="Veja o saldo atual no extrato ou app do banco."
            inputMode="decimal"
          />

          <div className="grid grid-cols-2 gap-4">
            <Input
              id="annualRate"
              name="annualRate"
              label="Taxa de juros anual (%)"
              placeholder="Ex.: 9.5"
              value={form.annualRate}
              onChange={handleChange}
              error={errors.annualRate}
              hint="Taxa nominal anual do contrato."
              inputMode="decimal"
            />
            <Input
              id="months"
              name="months"
              label="Prazo restante (meses)"
              placeholder="Ex.: 240"
              value={form.months}
              onChange={handleChange}
              error={errors.months}
              inputMode="numeric"
            />
          </div>

          <div className="flex flex-col gap-1">
            <label htmlFor="system" className="text-sm font-medium text-gray-700">
              Sistema de amortização
            </label>
            <select
              id="system"
              name="system"
              value={form.system}
              onChange={handleChange}
              className="w-full rounded-xl border border-gray-300 px-4 py-3 text-gray-900 bg-white focus:outline-none focus:ring-2 focus:ring-brand-green focus:border-transparent transition-colors"
            >
              <option value="SAC">SAC — Sistema de Amortização Constante</option>
              <option value="PRICE">PRICE — Tabela Price (parcela fixa)</option>
            </select>
          </div>

          <Input
            id="extraMonthly"
            name="extraMonthly"
            label="Aporte extra mensal (R$)"
            placeholder="Ex.: 500 (opcional)"
            value={form.extraMonthly}
            onChange={handleChange}
            hint="Valor adicional que você pretende pagar por mês além da parcela normal."
            inputMode="decimal"
          />

          <Button type="submit" size="lg" className="w-full" disabled={loading}>
            {loading ? 'Calculando...' : '🧮 Calcular economia'}
          </Button>
        </form>
      </Card>

      {result && (
        <div className="space-y-4">
          <h2 className="text-xl font-bold text-brand-navy text-center mb-2">
            Resultado da sua simulação
          </h2>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <Card variant="green" className="text-center">
              <div className="text-3xl font-bold text-emerald-700 mb-1">
                {formatCurrency(result.interestSaved)}
              </div>
              <div className="text-sm text-emerald-600 font-medium">
                economizados em juros
              </div>
            </Card>

            <Card variant="navy" className="text-center">
              <div className="text-3xl font-bold text-brand-navy mb-1">
                {result.monthsSaved} {result.monthsSaved === 1 ? 'mês' : 'meses'}
              </div>
              <div className="text-sm text-blue-600 font-medium">antes do prazo original</div>
            </Card>
          </div>

          <Card>
            <div className="flex justify-between items-center">
              <span className="text-gray-600">Data estimada de quitação</span>
              <span className="font-bold text-brand-navy capitalize">
                {formatDate(result.payoffDate)}
              </span>
            </div>
            <hr className="my-3 border-gray-100" />
            <div className="flex justify-between items-center">
              <span className="text-gray-600">Juros sem aporte extra</span>
              <span className="font-semibold text-gray-900">
                {formatCurrency(result.totalInterestBase)}
              </span>
            </div>
            <div className="flex justify-between items-center mt-2">
              <span className="text-gray-600">Juros com aporte extra</span>
              <span className="font-semibold text-emerald-600">
                {formatCurrency(result.totalInterestExtra)}
              </span>
            </div>
          </Card>

          {/* CTA */}
          <div className="bg-brand-navy rounded-2xl p-6 text-center text-white">
            <p className="font-semibold text-lg mb-2">
              Quer alertas quando for o melhor momento para amortizar?
            </p>
            <p className="text-blue-200 text-sm mb-4">
              O app completo avisa você automaticamente e considera a TR, FGTS e comparativo
              com investimentos.
            </p>
            <a
              href="#download"
              className="inline-flex items-center gap-2 bg-brand-green text-white font-semibold px-6 py-3 rounded-xl hover:bg-emerald-600 transition-colors"
            >
              📱 Baixar o app gratuito
            </a>
          </div>
        </div>
      )}
    </>
  );
}
