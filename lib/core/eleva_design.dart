import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tokens do novo visual (azul + dourado).
///
/// Ficam separados do [elevaTheme] para que as telas migrem uma a uma
/// sem alterar as que ainda usam o tema dourado.
abstract class EDColors {
  // Base azul
  static const Color navy = Color(0xFF0E3A73);
  static const Color navySoft = Color(0xFF133A6E);
  static const Color navyLine = Color(0xFF1B4F93);
  static const Color blue = Color(0xFF1565C0);
  static const Color blueDark = Color(0xFF0D47A1);
  static const Color blueSoft = Color(0xFFE3EFFC);
  static const Color sky = Color(0xFF8EC5FC);

  // Superfícies e texto
  static const Color surface = Color(0xFFF4F8FD);
  static const Color card = Colors.white;
  static const Color border = Color(0xFFE1EAF5);
  static const Color divider = Color(0xFFE8EFF8);
  static const Color ink = Color(0xFF0F1B2D);
  static const Color inkMuted = Color(0xFF5A6B80);
  static const Color hint = Color(0xFF7D8CA0);
  static const Color onNavyMuted = Color(0xFFC3D6EF);

  // Dourado (acento da marca: fé, progresso, conquistas)
  static const Color gold = Color(0xFFE8B84B);
  static const Color goldInk = Color(0xFF855B0C); // texto dourado sobre fundo claro
  static const Color goldSoft = Color(0xFFFBF1DA);

  static const Color danger = Color(0xFFB42318);
}

abstract class EDText {
  static TextStyle display({
    double size = 28,
    FontWeight weight = FontWeight.w600,
    Color color = EDColors.ink,
    double? height,
  }) =>
      GoogleFonts.fraunces(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
      );

  static TextStyle body({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color color = EDColors.ink,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.manrope(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  static TextStyle eyebrow({Color color = EDColors.goldInk}) => body(
        size: 11,
        weight: FontWeight.w700,
        color: color,
        letterSpacing: 1.5,
      );
}

abstract class EDDecor {
  static InputDecoration input({
    String? hint,
    Widget? suffixIcon,
  }) {
    OutlineInputBorder border(Color color, [double width = 1.5]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color, width: width),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: EDText.body(size: 15, color: EDColors.hint),
      filled: true,
      fillColor: EDColors.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      suffixIcon: suffixIcon,
      enabledBorder: border(EDColors.border),
      focusedBorder: border(EDColors.blue, 2),
      errorBorder: border(EDColors.danger),
      focusedErrorBorder: border(EDColors.danger, 2),
      errorStyle: EDText.body(size: 12, color: EDColors.danger),
    );
  }

  static ButtonStyle primaryButton() => ElevatedButton.styleFrom(
        backgroundColor: EDColors.blue,
        foregroundColor: Colors.white,
        disabledBackgroundColor: EDColors.blue.withValues(alpha: 0.6),
        disabledForegroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 54),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: EDText.body(size: 16, weight: FontWeight.w800),
      );

  static ButtonStyle secondaryButton({Color color = EDColors.blue}) =>
      OutlinedButton.styleFrom(
        foregroundColor: color,
        minimumSize: const Size(double.infinity, 54),
        side: BorderSide(color: color.withValues(alpha: 0.35), width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: EDText.body(size: 15, weight: FontWeight.w800),
      );

  static ButtonStyle dangerButton() => ElevatedButton.styleFrom(
        backgroundColor: EDColors.danger,
        foregroundColor: Colors.white,
        disabledBackgroundColor: EDColors.danger.withValues(alpha: 0.6),
        disabledForegroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 54),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: EDText.body(size: 16, weight: FontWeight.w800),
      );

  /// AppBar clara com botão de voltar redondo e título centralizado.
  static AppBar appBar(BuildContext context, String title, {List<Widget>? actions}) =>
      AppBar(
        backgroundColor: EDColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leadingWidth: 68,
        leading: Navigator.of(context).canPop()
            ? const Padding(
                padding: EdgeInsets.only(left: 16),
                child: Center(child: EDBackButton()),
              )
            : null,
        title: Text(title, style: EDText.body(size: 16, weight: FontWeight.w800)),
        actions: actions,
      );

  static BoxDecoration card({Color color = EDColors.card, double radius = 20}) =>
      BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: EDColors.border),
      );
}

/// Os 7 estágios da Árvore da Fé.
class FaithStage {
  final int number;
  final String name;
  final String description;
  final Color color;

  const FaithStage(this.number, this.name, this.description, this.color);

  static const List<FaithStage> all = [
    FaithStage(1, 'Semente', 'A fé está nascendo no seu coração. Tudo começa aqui.', Color(0xFF3F5B2E)),
    FaithStage(2, 'Broto', 'Você começou a acreditar e a confiar nas promessas de Deus.', Color(0xFF5E6B22)),
    FaithStage(3, 'Crescimento', 'Sua fé está crescendo e se fortalecendo através da Palavra e da oração.', Color(0xFFA87A0A)),
    FaithStage(4, 'Enraizamento', 'Sua fé já tem base. Você se mantém firme mesmo nas dificuldades.', Color(0xFFB45A12)),
    FaithStage(5, 'Frutificação', 'Você começa a dar frutos e impactar outras vidas com o amor de Deus.', Color(0xFFB83A1A)),
    FaithStage(6, 'Maturidade', 'Sua fé é sólida e madura. Você anda com Deus e inspira muitos ao seu redor.', Color(0xFF5B3F6A)),
    FaithStage(7, 'Plenitude', 'Você vive o propósito de Deus em plenitude e sua fé é inspiração para gerações.', Color(0xFF2A3157)),
  ];

  /// Pontos de fé (0–70) → estágio. Cada estágio cobre 2 níveis da árvore (10 pontos).
  static FaithStage fromPoints(double points) {
    final level = (points / 5).floor().clamp(0, 14);
    final index = (level ~/ 2).clamp(0, all.length - 1);
    return all[index];
  }

  /// Pontos que faltam para o próximo estágio, ou null no último.
  static double? pointsToNext(double points) {
    final stage = fromPoints(points);
    if (stage.number == all.length) return null;
    return (stage.number * 10) - points;
  }
}

/// Botão de voltar redondo (44 px) usado nas telas internas.
class EDBackButton extends StatelessWidget {
  final Color background;
  final Color iconColor;

  const EDBackButton({
    super.key,
    this.background = EDColors.card,
    this.iconColor = EDColors.ink,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: CircleBorder(
        side: background == EDColors.card
            ? const BorderSide(color: EDColors.border)
            : BorderSide.none,
      ),
      child: SizedBox(
        width: 44,
        height: 44,
        child: IconButton(
          tooltip: 'Voltar',
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).maybePop(),
          icon: Icon(Icons.arrow_back_rounded, size: 20, color: iconColor),
        ),
      ),
    );
  }
}

/// Modal padrão do novo visual: ícone opcional, título serifado,
/// conteúdo e ações empilhadas (principal em cima).
class EDDialog extends StatelessWidget {
  final IconData? icon;
  final Color iconColor;
  final Color iconBackground;
  final Widget? leading;
  final String title;
  final String? message;
  final Widget? content;
  final List<Widget> actions;
  final bool centered;

  const EDDialog({
    super.key,
    required this.title,
    this.icon,
    this.iconColor = EDColors.blue,
    this.iconBackground = EDColors.blueSoft,
    this.leading,
    this.message,
    this.content,
    this.actions = const [],
    this.centered = true,
  });

  @override
  Widget build(BuildContext context) {
    final align = centered ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    final textAlign = centered ? TextAlign.center : TextAlign.start;
    return Dialog(
      backgroundColor: EDColors.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: align,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(height: 16),
              ] else if (icon != null) ...[
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(height: 16),
              ],
              Text(title, textAlign: textAlign, style: EDText.display(size: 22)),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(
                  message!,
                  textAlign: textAlign,
                  style: EDText.body(color: EDColors.inkMuted, height: 1.5),
                ),
              ],
              if (content != null) ...[
                const SizedBox(height: 20),
                content!,
              ],
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 24),
                for (var i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  SizedBox(width: double.infinity, child: actions[i]),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Faixa de erro usada dentro de sheets e modais.
class EDErrorBanner extends StatelessWidget {
  final String message;

  const EDErrorBanner(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 18, color: EDColors.danger),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: EDText.body(size: 13, weight: FontWeight.w600, color: EDColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}
