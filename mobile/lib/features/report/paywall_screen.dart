import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/constants.dart';
import '../../shared/widgets/app_button.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  static const _checkoutUrl =
      String.fromEnvironment('CHECKOUT_URL', defaultValue: 'https://www.mercadopago.com.br');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          // Header azul marinho
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.navy, Color(0xFF2D5487)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(32),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                  24, MediaQuery.of(context).padding.top + 24, 24, 32),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back,
                            color: AppColors.white),
                        onPressed: () => context.pop(),
                      ),
                      const Spacer(),
                    ],
                  ),
                  const Gap(8),
                  const Text('✨', style: TextStyle(fontSize: 48)),
                  const Gap(12),
                  Text(
                    'Relatório Premium',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Gap(8),
                  Text(
                    'Veja exatamente quanto você vai economizar',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const Gap(8),
                Text(
                  'O que você recebe:',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Gap(16),
                ...[
                  'Projeção completa mês a mês',
                  'Comparativo detalhado dos cenários',
                  'Guia prático de amortização no app da Caixa',
                  'PDF para guardar e compartilhar',
                ].map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: AppColors.greenLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check,
                                color: AppColors.green, size: 16),
                          ),
                          const Gap(12),
                          Expanded(
                            child: Text(
                              item,
                              style: GoogleFonts.inter(
                                  fontSize: 15,
                                  color: AppColors.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    )),
                const Gap(24),

                // Depoimento social
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.navyLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.navy.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ...List.generate(
                            5,
                            (_) => const Icon(Icons.star,
                                color: Color(0xFFF59E0B), size: 16),
                          ),
                        ],
                      ),
                      const Gap(8),
                      Text(
                        '"Economizei R\$ 38.400 em juros com este relatório."',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Gap(8),
                      Text(
                        '— Carlos M., São Paulo/SP',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(32),

                // Preço em destaque
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Pagamento único',
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textSecondary),
                      ),
                      const Gap(4),
                      Text(
                        'R\$ 19,90',
                        style: GoogleFonts.inter(
                          fontSize: 42,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                      Text(
                        'Sem assinatura — pague uma vez só',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const Gap(24),

                AppButton(
                  label: 'Gerar meu relatório — R\$ 19,90',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            const _CheckoutWebView(url: _checkoutUrl),
                      ),
                    );
                  },
                ),
                const Gap(12),
                Center(
                  child: Text(
                    '🔒 Pagamento seguro via Pix ou cartão de crédito',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Gap(32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutWebView extends StatefulWidget {
  const _CheckoutWebView({required this.url});

  final String url;

  @override
  State<_CheckoutWebView> createState() => _CheckoutWebViewState();
}

class _CheckoutWebViewState extends State<_CheckoutWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => setState(() => _isLoading = false),
          onPageStarted: (_) => setState(() => _isLoading = true),
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagamento seguro'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.navy),
            ),
        ],
      ),
    );
  }
}

