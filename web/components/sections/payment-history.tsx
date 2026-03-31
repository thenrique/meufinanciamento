import Link from 'next/link';
import { Card } from '@/components/ui/card';

export function PaymentHistory() {
  return (
    <section className="section-padding bg-gradient-to-br from-emerald-50 via-white to-blue-50">
      <div className="section-container">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
          {/* Text side */}
          <div>
            <div className="inline-block mb-4">
              <span className="bg-emerald-100 text-emerald-700 text-sm font-semibold px-4 py-2 rounded-full">
                ✨ Novo no App
              </span>
            </div>
            <h2 className="text-3xl sm:text-4xl font-bold text-brand-navy mb-4">
              Acompanhe seu financiamento em tempo real
            </h2>
            <p className="text-gray-600 text-lg leading-relaxed mb-8">
              Compare o estimado com o realizado mês a mês. Saiba exatamente onde estão seus juros,
              acompanhe a evolução do saldo devedor e simule pagamentos extras direto pelo app.
            </p>

            <ul className="space-y-3 mb-8">
              {[
                'Gráfico interativo de saldo devedor',
                'Comparativo detalhado de juros pagos vs. estimado',
                'Previsão automática de quitação',
                'Histórico completo de pagamentos mês a mês',
                'Simule pagamentos extras em tempo real',
              ].map((item) => (
                <li key={item} className="flex items-start gap-3 text-gray-700">
                  <span className="text-emerald-600 text-lg font-bold mt-0.5">•</span>
                  <span>{item}</span>
                </li>
              ))}
            </ul>

            <div className="flex flex-col sm:flex-row gap-4">
              <a
                href="#download"
                className="inline-flex items-center justify-center gap-2 bg-emerald-600 text-white font-semibold text-lg px-8 py-4 rounded-xl hover:bg-emerald-700 transition-colors shadow-lg shadow-emerald-600/30"
              >
                📱 Abrir no App Móvel
              </a>
              <Link
                href="/simulador"
                className="inline-flex items-center justify-center gap-2 bg-white text-emerald-600 font-semibold text-lg px-8 py-4 rounded-xl hover:bg-emerald-50 transition-colors border-2 border-emerald-200"
              >
                🧮 Simular agora
              </Link>
            </div>
          </div>

          {/* Mockup side */}
          <div className="bg-white rounded-2xl shadow-xl p-6 border border-gray-100">
            <div className="mb-6">
              <h3 className="font-bold text-brand-navy text-lg mb-1">Histórico de Pagamentos</h3>
              <p className="text-gray-500 text-sm">Seu financiamento mês a mês</p>
            </div>

            {/* Summary Cards */}
            <div className="grid grid-cols-2 gap-3 mb-6">
              <div className="bg-emerald-50 rounded-xl p-4 border border-emerald-100">
                <div className="text-xs text-emerald-600 mb-1 font-medium">Saldo Devedor</div>
                <div className="text-xl font-bold text-emerald-700">R$ 185.420</div>
              </div>
              <div className="bg-blue-50 rounded-xl p-4 border border-blue-100">
                <div className="text-xs text-blue-600 mb-1 font-medium">Próximo Pagamento</div>
                <div className="text-xl font-bold text-blue-700">R$ 1.245</div>
              </div>
            </div>

            {/* Chart representation */}
            <div className="mb-6 p-4 bg-gray-50 rounded-xl">
              <div className="text-xs font-medium text-gray-600 mb-3">Evolução do Saldo</div>
              <div className="space-y-2">
                <div className="flex items-center gap-2">
                  <span className="text-xs text-gray-500 w-8">Mês 1</span>
                  <div className="flex-1 bg-emerald-200 rounded h-3" style={{ width: '100%' }}></div>
                </div>
                <div className="flex items-center gap-2">
                  <span className="text-xs text-gray-500 w-8">Mês 2</span>
                  <div className="flex-1 bg-emerald-300 rounded h-3" style={{ width: '98%' }}></div>
                </div>
                <div className="flex items-center gap-2">
                  <span className="text-xs text-gray-500 w-8">Mês 3</span>
                  <div className="flex-1 bg-emerald-400 rounded h-3" style={{ width: '96%' }}></div>
                </div>
                <div className="flex items-center gap-2">
                  <span className="text-xs text-gray-500 w-8">Mês 4</span>
                  <div className="flex-1 bg-emerald-500 rounded h-3" style={{ width: '94%' }}></div>
                </div>
              </div>
            </div>

            {/* Comparison */}
            <div className="p-4 bg-blue-50 rounded-xl border border-blue-100">
              <div className="text-xs font-medium text-blue-600 mb-2">Juros Comparativo</div>
              <div className="flex justify-between items-center">
                <div>
                  <div className="text-sm text-blue-600">Estimado</div>
                  <div className="text-lg font-bold text-blue-700">R$ 2.150</div>
                </div>
                <div className="text-2xl text-blue-400">→</div>
                <div>
                  <div className="text-sm text-emerald-600">Realizado</div>
                  <div className="text-lg font-bold text-emerald-700">R$ 1.890</div>
                </div>
              </div>
            </div>

            <p className="text-center text-xs text-gray-400 mt-4">
              * Dados ilustrativos. Abra o app para ver seus dados reais.
            </p>
          </div>
        </div>
      </div>
    </section>
  );
}
