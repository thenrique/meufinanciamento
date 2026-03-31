export function Footer() {
  const currentYear = new Date().getFullYear();
  const whatsappNumber = '5511987654321'; // TODO: Atualizar com seu número
  const whatsappUrl = `https://wa.me/${whatsappNumber}`;

  return (
    <footer className="bg-brand-navy-dark text-brand-navy-light py-12 border-t border-brand-navy/50">
      <div className="section-container">
        <div className="grid md:grid-cols-4 gap-8 mb-12">
          {/* Brand */}
          <div>
            <h3 className="text-white font-bold text-lg mb-4">Amortizador Pro</h3>
            <p className="text-sm mb-4">
              Economize nos juros do seu financiamento com simulações inteligentes de SAC e PRICE.
            </p>
            <div className="flex gap-3">
              <a
                href={whatsappUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="w-10 h-10 bg-green-500 hover:bg-green-600 rounded-full flex items-center justify-center text-white text-lg transition-colors"
                title="WhatsApp"
              >
                💬
              </a>
              <a
                href="mailto:suporte@amortizadorpro.com"
                className="w-10 h-10 bg-blue-500 hover:bg-blue-600 rounded-full flex items-center justify-center text-white text-lg transition-colors"
                title="Email"
              >
                ✉️
              </a>
            </div>
          </div>

          {/* Produto */}
          <div>
            <h4 className="text-white font-semibold mb-4">Produto</h4>
            <ul className="space-y-2 text-sm">
              <li>
                <a href="/simulador" className="hover:text-white transition-colors">
                  Simulador
                </a>
              </li>
              <li>
                <a href="#features" className="hover:text-white transition-colors">
                  Funcionalidades
                </a>
              </li>
              <li>
                <a href="#download" className="hover:text-white transition-colors">
                  Download App
                </a>
              </li>
              <li>
                <a href="#como-funciona" className="hover:text-white transition-colors">
                  Como Funciona
                </a>
              </li>
            </ul>
          </div>

          {/* Ajuda */}
          <div>
            <h4 className="text-white font-semibold mb-4">Ajuda</h4>
            <ul className="space-y-2 text-sm">
              <li>
                <a href="#faq" className="hover:text-white transition-colors">
                  FAQ
                </a>
              </li>
              <li>
                <a href="#suporte" className="hover:text-white transition-colors">
                  Centro de Suporte
                </a>
              </li>
              <li>
                <a href="#contato" className="hover:text-white transition-colors">
                  Entre em Contato
                </a>
              </li>
              <li>
                <a href="/docs/tutorial" className="hover:text-white transition-colors">
                  Tutorial
                </a>
              </li>
            </ul>
          </div>

          {/* Legal */}
          <div>
            <h4 className="text-white font-semibold mb-4">Legal</h4>
            <ul className="space-y-2 text-sm">
              <li>
                <a href="/termos" className="hover:text-white transition-colors">
                  Termos de Uso
                </a>
              </li>
              <li>
                <a href="/privacidade" className="hover:text-white transition-colors">
                  Privacidade
                </a>
              </li>
              <li>
                <a href="/cookies" className="hover:text-white transition-colors">
                  Política de Cookies
                </a>
              </li>
              <li>
                <a href="/acessibilidade" className="hover:text-white transition-colors">
                  Acessibilidade
                </a>
              </li>
            </ul>
          </div>
        </div>

        <div className="border-t border-brand-navy/50 pt-8">
          <div className="flex flex-col md:flex-row justify-between items-center gap-4">
            <p className="text-sm">
              © {currentYear} Amortizador Pro. Todos os direitos reservados.
            </p>
            <p className="text-xs text-brand-navy-light">
              Desenvolvido com ❤️ para ajudar você a economizar
            </p>
          </div>
        </div>
      </div>
    </footer>
  );
}
