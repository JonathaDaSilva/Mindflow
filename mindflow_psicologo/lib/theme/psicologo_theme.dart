import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tema light clínico exclusivo do app do psicólogo.
/// O app do paciente continua usando AppTheme.dark do mindflow_shared.
class PT {
  PT._();

  // ── Paleta ───────────────────────────────────────────────────────────────
  static const Color primary      = Color(0xFF3B4FCC); // azul profundo
  static const Color primaryDark  = Color(0xFF2D3E9E);
  static const Color primaryLight = Color(0xFFEEF0FD); // tint leve
  static const Color accent       = Color(0xFF0EA5E9); // azul vivo
  static const Color background   = Color(0xFFF8FAFC); // quase branco
  static const Color surface      = Color(0xFFFFFFFF); // card branco
  static const Color surfaceAlt   = Color(0xFFF1F5F9); // input / alt
  static const Color border       = Color(0xFFE2E8F0); // borda sutil
  static const Color borderFocus  = Color(0xFF3B4FCC);
  static const Color text1        = Color(0xFF0F172A); // quase preto
  static const Color text2        = Color(0xFF64748B); // slate médio
  static const Color text3        = Color(0xFF94A3B8); // slate claro
  static const Color error        = Color(0xFFEF4444);
  static const Color errorLight   = Color(0xFFFEE2E2);
  static const Color success      = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning      = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color purple       = Color(0xFF8B5CF6);
  static const Color purpleLight  = Color(0xFFEDE9FE);

  // ── Status badges ────────────────────────────────────────────────────────
  static Color statusBg(String? s) {
    switch (s) {
      case 'SOLICITADA':    return warningLight;
      case 'CONFIRMADA':    return successLight;
      case 'RECUSADA':
      case 'CANCELADA':     return errorLight;
      case 'EM_ANDAMENTO':  return primaryLight;
      case 'CONCLUIDA':     return purpleLight;
      default:              return surfaceAlt;
    }
  }

  static Color statusFg(String? s) {
    switch (s) {
      case 'SOLICITADA':    return const Color(0xFFD97706);
      case 'CONFIRMADA':    return const Color(0xFF065F46);
      case 'RECUSADA':
      case 'CANCELADA':     return const Color(0xFF991B1B);
      case 'EM_ANDAMENTO':  return primaryDark;
      case 'CONCLUIDA':     return const Color(0xFF5B21B6);
      default:              return text2;
    }
  }

  static String statusLabel(String? s) {
    switch (s) {
      case 'SOLICITADA':    return 'Solicitada';
      case 'CONFIRMADA':    return 'Confirmada';
      case 'RECUSADA':      return 'Recusada';
      case 'CANCELADA':     return 'Cancelada';
      case 'EM_ANDAMENTO':  return 'Em andamento';
      case 'CONCLUIDA':     return 'Concluída';
      default:              return s ?? '';
    }
  }

  // ── Decorações reutilizáveis ──────────────────────────────────────────────
  static BoxDecoration get card => BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: border, width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static BoxDecoration cardWith({Color? accent, double radius = 16}) =>
      BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: accent != null ? accent.withOpacity(0.25) : border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );

  // ── Widgets ───────────────────────────────────────────────────────────────

  /// Chip de status padronizado
  static Widget statusChip(String? s) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: statusBg(s),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      statusLabel(s),
      style: TextStyle(
        color: statusFg(s),
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  /// Linha de informação (ícone + label + valor)
  static Widget infoRow(IconData icon, String label, String value) => Row(
    children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: primaryLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: primary, size: 18),
      ),
      const SizedBox(width: 12),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: text2, fontSize: 11)),
          const SizedBox(height: 1),
          Text(value, style: const TextStyle(color: text1, fontWeight: FontWeight.w500, fontSize: 14)),
        ],
      ),
    ],
  );

  // ── ThemeData ─────────────────────────────────────────────────────────────
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: background,
    fontFamily: 'Inter',
    colorScheme: const ColorScheme.light(
      primary: primary,
      secondary: accent,
      surface: surface,
      error: error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: text1,
      onError: Colors.white,
    ),
    textTheme: const TextTheme(
      displayLarge:   TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: text1, letterSpacing: -0.5),
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: text1, letterSpacing: -0.3),
      titleLarge:     TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: text1),
      titleMedium:    TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: text1),
      bodyLarge:      TextStyle(fontSize: 16, color: text1),
      bodyMedium:     TextStyle(fontSize: 14, color: text2),
      bodySmall:      TextStyle(fontSize: 12, color: text3),
      labelLarge:     TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: surface,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: Color(0x14000000),
      centerTitle: false,
      iconTheme: IconThemeData(color: text1),
      titleTextStyle: TextStyle(
        color: text1,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        fontFamily: 'Inter',
      ),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceAlt,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: error, width: 1.5),
      ),
      hintStyle: const TextStyle(color: text3, fontSize: 14),
      labelStyle: const TextStyle(color: text2, fontSize: 14),
      floatingLabelStyle: const TextStyle(color: primary, fontSize: 12, fontWeight: FontWeight.w500),
      prefixIconColor: text2,
      suffixIconColor: text2,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: primary, width: 1.5),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withOpacity(0.06),
      elevation: 8,
      indicatorColor: primaryLight,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(color: primary, fontWeight: FontWeight.w600, fontSize: 11, fontFamily: 'Inter');
        }
        return const TextStyle(color: text2, fontSize: 11, fontFamily: 'Inter');
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: primary, size: 22);
        }
        return const IconThemeData(color: text2, size: 22);
      }),
      height: 68,
    ),
    tabBarTheme: const TabBarThemeData(
      indicatorColor: primary,
      labelColor: primary,
      unselectedLabelColor: text2,
      dividerColor: border,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, fontFamily: 'Inter'),
      unselectedLabelStyle: TextStyle(fontSize: 14, fontFamily: 'Inter'),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: const TextStyle(color: text1, fontSize: 18, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
      contentTextStyle: const TextStyle(color: text2, fontSize: 14, fontFamily: 'Inter'),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: text1,
      contentTextStyle: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
    dividerTheme: const DividerThemeData(color: border, thickness: 1),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? Colors.white : text3),
      trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? primary : surfaceAlt),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? primary : Colors.transparent),
      side: const BorderSide(color: border, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    dropdownMenuTheme: const DropdownMenuThemeData(
      textStyle: TextStyle(color: text1, fontFamily: 'Inter'),
    ),
  );
}
