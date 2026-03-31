import Link from 'next/link';
import { Badge } from '@/components/ui/badge';

export function Hero() {
  return (
    <section className="bg-gradient-to-br from-brand-navy via-brand-navy to-blue-900 text-white section-padding">
      <div className="section-container">
        <div className="max-w-3xl mx-auto text-center">
          {/* Social proof badge */}
          <div className="flex justify-center mb-6">
            <Badge variant="green" className="text-sm px-4 py-1.5">
              🏠 Mais de 10.000 financiamentos simulados
            </Badge>
          </div>

          {/* Headline */}
          <h1 className="text-4xl sm:text-5xl lg:text-6xl font-bold tracking-tight leading-tight mb-6">
            Seu financiamento está te{' '}
            <span className="text-brand-green">custando mais</span> do que deveria.
          </h1>

          {/* Subheadline */}
          <p className="text-lg sm:text-xl text-blue-200 leading-relaxed mb-10 max-w-2xl mx-auto">
            Descubra quanto você pode economizar com amortizações inteligentes — e receba
            alertas no momento certo para agir.
          </p>

          {/* CTAs */}
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Link
              href="/simulador"
              className="inline-flex items-center justify-center gap-2 bg-brand-green text-white font-semibold text-lg px-8 py-4 rounded-xl hover:bg-emerald-600 transition-colors shadow-lg shadow-emerald-900/30"
            >
              🧮 Simular agora — é grátis
            </Link>
            <a
              href="#download"
              className="inline-flex items-center justify-center gap-2 bg-white/10 text-white font-semibold text-lg px-8 py-4 rounded-xl hover:bg-white/20 transition-colors border border-white/20"
            >
              📱 Baixar o app
            </a>
          </div>

          {/* Trust indicators */}
          <div className="mt-12 flex flex-wrap justify-center gap-6 text-sm text-blue-300">
            <span className="flex items-center gap-1.5">✅ Sem cadastro necessário</span>
            <span className="flex items-center gap-1.5">🔒 Seus dados ficam no seu dispositivo</span>
            <span className="flex items-center gap-1.5">⚡ Resultado em segundos</span>
          </div>
        </div>
      </div>
    </section>
  );
}
