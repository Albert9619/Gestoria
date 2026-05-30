import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';

// ═══════════════════════════════════════════════════════════
// FORMATO DE MONEDA (COP)
// ═══════════════════════════════════════════════════════════
final _fmt = NumberFormat.currency(
    locale: 'es_CO', symbol: '\$', decimalDigits: 0);
String formatCOP(double value) => _fmt.format(value);

// ═══════════════════════════════════════════════════════════
// ESTADO CHIP — label con color semántico
// ═══════════════════════════════════════════════════════════
class EstadoChip extends StatelessWidget {
  final String label;
  final Color color;
  final double? fontSize;

  const EstadoChip({
    super.key,
    required this.label,
    required this.color,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSm.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: fontSize,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// SECCIÓN HEADER — separador con título en mayúsculas
// ═══════════════════════════════════════════════════════════
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          0, AppSpacing.md, 0, AppSpacing.xs),
      child: Row(
        children: [
          Text(
            title,
            style: AppTextStyles.labelMd.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// EMPTY STATE — pantalla vacía con icono y mensaje
// ═══════════════════════════════════════════════════════════
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? subMessage;

  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.subMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.divider,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 36,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: AppTextStyles.titleSm
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (subMessage != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                subMessage!,
                style: AppTextStyles.bodyXs
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// APP TEXT FIELD — campo de formulario estándar
// ═══════════════════════════════════════════════════════════
class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int maxLines;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      style: AppTextStyles.bodySm,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// KPI CARD — tarjeta de cifra principal con etiqueta
// ═══════════════════════════════════════════════════════════
class KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData? icon;

  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: color),
                const SizedBox(width: AppSpacing.xxs),
              ],
              Text(label,
                  style: AppTextStyles.labelSm.copyWith(color: color)),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            value,
            style: AppTextStyles.kpiSm.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// INFO ROW — fila etiqueta : valor
// ═══════════════════════════════════════════════════════════
class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs + 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySm.copyWith(
              color: AppColors.textSecondary)),
          Text(
            value,
            style: AppTextStyles.titleXs.copyWith(
                color: valueColor ?? AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// HANDLE DE BOTTOM SHEET — barra decorativa superior
// ═══════════════════════════════════════════════════════════
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.divider,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// LOADING OVERLAY
// ═══════════════════════════════════════════════════════════
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.black26,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// GRADIENT FAB — botón flotante con gradiente de marca
// ═══════════════════════════════════════════════════════════
class GradientFAB extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;

  const GradientFAB({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A3577), Color(0xFF2D5ABF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.45),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.sm + 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  label,
                  style: AppTextStyles.titleXs
                      .copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// ACCENT CARD — tarjeta con barra de color a la izquierda
// ═══════════════════════════════════════════════════════════
class AccentCard extends StatelessWidget {
  final Widget child;
  final Color accentColor;
  final VoidCallback? onTap;

  const AccentCard({
    super.key,
    required this.child,
    this.accentColor = AppColors.primary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Barra de color izquierda
              Container(width: 4, color: accentColor),
              // Contenido
              Expanded(
                child: onTap != null
                    ? InkWell(
                        onTap: onTap,
                        child: child,
                      )
                    : child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// FLOATING NAV BAR — wrapper flotante para BottomNavigationBar
// ═══════════════════════════════════════════════════════════
class FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavigationBarItem> items;

  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: onTap,
            items: items,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textSecondary,
            backgroundColor: AppColors.surface,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            selectedLabelStyle: AppTextStyles.labelSm
                .copyWith(fontWeight: FontWeight.w700),
            unselectedLabelStyle: AppTextStyles.labelSm,
          ),
        ),
      ),
    );
  }
}
