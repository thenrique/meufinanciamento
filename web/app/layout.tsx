import type { Metadata } from 'next';
import { Inter } from 'next/font/google';
import './globals.css';
import { Header } from '@/components/layout/header';
import { Footer } from '@/components/layout/footer';

const inter = Inter({ subsets: ['latin'], variable: '--font-inter' });

export const metadata: Metadata = {
  title: {
    default: 'Amortizador Pro — Economize nos juros do seu financiamento',
    template: '%s | Amortizador Pro',
  },
  description:
    'Calcule quanto você pode economizar com amortizações inteligentes no seu financiamento imobiliário. Simulador gratuito de SAC e PRICE com análise de FGTS.',
  keywords: [
    'amortização financiamento',
    'simulador SAC PRICE',
    'FGTS financiamento imobiliário',
    'economizar juros',
    'amortizar financiamento Caixa',
  ],
  authors: [{ name: 'Amortizador Pro' }],
  openGraph: {
    type: 'website',
    locale: 'pt_BR',
    siteName: 'Amortizador Pro',
    title: 'Amortizador Pro — Economize nos juros do seu financiamento',
    description:
      'Calcule quanto você pode economizar com amortizações inteligentes. Simulador gratuito.',
  },
  robots: { index: true, follow: true },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="pt-BR" className={inter.variable}>
      <body className="bg-surface text-gray-900 antialiased">
        <Header />
        <main>{children}</main>
        <Footer />
      </body>
    </html>
  );
}
