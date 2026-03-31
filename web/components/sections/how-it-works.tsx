const steps = [
  {
    number: '01',
    icon: '📋',
    title: 'Cadastre seu financiamento',
    description:
      'Informe os dados do seu contrato. Leva menos de 2 minutos e você não precisa de nenhum documento em mãos.',
  },
  {
    number: '02',
    icon: '💡',
    title: 'Veja sua economia real',
    description:
      'O app calcula exatamente quanto você pagaria a menos hoje com diferentes cenários de amortização.',
  },
  {
    number: '03',
    icon: '🔔',
    title: 'Receba alertas inteligentes',
    description:
      'Te avisamos quando vale amortizar, quando usar o FGTS e quando é melhor investir do que pagar o financiamento.',
  },
];

export function HowItWorks() {
  return (
    <section className="section-padding bg-white">
      <div className="section-container">
        <div className="text-center mb-12">
          <h2 className="text-3xl sm:text-4xl font-bold text-brand-navy mb-4">
            Como funciona
          </h2>
          <p className="text-gray-600 text-lg max-w-xl mx-auto">
            Em três passos simples, você passa a tomar decisões financeiras com confiança.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {steps.map((step, idx) => (
            <div key={step.number} className="relative flex flex-col items-center text-center">
              {/* Connector line between steps */}
              {idx < steps.length - 1 && (
                <div className="hidden md:block absolute top-10 left-[60%] w-[80%] h-0.5 bg-brand-green-light z-0" />
              )}

              {/* Step number circle */}
              <div className="relative z-10 flex items-center justify-center w-20 h-20 rounded-full bg-brand-green-light border-4 border-white shadow-md mb-5">
                <span className="text-3xl">{step.icon}</span>
              </div>

              {/* Step number badge */}
              <span className="text-xs font-bold text-brand-green tracking-wider uppercase mb-2">
                Passo {step.number}
              </span>

              <h3 className="text-xl font-bold text-brand-navy mb-2">{step.title}</h3>
              <p className="text-gray-600 leading-relaxed">{step.description}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
