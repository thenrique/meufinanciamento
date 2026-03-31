import { Card, CardTitle, CardDescription } from '@/components/ui/card';

const features = [
  {
    icon: '🧮',
    title: 'Simulador SAC e PRICE com correção pela TR',
    description:
      'Calcule com precisão o impacto de amortizações extras em ambos os sistemas, incluindo a correção pela Taxa Referencial.',
  },
  {
    icon: '📊',
    title: 'Histórico de Pagamentos',
    description:
      'Acompanhe a evolução do seu financiamento mês a mês. Compare o estimado com o realizado e veja exatamente onde estão seus juros.',
  },
  {
    icon: '🏦',
    title: 'FGTS Optimizer',
    description:
      'Descubra quando e quanto usar o seu FGTS para obter o maior impacto na redução de juros.',
  },
  {
    icon: '📈',
    title: 'Alerta Amortizar vs. Investir',
    description:
      'Compare automaticamente se vale mais a pena amortizar ou aplicar no CDB/Selic com base na sua taxa contratada.',
  },
  {
    icon: '📱',
    title: 'Multi-banco',
    description:
      'Compatível com Caixa Econômica Federal, Bradesco, Itaú, Santander e outros bancos que operam o SFH.',
  },
  {
    icon: '📄',
    title: 'Relatório PDF profissional',
    description:
      'Exporte um relatório completo com gráficos e tabela de amortização para guardar ou compartilhar.',
  },
];

export function Features() {
  return (
    <section className="section-padding bg-surface">
      <div className="section-container">
        <div className="text-center mb-12">
          <h2 className="text-3xl sm:text-4xl font-bold text-brand-navy mb-4">
            Tudo que você precisa para economizar
          </h2>
          <p className="text-gray-600 text-lg max-w-2xl mx-auto">
            Funcionalidades pensadas para quem quer tomar o controle do próprio financiamento,
            sem precisar ser especialista em finanças.
          </p>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
          {features.map((feature) => (
            <Card key={feature.title} className="hover:shadow-md transition-shadow">
              <div className="text-4xl mb-4">{feature.icon}</div>
              <CardTitle className="mb-2">{feature.title}</CardTitle>
              <CardDescription>{feature.description}</CardDescription>
            </Card>
          ))}
        </div>
      </div>
    </section>
  );
}
