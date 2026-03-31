import type { Metadata } from 'next';
import { SimulatorForm } from './simulator-form';

export const metadata: Metadata = {
  title: 'Simulador de Amortização Gratuito — SAC e PRICE',
  description:
    'Calcule instantaneamente quanto você economizaria com amortizações extras no seu financiamento imobiliário. Funciona para SAC e PRICE, sem cadastro.',
};

export default function SimuladorPage() {
  return (
    <div className="min-h-screen bg-surface section-padding">
      <div className="section-container max-w-2xl">
        {/* Page header */}
        <div className="text-center mb-10">
          <h1 className="text-3xl sm:text-4xl font-bold text-brand-navy mb-3">
            Simulador de Amortização
          </h1>
          <p className="text-gray-600 text-lg">
            Descubra em segundos quanto você pode economizar no seu financiamento.
          </p>
          <p className="text-sm text-gray-500 mt-1">
            Cálculo feito localmente no seu navegador — seus dados não saem do seu dispositivo.
          </p>
        </div>

        <SimulatorForm />
      </div>
    </div>
  );
}
