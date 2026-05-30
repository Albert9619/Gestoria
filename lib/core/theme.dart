import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════
// COLORES
// ═══════════════════════════════════════════════════════════
class AppColors {
  // ── Marca ───────────────────────────────────────────────
  /// Azul marino del logo (hexágono y texto "Gestoría")
  static const Color primary = Color(0xFF1A3577);
  static const Color primaryLight = Color(0xFF2D5ABF);

  /// Verde del logo (barras y flecha)
  static const Color accent = Color(0xFF4DB848);

  // ── Semánticos ──────────────────────────────────────────
  static const Color success = Color(0xFF4DB848);
  static const Color error = Color(0xFFDC2626);
  static const Color warning = Color(0xFFF59E0B);

  /// Ámbar — mesas ocupadas, servicios, tiempo transcurrido
  static const Color amber = Color(0xFFD97706);
  static const Color amberLight = Color(0xFFFEF3C7);

  // ── Superficie y fondo ──────────────────────────────────
  static const Color background = Color(0xFFF1F5F9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE2E8F0);
  static const Color cardBorder = Color(0xFFE2E8F0);

  // ── Texto ───────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textOnPrimary = Colors.white;
}

// ═══════════════════════════════════════════════════════════
// ESCALA DE ESPACIADO  (base 4 px)
// ═══════════════════════════════════════════════════════════
class AppSpacing {
  /// 4 px — separaciones mínimas, badges
  static const double xxs = 4;

  /// 8 px — gap interno de chips y elementos compactos
  static const double xs = 8;

  /// 12 px — padding interno de tarjetas pequeñas
  static const double sm = 12;

  /// 16 px — padding estándar de pantallas y tarjetas
  static const double md = 16;

  /// 20 px — separación entre secciones cortas
  static const double lg = 20;

  /// 24 px — separación entre secciones
  static const double xl = 24;

  /// 32 px — separaciones grandes entre bloques
  static const double xxl = 32;

  /// 48 px — espacio de respiración en pantallas vacías
  static const double xxxl = 48;

  // ── Semánticos ──────────────────────────────────────────
  /// 14 px — gap estándar entre campos de formulario
  static const double formGap = 14;

  /// 16 px — padding horizontal/vertical de pantallas
  static const double screenPadding = 16;

  /// 16 px — padding interno estándar de tarjetas
  static const double cardPadding = 16;
}

// ═══════════════════════════════════════════════════════════
// RADIO DE BORDES
// ═══════════════════════════════════════════════════════════
class AppRadius {
  /// 8 px — chips, badges, botones secundarios
  static const double sm = 8;

  /// 10 px — campos de texto, botones principales
  static const double md = 10;

  /// 12 px — tarjetas
  static const double lg = 12;

  /// 16 px — bottom sheets pequeños, contenedores
  static const double xl = 16;

  /// 20 px — bottom sheets principales, modales
  static const double xxl = 20;

  /// 999 px — completamente redondeado (pills, avatares)
  static const double full = 999;
}

// ═══════════════════════════════════════════════════════════
// ESCALA TIPOGRÁFICA
// ═══════════════════════════════════════════════════════════
class AppTextStyles {
  // ── Etiquetas ───────────────────────────────────────────
  /// 11 px — metadatos, timestamps, estados secundarios
  static const TextStyle labelXs = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  /// 12 px — subtítulos de tarjeta, chips, nav labels
  static const TextStyle labelSm = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  /// 13 px — texto de soporte, descripciones cortas
  static const TextStyle labelMd = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  // ── Cuerpo ──────────────────────────────────────────────
  /// 13 px — texto de apoyo en listas
  static const TextStyle bodyXs = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  /// 14 px — texto principal de listas y tarjetas
  static const TextStyle bodySm = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  /// 15 px — párrafos y descripciones
  static const TextStyle bodyMd = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  /// 16 px — texto destacado en listas
  static const TextStyle bodyLg = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  // ── Títulos ─────────────────────────────────────────────
  /// 14 px semibold — título de ítem en lista
  static const TextStyle titleXs = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// 16 px semibold — título de tarjeta
  static const TextStyle titleSm = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// 18 px semibold — título de sección
  static const TextStyle titleMd = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  /// 20 px bold — título de bottom sheet / pantalla
  static const TextStyle titleLg = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  // ── KPI / Cifras ─────────────────────────────────────────
  /// 16 px extrabold — cifras pequeñas (totales de tarjeta)
  static const TextStyle kpiSm = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );

  /// 20 px extrabold — cifras de resumen
  static const TextStyle kpiMd = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );

  /// 28 px extrabold — cifras de caja / total a cobrar
  static const TextStyle kpiLg = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );

  // ── Display ──────────────────────────────────────────────
  /// 36 px extrabold — splash / pantallas de marca
  static const TextStyle display = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );
}

// ═══════════════════════════════════════════════════════════
// TEMA GLOBAL
// ═══════════════════════════════════════════════════════════
class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        backgroundColor: AppColors.surface,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: AppTextStyles.labelSm
            .copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: AppTextStyles.labelSm,
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shadowColor: const Color(0x1A1A3577),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        color: AppColors.surface,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.formGap,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: AppTextStyles.labelMd,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          elevation: 0,
          textStyle: AppTextStyles.titleSm,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        space: 1,
      ),
    );
  }
}
