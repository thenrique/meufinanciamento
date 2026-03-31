import type { Metadata } from 'next';
import { Header } from '@/components/sections/header';
import { Hero } from '@/components/sections/hero';
import { HowItWorks } from '@/components/sections/how-it-works';
import { Features } from '@/components/sections/features';
import { PaymentHistory } from '@/components/sections/payment-history';
import { Testimonials } from '@/components/sections/testimonials';
import { SimulatorPreview } from '@/components/sections/simulator-preview';
import { FAQ } from '@/components/sections/faq';
import { Support } from '@/components/sections/support';
import { Contact } from '@/components/sections/contact';
import { Footer } from '@/components/sections/footer';

export const metadata: Metadata = {
  title: 'Amortizador Pro — Economize nos juros do seu financiamento',
  description:
    'Descubra quanto você pode economizar com amortizações inteligentes no seu financiamento imobiliário. Simulador gratuito de SAC e PRICE. Análise de FGTS. Acompanhe seu histórico de pagamentos em tempo real.',
};

export default function HomePage() {
  return (
    <>
      <Header />
      <Hero />
      <HowItWorks />
      <Features />
      <PaymentHistory />
      <SimulatorPreview />
      <Testimonials />
      <FAQ />
      <Support />
      <Contact />

      {/* Download Section */}
      <section id="download" className="bg-brand-navy section-padding">
        <div className="section-container text-center">
          <h2 className="text-3xl sm:text-4xl font-bold text-white mb-4">
            Disponível para Android e iOS
          </h2>
          <p className="text-brand-navy-light text-lg mb-10 max-w-xl mx-auto">
            Baixe grátis e comece a economizar nos juros do seu financiamento hoje mesmo.
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center items-center">
            <a
              href="#download"
              className="inline-flex items-center gap-3 bg-white text-brand-navy font-semibold px-6 py-3 rounded-xl hover:bg-gray-100 transition-colors w-56"
            >
              <span className="text-2xl">🍎</span>
              <span className="text-left leading-tight">
                <span className="text-xs block font-normal text-gray-500">Baixar na</span>
                App Store
              </span>
            </a>
            <a
              href="#download"
              className="inline-flex items-center gap-3 bg-white text-brand-navy font-semibold px-6 py-3 rounded-xl hover:bg-gray-100 transition-colors w-56"
            >
              <span className="text-2xl">▶️</span>
              <span className="text-left leading-tight">
                <span className="text-xs block font-normal text-gray-500">Disponível no</span>
                Google Play
              </span>
            </a>
          </div>
          <p className="text-brand-navy-light mt-8 text-sm">
            Simulador gratuito também disponível no site —{' '}
            <a href="/simulador" className="underline hover:text-white transition-colors">
              Acessar agora
            </a>
          </p>
        </div>
      </section>

      <Footer />
    </>
  );
}
