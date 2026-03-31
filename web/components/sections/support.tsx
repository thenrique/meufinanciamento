export function Support() {
  const supportTopics = [
    {
      icon: '🚀',
      title: 'Como Começar',
      description: 'Guia passo a passo para fazer seu primeiro simulador',
      link: '#como-comeca',
    },
    {
      icon: '💰',
      title: 'Economia com Amortização',
      description: 'Entenda como você pode economizar nos juros',
      link: '#como-funciona',
    },
    {
      icon: '📱',
      title: 'App Mobile',
      description: 'Guia de uso do aplicativo no seu celular',
      link: '#app',
    },
    {
      icon: '🔐',
      title: 'Segurança',
      description: 'Como seus dados estão protegidos',
      link: '#seguranca',
    },
    {
      icon: '❓',
      title: 'FAQ',
      description: 'Respostas para as perguntas mais comuns',
      link: '#faq',
    },
    {
      icon: '🐛',
      title: 'Reportar Bug',
      description: 'Encontrou um problema? Nos avise!',
      link: 'mailto:bugs@amortizadorpro.com',
    },
  ];

  return (
    <section id="suporte" className="bg-gradient-to-b from-brand-navy-dark to-brand-navy section-padding">
      <div className="section-container">
        <div className="text-center mb-12">
          <h2 className="text-3xl sm:text-4xl font-bold text-white mb-4">
            Centro de Suporte
          </h2>
          <p className="text-brand-navy-light text-lg max-w-xl mx-auto">
            Encontre respostas para suas dúvidas e aprenda a aproveitar ao máximo o Amortizador Pro.
          </p>
        </div>

        <div className="grid md:grid-cols-3 gap-6 max-w-5xl mx-auto">
          {supportTopics.map((topic, idx) => (
            <a
              key={idx}
              href={topic.link}
              className="p-6 bg-white/10 backdrop-blur rounded-xl border border-white/20 hover:bg-white/20 hover:border-white/40 transition-all hover:shadow-xl hover:scale-105 group"
            >
              <div className="text-4xl mb-3 group-hover:scale-125 transition-transform">
                {topic.icon}
              </div>
              <h3 className="text-lg font-bold text-white mb-2">{topic.title}</h3>
              <p className="text-brand-navy-light text-sm">{topic.description}</p>
            </a>
          ))}
        </div>

        {/* Documentation Links */}
        <div className="mt-12 p-8 bg-white/5 rounded-xl border border-white/10">
          <h3 className="text-xl font-bold text-white mb-6 text-center">Documentação</h3>
          <div className="grid sm:grid-cols-2 gap-4 max-w-2xl mx-auto">
            <a
              href="/docs/tutorial"
              className="flex items-center gap-3 p-4 bg-white/10 hover:bg-white/20 rounded-lg transition-colors text-white"
            >
              <span>📖</span>
              <span>Tutorial Completo</span>
            </a>
            <a
              href="/docs/calculadora"
              className="flex items-center gap-3 p-4 bg-white/10 hover:bg-white/20 rounded-lg transition-colors text-white"
            >
              <span>🧮</span>
              <span>Como funciona a calculadora</span>
            </a>
            <a
              href="/docs/sac-price"
              className="flex items-center gap-3 p-4 bg-white/10 hover:bg-white/20 rounded-lg transition-colors text-white"
            >
              <span>📊</span>
              <span>SAC vs PRICE</span>
            </a>
            <a
              href="/docs/privacidade"
              className="flex items-center gap-3 p-4 bg-white/10 hover:bg-white/20 rounded-lg transition-colors text-white"
            >
              <span>🔒</span>
              <span>Privacidade e Segurança</span>
            </a>
          </div>
        </div>
      </div>
    </section>
  );
}
