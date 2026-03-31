import Link from 'next/link';

export function SimulatorPreview() {
  return (
    <section className="section-padding bg-brand-navy-light">
      <div className="section-container">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
          {/* Text side */}
          <div>
            <span className="text-brand-green font-semibold text-sm uppercase tracking-wider">
              Simulador gratuito
            </span>
            <h2 className="text-3xl sm:text-4xl font-bold text-brand-navy mt-2 mb-4">
              Descubra sua economia em menos de 1 minuto
            </h2>
            <p className="text-gray-600 text-lg leading-relaxed mb-8">
              Informe os dados básicos do seu financiamento e veja instantaneamente quanto
              você poderia economizar com amortizações extras. Sem cadastro, sem complicação.
            </p>

            <ul className="space-y-3 mb-8">
              {[
                'Funciona para SAC e PRICE',
                'Calcula meses economizados e data de quitação',
                'Mostra o impacto de qualquer valor de aporte',
                'Resultado imediato, direto no navegador',
              ].map((item) => (
                <li key={item} className="flex items-start gap-3 text-gray-700">
                  <span className="text-brand-green text-lg mt-0.5">✓</span>
                  <span>{item}</span>
                </li>
              ))}
            </ul>

            <Link
              href="/simulador"
              className="inline-flex items-center gap-2 bg-brand-green text-white font-semibold text-lg px-8 py-4 rounded-xl hover:bg-emerald-600 transition-colors"
            >
              🧮 Abrir simulador gratuito
            </Link>
          </div>

          {/* Mockup side */}
          <div className="bg-white rounded-2xl shadow-xl p-6 border border-gray-100">
            <div className="mb-5">
              <h3 className="font-bold text-brand-navy text-lg mb-1">Simulador de Amortização</h3>
              <p className="text-gray-500 text-sm">Preencha os dados do seu contrato</p>
            </div>

            <div className="space-y-4 mb-6">
              <div>
                <div className="text-xs font-medium text-gray-600 mb-1">Saldo devedor</div>
                <div className="bg-gray-50 border border-gray-200 rounded-lg px-4 py-3 text-gray-400 text-sm">
                  R$ 250.000,00
                </div>
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <div className="text-xs font-medium text-gray-600 mb-1">Taxa de juros (a.a.)</div>
                  <div className="bg-gray-50 border border-gray-200 rounded-lg px-4 py-3 text-gray-400 text-sm">
                    9,5%
                  </div>
                </div>
                <div>
                  <div className="text-xs font-medium text-gray-600 mb-1">Prazo restante</div>
                  <div className="bg-gray-50 border border-gray-200 rounded-lg px-4 py-3 text-gray-400 text-sm">
                    240 meses
                  </div>
                </div>
              </div>
              <div>
                <div className="text-xs font-medium text-gray-600 mb-1">Aporte extra mensal</div>
                <div className="bg-gray-50 border border-gray-200 rounded-lg px-4 py-3 text-gray-400 text-sm">
                  R$ 500,00
                </div>
              </div>
            </div>

            {/* Resultado preview */}
            <div className="grid grid-cols-2 gap-3">
              <div className="bg-brand-green-light rounded-xl p-4 text-center">
                <div className="text-2xl font-bold text-emerald-700">R$ 41.200</div>
                <div className="text-xs text-emerald-600 mt-1">em juros economizados</div>
              </div>
              <div className="bg-brand-navy-light rounded-xl p-4 text-center">
                <div className="text-2xl font-bold text-brand-navy">52 meses</div>
                <div className="text-xs text-blue-600 mt-1">antes do prazo</div>
              </div>
            </div>

            <p className="text-center text-xs text-gray-400 mt-4">
              * Valores ilustrativos. Use o simulador para calcular o seu cenário real.
            </p>
          </div>
        </div>
      </div>
    </section>
  );
}
