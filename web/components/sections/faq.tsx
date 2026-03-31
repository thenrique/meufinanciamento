'use client';

import { useState } from 'react';

const faqs = [
  {
    question: 'O app funciona para qualquer banco?',
    answer:
      'O Amortizador Pro é compatível com os principais bancos que operam o Sistema Financeiro de Habitação (SFH) no Brasil: Caixa Econômica Federal, Bradesco, Itaú, Santander, Banco do Brasil e outros. Para financiamentos fora do SFH, o simulador ainda funciona, mas alguns recursos específicos podem variar.',
  },
  {
    question: 'Os cálculos consideram a TR (Taxa Referencial)?',
    answer:
      'Sim. O app aplica a TR histórica e realiza projeções com base nos cenários mais recentes divulgados pelo Banco Central. No simulador do site, utilizamos a taxa pura para simplificar o cálculo, mas no app completo a TR é considerada para máxima precisão.',
  },
  {
    question: 'É seguro informar os dados do meu financiamento?',
    answer:
      'Totalmente seguro. O Amortizador Pro não solicita acesso às suas contas bancárias, senhas ou qualquer dado sensível. Você informa apenas os dados técnicos do contrato (saldo, taxa, prazo), que ficam armazenados localmente no seu dispositivo. Não acessamos seus dados sem sua autorização.',
  },
  {
    question: 'Como funciona o plano premium?',
    answer:
      'O plano gratuito inclui o simulador completo e o acompanhamento de um financiamento. O plano premium (a partir de R$ 9,90/mês) adiciona múltiplos financiamentos, alertas automáticos por notificação push, o comparativo Amortizar vs. Investir em tempo real, exportação de relatório em PDF e suporte prioritário.',
  },
  {
    question: 'Posso usar o FGTS pelo app?',
    answer:
      'O app não executa movimentações financeiras diretamente. O que ele faz é calcular o impacto do uso do FGTS em diferentes cenários e te avisar qual o melhor momento para agir. A solicitação de uso do FGTS em si é feita pelo app da Caixa ou pelo aplicativo FGTS, de acordo com as normas da Caixa Econômica Federal.',
  },
];

export function FAQ() {
  const [openIndex, setOpenIndex] = useState<number | null>(null);

  return (
    <section className="section-padding bg-surface">
      <div className="section-container">
        <div className="text-center mb-12">
          <h2 className="text-3xl sm:text-4xl font-bold text-brand-navy mb-4">
            Perguntas frequentes
          </h2>
          <p className="text-gray-600 text-lg">
            Tem outra dúvida?{' '}
            <a
              href="mailto:contato@amortizadorpro.com.br"
              className="text-brand-green hover:underline font-medium"
            >
              Entre em contato
            </a>
          </p>
        </div>

        <div className="max-w-2xl mx-auto space-y-3">
          {faqs.map((faq, idx) => (
            <div
              key={idx}
              className="bg-white rounded-xl border border-gray-100 shadow-sm overflow-hidden"
            >
              <button
                className="w-full flex items-center justify-between gap-4 px-6 py-5 text-left hover:bg-gray-50 transition-colors"
                onClick={() => setOpenIndex(openIndex === idx ? null : idx)}
                aria-expanded={openIndex === idx}
              >
                <span className="font-semibold text-gray-900">{faq.question}</span>
                <span
                  className={`text-brand-green text-xl flex-shrink-0 transition-transform duration-200 ${
                    openIndex === idx ? 'rotate-45' : ''
                  }`}
                >
                  +
                </span>
              </button>

              {openIndex === idx && (
                <div className="px-6 pb-5 text-gray-600 leading-relaxed border-t border-gray-50 pt-4">
                  {faq.answer}
                </div>
              )}
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
