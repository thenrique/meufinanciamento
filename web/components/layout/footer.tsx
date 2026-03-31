import Link from 'next/link';

export function Footer() {
  return (
    <footer className="bg-gray-900 text-gray-400">
      <div className="section-container py-12">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8 mb-10">
          {/* Brand */}
          <div>
            <div className="flex items-center gap-2 font-bold text-xl text-white mb-3">
              <span className="text-2xl">🏠</span>
              <span>
                Amortizador<span className="text-brand-green"> Pro</span>
              </span>
            </div>
            <p className="text-sm leading-relaxed">
              Ajudamos brasileiros a economizar nos juros do financiamento imobiliário com
              simulações inteligentes e alertas personalizados.
            </p>
          </div>

          {/* Links */}
          <div>
            <h4 className="text-white font-semibold mb-3">Produto</h4>
            <ul className="space-y-2 text-sm">
              <li>
                <Link href="/simulador" className="hover:text-white transition-colors">
                  Simulador gratuito
                </Link>
              </li>
              <li>
                <Link href="/blog" className="hover:text-white transition-colors">
                  Blog
                </Link>
              </li>
              <li>
                <a href="#download" className="hover:text-white transition-colors">
                  Baixar o app
                </a>
              </li>
              <li>
                <a href="/#precos" className="hover:text-white transition-colors">
                  Planos e preços
                </a>
              </li>
            </ul>
          </div>

          {/* Legal */}
          <div>
            <h4 className="text-white font-semibold mb-3">Legal</h4>
            <ul className="space-y-2 text-sm">
              <li>
                <Link href="/privacidade" className="hover:text-white transition-colors">
                  Política de Privacidade
                </Link>
              </li>
              <li>
                <Link href="/termos" className="hover:text-white transition-colors">
                  Termos de Uso
                </Link>
              </li>
              <li>
                <a href="mailto:contato@amortizadorpro.com.br" className="hover:text-white transition-colors">
                  Contato
                </a>
              </li>
            </ul>
          </div>
        </div>

        {/* Disclaimer */}
        <div className="border-t border-gray-800 pt-8">
          <p className="text-xs text-gray-500 leading-relaxed mb-4">
            <strong className="text-gray-400">Aviso legal:</strong> Este aplicativo fornece
            simulações de caráter exclusivamente educativo e informativo. As projeções e
            cálculos apresentados não constituem consultoria financeira, assessoria de
            investimentos ou recomendação de qualquer produto ou serviço financeiro. Consulte
            sempre um profissional habilitado antes de tomar decisões financeiras.
          </p>
          <p className="text-xs text-gray-600">
            © {new Date().getFullYear()} Amortizador Pro. Todos os direitos reservados.
          </p>
        </div>
      </div>
    </footer>
  );
}
