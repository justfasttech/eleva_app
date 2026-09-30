import 'package:flutter/material.dart';

import '../../../core/theme.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Política de Privacidade')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Image.asset('assets/images/logo.png', height: 56),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Política de Privacidade',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: ElevaColors.textDark,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Center(
                child: Text(
                  'Última atualização: 30 de setembro de 2026',
                  style: TextStyle(fontSize: 13, color: ElevaColors.textMuted),
                ),
              ),
              const SizedBox(height: 24),
              _text(
                'O Eleva ("nós", "nosso" ou "aplicativo") é um aplicativo de fé e espiritualidade '
                'desenvolvido por JustFast Technology. Esta Política de Privacidade descreve como '
                'coletamos, usamos e protegemos suas informações pessoais quando você utiliza nosso '
                'aplicativo, disponível para Android, iOS e Web.',
              ),
              const SizedBox(height: 12),
              _highlightBox(
                'Respeitamos sua privacidade. Seus dados são utilizados exclusivamente para o '
                'funcionamento do aplicativo e nunca são vendidos a terceiros.',
              ),
              _section('1. Informações que coletamos'),
              _subtitle('Dados fornecidos por você'),
              _bullet('Dados de cadastro: nome, endereço de e-mail e senha'),
              _bullet(
                'Perfil espiritual: preferências de fé, nível espiritual e respostas ao questionário inicial',
              ),
              _bullet(
                'Diário pessoal: anotações e reflexões que você registra no aplicativo',
              ),
              _bullet('Foto de perfil: caso opte por adicionar uma'),
              _subtitle('Dados coletados automaticamente'),
              _bullet(
                'Dados de uso: recursos acessados, tempo de utilização e interações com o conteúdo',
              ),
              _bullet(
                'Dados do dispositivo: modelo, sistema operacional e versão do aplicativo',
              ),
              _bullet(
                'Dados de assinatura: status e período do plano (mensal ou anual)',
              ),
              _section('2. Como utilizamos seus dados'),
              _bullet('Fornecer, manter e melhorar os serviços do aplicativo'),
              _bullet(
                'Personalizar sua experiência espiritual com conteúdos relevantes ao seu nível de fé',
              ),
              _bullet('Gerenciar sua conta e assinatura'),
              _bullet(
                'Enviar notificações sobre novos conteúdos, desafios e lembretes (com seu consentimento)',
              ),
              _bullet('Garantir a segurança e prevenir fraudes'),
              _bullet('Cumprir obrigações legais'),
              _section('3. Serviços de terceiros'),
              _text(
                'Utilizamos os seguintes serviços para o funcionamento do aplicativo:',
              ),
              const SizedBox(height: 8),
              _bullet(
                'Supabase: autenticação, armazenamento de dados e hospedagem do backend',
              ),
              _bullet(
                'RevenueCat: gerenciamento de assinaturas e compras no aplicativo',
              ),
              _bullet(
                'Google Play / App Store: processamento de pagamentos das assinaturas',
              ),
              _bullet('Stripe: processamento de pagamentos na versão web'),
              _bullet(
                'Google Gemini: geração de conteúdo espiritual (processamento no servidor, sem envio de dados pessoais)',
              ),
              const SizedBox(height: 8),
              _text(
                'Cada serviço possui sua própria política de privacidade. Recomendamos que você as consulte '
                'para entender como tratam seus dados.',
              ),
              _section('4. Armazenamento e segurança'),
              _text(
                'Seus dados são armazenados de forma segura em servidores da Supabase, com criptografia em '
                'trânsito (TLS) e em repouso. Adotamos medidas técnicas e organizacionais para proteger suas '
                'informações contra acesso não autorizado, perda ou destruição.',
              ),
              _section('5. Compartilhamento de dados'),
              _text(
                'Não vendemos, alugamos ou compartilhamos suas informações pessoais com terceiros para fins '
                'de marketing. Seus dados podem ser compartilhados apenas:',
              ),
              const SizedBox(height: 8),
              _bullet(
                'Com prestadores de serviço essenciais ao funcionamento do aplicativo (listados na seção 3)',
              ),
              _bullet('Quando exigido por lei ou ordem judicial'),
              _bullet(
                'Para proteger nossos direitos legais ou a segurança dos usuários',
              ),
              _section('6. Seus direitos'),
              _text(
                'Em conformidade com a Lei Geral de Proteção de Dados (LGPD), você tem direito a:',
              ),
              const SizedBox(height: 8),
              _bullet('Acessar seus dados pessoais'),
              _bullet('Corrigir dados incompletos ou desatualizados'),
              _bullet('Solicitar a exclusão de seus dados'),
              _bullet('Revogar o consentimento a qualquer momento'),
              _bullet('Solicitar a portabilidade dos seus dados'),
              _bullet(
                'Obter informações sobre com quem seus dados foram compartilhados',
              ),
              const SizedBox(height: 8),
              _text(
                'Para exercer qualquer desses direitos, entre em contato conosco pelo e-mail abaixo.',
              ),
              _section('7. Retenção de dados'),
              _text(
                'Seus dados pessoais são mantidos enquanto sua conta estiver ativa. Ao solicitar a exclusão da '
                'conta, seus dados serão removidos em até 30 dias, exceto quando a retenção for necessária '
                'para cumprimento de obrigações legais.',
              ),
              _section('8. Menores de idade'),
              _text(
                'O Eleva não é destinado a menores de 13 anos. Não coletamos intencionalmente dados de '
                'crianças. Se tomarmos conhecimento de que dados de um menor de 13 anos foram coletados, '
                'estes serão excluídos imediatamente.',
              ),
              _section('9. Alterações nesta política'),
              _text(
                'Podemos atualizar esta Política de Privacidade periodicamente. Notificaremos você sobre '
                'alterações significativas por meio do aplicativo ou por e-mail. A data da última atualização '
                'será sempre indicada no topo desta página.',
              ),
              _section('10. Contato'),
              _text(
                'Se você tiver dúvidas ou solicitações sobre esta Política de Privacidade ou sobre o '
                'tratamento de seus dados pessoais, entre em contato:',
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: ElevaColors.offWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: ElevaColors.goldLight.withValues(alpha: 0.5),
                  ),
                ),
                child: const Column(
                  children: [
                    Text(
                      'contato@justfast.tech',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ElevaColors.gold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'JustFast Technology',
                      style: TextStyle(
                        fontSize: 13,
                        color: ElevaColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Center(
                child: Text(
                  '© 2026 JustFast Technology. Todos os direitos reservados.',
                  style: TextStyle(fontSize: 12, color: ElevaColors.textMuted),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: ElevaColors.textDark,
        ),
      ),
    );
  }

  static Widget _subtitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: ElevaColors.textDark,
        ),
      ),
    );
  }

  static Widget _text(String content) {
    return Text(
      content,
      style: const TextStyle(
        fontSize: 14,
        color: ElevaColors.textDark,
        height: 1.6,
      ),
    );
  }

  static Widget _bullet(String content) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 7),
            child: Icon(Icons.circle, size: 6, color: ElevaColors.gold),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              content,
              style: const TextStyle(
                fontSize: 14,
                color: ElevaColors.textDark,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _highlightBox(String content) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ElevaColors.goldLight.withValues(alpha: 0.15),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        border: const Border(
          left: BorderSide(color: ElevaColors.gold, width: 3),
        ),
      ),
      child: Text(
        content,
        style: const TextStyle(
          fontSize: 14,
          color: ElevaColors.textDark,
          height: 1.5,
        ),
      ),
    );
  }
}
