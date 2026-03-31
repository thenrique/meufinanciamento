export function Contact() {
  const whatsappNumber = '5511987654321'; // TODO: Atualizar com seu número
  const whatsappMessage = 'Olá! Tenho dúvidas sobre o Amortizador Pro.';
  const whatsappUrl = `https://wa.me/${whatsappNumber}?text=${encodeURIComponent(whatsappMessage)}`;
  const emailAddress = 'suporte@amortizadorpro.com'; // TODO: Atualizar com seu email
  const emailSubject = 'Dúvidas sobre Amortizador Pro';

  return (
    <section id="contato" className="bg-white section-padding">
      <div className="section-container">
        <div className="text-center mb-12">
          <h2 className="text-3xl sm:text-4xl font-bold text-brand-navy mb-4">
            Entre em Contato
          </h2>
          <p className="text-gray-600 text-lg max-w-xl mx-auto">
            Tem dúvidas? Nossa equipe está pronta para ajudar você!
          </p>
        </div>

        <div className="grid md:grid-cols-2 gap-8 max-w-3xl mx-auto">
          {/* WhatsApp Card */}
          <a
            href={whatsappUrl}
            target="_blank"
            rel="noopener noreferrer"
            className="p-8 bg-gradient-to-br from-green-50 to-green-100 rounded-2xl border border-green-200 hover:shadow-lg transition-all hover:scale-105"
          >
            <div className="flex items-center justify-center w-12 h-12 bg-green-500 rounded-full mb-4">
              <span className="text-xl">💬</span>
            </div>
            <h3 className="text-xl font-bold text-brand-navy mb-2">WhatsApp</h3>
            <p className="text-gray-600 mb-4">
              Chat rápido e direto. Resposta em poucos minutos.
            </p>
            <button className="w-full bg-green-500 hover:bg-green-600 text-white font-semibold py-3 rounded-lg transition-colors">
              Abrir WhatsApp
            </button>
          </a>

          {/* Email Card */}
          <a
            href={`mailto:${emailAddress}?subject=${encodeURIComponent(emailSubject)}`}
            className="p-8 bg-gradient-to-br from-blue-50 to-blue-100 rounded-2xl border border-blue-200 hover:shadow-lg transition-all hover:scale-105"
          >
            <div className="flex items-center justify-center w-12 h-12 bg-blue-500 rounded-full mb-4">
              <span className="text-xl">✉️</span>
            </div>
            <h3 className="text-xl font-bold text-brand-navy mb-2">Email</h3>
            <p className="text-gray-600 mb-4">
              Envie sua pergunta e responderemos em breve.
            </p>
            <button className="w-full bg-blue-500 hover:bg-blue-600 text-white font-semibold py-3 rounded-lg transition-colors">
              Enviar Email
            </button>
          </a>
        </div>

        <div className="mt-12 p-6 bg-blue-50 rounded-xl border border-blue-200 text-center">
          <p className="text-gray-700">
            <span className="font-semibold">Horário de atendimento:</span> Segunda a Sexta, 9h às 18h
          </p>
        </div>
      </div>
    </section>
  );
}
