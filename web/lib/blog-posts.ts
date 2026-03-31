export interface BlogPost {
  slug: string;
  title: string;
  description: string;
  content: string;
  publishedAt: string;
  readTimeMinutes: number;
}

export const blogPosts: BlogPost[] = [
  {
    slug: 'como-amortizar-financiamento-caixa-2025',
    title: 'Como amortizar o financiamento da Caixa pelo app: passo a passo 2025',
    description:
      'Guia completo e atualizado para amortizar seu financiamento imobiliário da Caixa Econômica Federal com segurança e economia máxima.',
    publishedAt: '2025-01-15',
    readTimeMinutes: 6,
    content: `
<h2>Por que amortizar o financiamento da Caixa vale a pena?</h2>
<p>A Caixa Econômica Federal é responsável por mais de 70% dos financiamentos imobiliários do Brasil. Se você tem um contrato ativo, saiba que amortizar — ou seja, pagar parcelas extras para reduzir o saldo devedor — pode representar uma economia de dezenas de milhares de reais ao longo do contrato.</p>
<p>A lógica é simples: quanto mais cedo você reduz o saldo devedor, menos juros incide sobre ele. Em um financiamento de 30 anos com taxa de 10% ao ano, os juros chegam a custar mais do que o próprio imóvel. Amortizar regularmente muda esse cenário de forma significativa.</p>

<h2>Dois tipos de amortização na Caixa</h2>
<p>A Caixa permite dois tipos de amortização extraordinária:</p>
<ul>
  <li><strong>Redução de prazo:</strong> você mantém o valor da parcela e paga o financiamento em menos tempo. É a opção que mais economiza em juros totais.</li>
  <li><strong>Redução de parcela:</strong> você mantém o prazo original, mas o valor mensal cai. Ideal para quem precisa de alívio no fluxo de caixa imediato.</li>
</ul>
<p>Qual das duas escolher depende do seu perfil e do momento financeiro. O Amortizador Pro simula os dois cenários automaticamente para você comparar.</p>

<h2>Passo a passo: como amortizar pelo aplicativo Habitação Caixa</h2>
<ol>
  <li><strong>Baixe o app Habitação Caixa</strong> (disponível para Android e iOS gratuitamente).</li>
  <li><strong>Faça login</strong> com o mesmo CPF e senha do seu internet banking.</li>
  <li>No menu principal, acesse <em>"Meu Financiamento"</em> e selecione o contrato desejado.</li>
  <li>Toque em <em>"Amortização Extraordinária"</em>.</li>
  <li>Escolha entre <strong>reduzir prazo</strong> ou <strong>reduzir parcela</strong>.</li>
  <li>Informe o valor que deseja amortizar (mínimo geralmente é R$ 50,00).</li>
  <li>Confirme com sua senha ou biometria.</li>
</ol>
<p>O crédito é processado imediatamente e o novo saldo aparece na próxima atualização do app.</p>

<h2>Cuidados importantes antes de amortizar</h2>
<p>Antes de usar suas reservas para amortizar, certifique-se de que:</p>
<ul>
  <li>Você possui uma reserva de emergência de pelo menos 3 a 6 meses de despesas.</li>
  <li>Não há dívidas com juros mais altos (cartão de crédito, cheque especial) pendentes.</li>
  <li>A taxa do seu financiamento é maior do que o rendimento líquido das suas aplicações financeiras.</li>
</ul>
<p>Esse último ponto é crucial. Se seu financiamento está em 9% ao ano e sua aplicação rende 11% ao ano líquido, pode valer mais a pena investir do que amortizar. O Amortizador Pro faz essa comparação automaticamente com a taxa Selic atual.</p>

<h2>Use o FGTS para amortizar</h2>
<p>Se você possui saldo no FGTS, pode utilizá-lo para amortizar o financiamento da Caixa a cada 2 anos (para redução de saldo) ou anualmente (para abater até 80% das parcelas). O processo é feito pelo próprio app da Caixa ou pelo app FGTS.</p>
<p>O ideal é planejar o momento certo para usar o FGTS — e é exatamente isso que o Amortizador Pro faz: ele calcula quando o uso do FGTS gera o maior impacto na redução de juros.</p>

<h2>Comece a simular agora</h2>
<p>Antes de amortizar, simule o impacto no nosso simulador gratuito. Informe seu saldo devedor, taxa de juros e prazo restante, e veja em segundos quanto você economizaria em diferentes cenários.</p>
<p><strong>Baixe o Amortizador Pro</strong> para receber alertas personalizados e acompanhar seu financiamento mês a mês — tudo em um só lugar.</p>
`,
  },
  {
    slug: 'sac-ou-price-qual-sistema-e-melhor',
    title: 'SAC ou PRICE: qual sistema é melhor para o seu perfil?',
    description:
      'Entenda a diferença entre os sistemas de amortização SAC e PRICE, quando cada um é mais vantajoso e como escolher o ideal para o seu financiamento.',
    publishedAt: '2025-01-22',
    readTimeMinutes: 7,
    content: `
<h2>A escolha que poucos fazem com cuidado</h2>
<p>Na hora de assinar o contrato de financiamento, uma das decisões mais importantes — e frequentemente subestimadas — é o sistema de amortização. A escolha entre SAC e PRICE pode significar uma diferença de dezenas de milhares de reais ao longo do financiamento.</p>
<p>Neste artigo, vamos explicar como cada sistema funciona e, principalmente, qual faz mais sentido para o seu momento de vida.</p>

<h2>O que é o sistema SAC?</h2>
<p>SAC significa <strong>Sistema de Amortização Constante</strong>. Nele, a parcela de amortização (a parte que efetivamente abate o saldo devedor) é sempre igual durante todo o contrato.</p>
<p>Como os juros incidem sobre um saldo que diminui mais rapidamente, as parcelas começam maiores e vão caindo ao longo do tempo. Isso pode parecer desvantajoso no início, mas no total você paga menos juros.</p>
<p><strong>Exemplo prático (SAC):</strong></p>
<ul>
  <li>Financiamento de R$ 300.000 em 240 meses a 10% a.a.</li>
  <li>1ª parcela: aproximadamente R$ 3.750</li>
  <li>120ª parcela: aproximadamente R$ 2.500</li>
  <li>240ª parcela: aproximadamente R$ 1.260</li>
</ul>

<h2>O que é o sistema PRICE?</h2>
<p>PRICE (Tabela Price) é o <strong>Sistema Francês de Amortização</strong>. Nele, as parcelas são todas iguais do início ao fim. A distribuição entre juros e amortização muda ao longo do tempo: no início, a maior parte da parcela são juros; no final, a maior parte é amortização.</p>
<p><strong>Exemplo prático (PRICE):</strong></p>
<ul>
  <li>Mesmo financiamento de R$ 300.000 em 240 meses a 10% a.a.</li>
  <li>Todas as parcelas: aproximadamente R$ 2.895</li>
  <li>Total de juros pagos: significativamente maior que no SAC</li>
</ul>

<h2>Qual sistema paga menos juros no total?</h2>
<p>O <strong>SAC paga menos juros no total</strong>. Isso acontece porque o saldo devedor cai mais depressa, reduzindo a base sobre a qual os juros são calculados. A diferença pode chegar a 20-30% nos juros totais para financiamentos longos.</p>

<h2>Então por que alguém escolhe PRICE?</h2>
<p>Porque a parcela inicial do PRICE é menor. Para quem está no limite do orçamento no momento da compra, isso pode ser determinante para conseguir a aprovação do crédito ou para não comprometer demais a renda familiar nos primeiros anos.</p>
<p>O banco também prefere o PRICE porque garante receita de juros mais distribuída ao longo do tempo.</p>

<h2>Qual escolher?</h2>
<p>A resposta depende de dois fatores principais:</p>
<ol>
  <li><strong>Capacidade de pagamento inicial:</strong> Se você pode arcar com parcelas maiores no começo, o SAC é quase sempre mais vantajoso.</li>
  <li><strong>Prazo que pretende manter o financiamento:</strong> Se planeja quitar ou amortizar pesado nos primeiros anos, a diferença entre os sistemas diminui.</li>
</ol>
<p>Uma regra prática: se a parcela inicial do SAC cabe no seu orçamento com conforto, vá de SAC. Se a diferença for pequena, considere o PRICE pela previsibilidade das parcelas fixas.</p>

<h2>E se eu já tenho um financiamento no sistema errado?</h2>
<p>Não existe portabilidade de sistema após a assinatura do contrato. A alternativa é compensar com amortizações extraordinárias frequentes — o que, no sistema PRICE, é ainda mais valioso, pois reduz o principal sobre o qual os juros crescem.</p>

<h2>Simule antes de decidir</h2>
<p>O Amortizador Pro simula os dois sistemas com os dados reais do seu contrato, mostrando o impacto de amortizações extras em cada cenário. <strong>Baixe o app gratuitamente</strong> e tome decisões baseadas em números, não em achismos.</p>
`,
  },
  {
    slug: 'fgts-financiamento-imobiliario-quando-usar',
    title: 'FGTS no financiamento imobiliário: quando realmente vale usar?',
    description:
      'Saiba quando é vantajoso usar o FGTS para amortizar seu financiamento imobiliário e como calcular o melhor momento para agir.',
    publishedAt: '2025-01-29',
    readTimeMinutes: 6,
    content: `
<h2>O FGTS rende menos do que parece</h2>
<p>O Fundo de Garantia do Tempo de Serviço (FGTS) é corrigido por TR + 3% ao ano. Em um cenário de juros altos como o atual, onde a Selic está acima de 10%, o FGTS rende significativamente menos do que outras opções de renda fixa. Isso cria uma oportunidade: usar o saldo do FGTS para amortizar um financiamento que cobra taxas mais altas pode ser um ótimo negócio.</p>

<h2>Regras básicas para usar o FGTS no financiamento</h2>
<p>Para usar o FGTS na amortização do financiamento imobiliário, algumas condições precisam ser atendidas:</p>
<ul>
  <li>O imóvel deve ser de uso residencial e estar enquadrado no Sistema Financeiro de Habitação (SFH).</li>
  <li>O mutuário não pode ter outro imóvel em seu nome no mesmo município.</li>
  <li>O financiamento deve estar com as parcelas em dia.</li>
  <li>O uso do FGTS para redução de saldo pode ser feito a cada 2 anos.</li>
  <li>Para abater até 80% das parcelas futuras, o intervalo cai para 12 meses.</li>
</ul>

<h2>Quando vale a pena usar o FGTS?</h2>
<p>A pergunta certa não é "devo usar o FGTS?", mas sim "quando e quanto devo usar?". A resposta depende de três variáveis:</p>
<ol>
  <li><strong>Taxa do seu financiamento:</strong> Se é 9% a.a. ou mais, o FGTS (que rende ~3% a.a.) claramente custa menos "guardado". Usar faz sentido.</li>
  <li><strong>Fase do financiamento:</strong> Nos primeiros anos, a proporção de juros nas parcelas é maior. Amortizar cedo tem impacto maior.</li>
  <li><strong>Prazo restante:</strong> Quanto mais tempo falta, maior o benefício de reduzir o saldo agora.</li>
</ol>

<h2>Reduzir prazo ou parcela com o FGTS?</h2>
<p>Assim como na amortização comum, você pode usar o FGTS para reduzir o prazo (pagando menos juros no total) ou para reduzir o valor das parcelas (aliviando o orçamento mensal).</p>
<p>Se você não tem dificuldades financeiras imediatas, a <strong>redução de prazo maximiza a economia em juros</strong>. Em um financiamento de R$ 400.000 a 10% a.a., usar R$ 50.000 do FGTS para reduzir o prazo pode economizar mais de R$ 80.000 em juros — uma "rentabilidade implícita" de 10% ao ano, garantida.</p>

<h2>O erro mais comum com o FGTS</h2>
<p>Muitas pessoas guardam o FGTS para uma eventual demissão, sem considerar que o benefício de usá-lo no financiamento pode ser muito maior do que a segurança de tê-lo parado.</p>
<p>A lógica correta é: o FGTS usado no financiamento "rende" o equivalente à taxa do seu financiamento (porque evita esses juros). Se sua taxa é 10% e o FGTS rende 3%, usar o FGTS é como fazer um investimento de 10% ao ano com risco zero.</p>

<h2>Como calcular o momento ideal</h2>
<p>Calcular manualmente o impacto do FGTS em diferentes momentos e valores é complexo. O Amortizador Pro faz isso automaticamente: basta informar seu saldo de FGTS e o app mostra qual o melhor momento para usá-lo, quanto você economizaria e se vale mais a pena amortizar ou manter o saldo investido.</p>

<h2>Atenção: FGTS não pode ser usado em qualquer financiamento</h2>
<p>Financiamentos fora do SFH (acima do valor limite, geralmente R$ 1,5 milhão) não permitem o uso do FGTS. Da mesma forma, imóveis comerciais ou terrenos sem construção ficam de fora. Consulte seu contrato ou o simulador para verificar sua elegibilidade.</p>

<h2>Planeje com dados reais</h2>
<p>Tomar a decisão correta sobre o FGTS exige simulação personalizada. <strong>Baixe o Amortizador Pro</strong> e tenha em mãos a análise completa: quando usar, quanto usar, qual modalidade escolher e quanto você vai economizar em juros no total.</p>
`,
  },
];

export function getPostBySlug(slug: string): BlogPost | undefined {
  return blogPosts.find((p) => p.slug === slug);
}
