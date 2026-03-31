const testimonials = [
  {
    quote:
      'Economizei R$ 38.400 em juros ao quitar 4 anos antes. O app me mostrou exatamente quando agir e qual o momento ideal para cada aporte.',
    name: 'Carlos M.',
    location: 'São Paulo',
    avatar: 'CM',
    highlight: 'R$ 38.400 economizados',
  },
  {
    quote:
      'Finalmente entendi se vale mais amortizar ou investir. Simples, sem enrolação e sem precisar entender de finanças para usar.',
    name: 'Ana Paula R.',
    location: 'Belo Horizonte',
    avatar: 'AR',
    highlight: 'Decisão sem enrolação',
  },
  {
    quote:
      'Usei o FGTS no momento certo graças ao alerta. Reduzi 18 meses do prazo sem tirar nada do bolso.',
    name: 'Roberto S.',
    location: 'Curitiba',
    avatar: 'RS',
    highlight: '18 meses a menos',
  },
];

function StarRating() {
  return (
    <div className="flex gap-0.5 text-amber-400 mb-4">
      {[...Array(5)].map((_, i) => (
        <svg key={i} className="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
          <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
        </svg>
      ))}
    </div>
  );
}

export function Testimonials() {
  return (
    <section className="section-padding bg-white">
      <div className="section-container">
        <div className="text-center mb-12">
          <h2 className="text-3xl sm:text-4xl font-bold text-brand-navy mb-4">
            Quem já está economizando
          </h2>
          <p className="text-gray-600 text-lg">
            Histórias reais de brasileiros que tomaram o controle do próprio financiamento.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {testimonials.map((t) => (
            <div
              key={t.name}
              className="bg-surface rounded-2xl p-6 border border-gray-100 flex flex-col"
            >
              <StarRating />

              {/* Highlight badge */}
              <span className="inline-block bg-brand-green-light text-emerald-800 text-xs font-semibold px-3 py-1 rounded-full mb-4 self-start">
                {t.highlight}
              </span>

              <blockquote className="text-gray-700 leading-relaxed flex-1 mb-6">
                &ldquo;{t.quote}&rdquo;
              </blockquote>

              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-full bg-brand-navy flex items-center justify-center text-white text-sm font-bold flex-shrink-0">
                  {t.avatar}
                </div>
                <div>
                  <p className="font-semibold text-gray-900 text-sm">{t.name}</p>
                  <p className="text-gray-500 text-xs">{t.location}</p>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
