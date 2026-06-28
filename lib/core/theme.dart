import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Luxe color palette ──────────────────────────────────────────────────
  static const Color navy       = Color(0xFF0D1B2A);
  static const Color navyLight  = Color(0xFF1B2A3B);
  static const Color gold       = Color(0xFFC9A84C);
  static const Color goldLight  = Color(0xFFE2C97E);
  static const Color offWhite   = Color(0xFFF7F8FC);
  static const Color surface    = Color(0xFFFFFFFF);
  static const Color border     = Color(0xFFE8ECF0);

  static const Color success    = Color(0xFF0E9F6E);
  static const Color warning    = Color(0xFFF59E0B);
  static const Color danger     = Color(0xFFEF4444);
  static const Color info       = Color(0xFF3B82F6);

  // ── Cairo text theme ────────────────────────────────────────────────────
  static TextTheme _cairoText(Color base) => TextTheme(
    displayLarge  : GoogleFonts.cairo(fontSize: 57, fontWeight: FontWeight.w300, color: base),
    displayMedium : GoogleFonts.cairo(fontSize: 45, fontWeight: FontWeight.w300, color: base),
    displaySmall  : GoogleFonts.cairo(fontSize: 36, fontWeight: FontWeight.w400, color: base),
    headlineLarge : GoogleFonts.cairo(fontSize: 32, fontWeight: FontWeight.w800, color: base),
    headlineMedium: GoogleFonts.cairo(fontSize: 28, fontWeight: FontWeight.w700, color: base),
    headlineSmall : GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.w700, color: base),
    titleLarge    : GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.w700, color: base),
    titleMedium   : GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w600, color: base),
    titleSmall    : GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600, color: base),
    bodyLarge     : GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w400, color: base),
    bodyMedium    : GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w400, color: base),
    bodySmall     : GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w400, color: base),
    labelLarge    : GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w700, color: base),
    labelMedium   : GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w600, color: base),
    labelSmall    : GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w500, color: base),
  );

  // ── Light (Luxe Pearl) ───────────────────────────────────────────────────
  static ThemeData light(Color seed) {
    final cs = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light).copyWith(
      surface         : surface,
      onSurface       : const Color(0xFF0D1B2A),
      surfaceContainerHighest : const Color(0xFFF0F3F8),
    );
    return _base(cs, offWhite);
  }

  // ── Dark (Luxe Noir) ─────────────────────────────────────────────────────
  static ThemeData dark(Color seed) {
    final cs = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark).copyWith(
      surface         : const Color(0xFF111827),
      onSurface       : const Color(0xFFF1F5F9),
      surfaceContainerHighest : const Color(0xFF1F2937),
    );
    return _base(cs, const Color(0xFF0D1117));
  }

  static ThemeData _base(ColorScheme cs, Color scaffold) {
    final isLight = cs.brightness == Brightness.light;
    final textBase = cs.onSurface;

    return ThemeData(
      useMaterial3      : true,
      colorScheme       : cs,
      scaffoldBackgroundColor: scaffold,
      textTheme         : _cairoText(textBase),
      primaryTextTheme  : _cairoText(cs.onPrimary),

      // ─ AppBar ───────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        elevation              : 0,
        scrolledUnderElevation : 0,
        backgroundColor        : cs.surface,
        foregroundColor        : cs.onSurface,
        titleTextStyle         : GoogleFonts.cairo(
            fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface),
        iconTheme              : IconThemeData(color: cs.onSurface),
        actionsIconTheme       : IconThemeData(color: cs.onSurface),
        shadowColor            : Colors.transparent,
        surfaceTintColor       : Colors.transparent,
      ),

      // ─ Card ─────────────────────────────────────────────────────────────
      cardTheme: CardTheme(
        elevation   : 0,
        color       : cs.surface,
        surfaceTintColor: Colors.transparent,
        shape       : RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side        : BorderSide(
              color: isLight ? border : const Color(0xFF1F2937), width: 1),
        ),
        margin : EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      // ─ ElevatedButton ───────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor : cs.primary,
          foregroundColor : cs.onPrimary,
          elevation       : 0,
          shadowColor     : Colors.transparent,
          padding         : const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape           : RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle       : GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),

      // ─ OutlinedButton ───────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding  : const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape    : RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // ─ Input ────────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled         : true,
        fillColor      : isLight ? const Color(0xFFF8FAFC) : const Color(0xFF1A2332),
        contentPadding : const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border         : OutlineInputBorder(
          borderRadius : BorderRadius.circular(14),
          borderSide   : BorderSide(color: isLight ? border : const Color(0xFF2D3748)),
        ),
        enabledBorder  : OutlineInputBorder(
          borderRadius : BorderRadius.circular(14),
          borderSide   : BorderSide(color: isLight ? border : const Color(0xFF2D3748)),
        ),
        focusedBorder  : OutlineInputBorder(
          borderRadius : BorderRadius.circular(14),
          borderSide   : BorderSide(color: cs.primary, width: 2),
        ),
        errorBorder    : OutlineInputBorder(
          borderRadius : BorderRadius.circular(14),
          borderSide   : const BorderSide(color: danger),
        ),
        labelStyle     : GoogleFonts.cairo(fontSize: 13, color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
        hintStyle      : GoogleFonts.cairo(fontSize: 13, color: isLight ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
        floatingLabelStyle: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600, color: cs.primary),
        prefixIconColor: isLight ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        suffixIconColor: isLight ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
      ),

      // ─ DataTable ────────────────────────────────────────────────────────
      dataTableTheme: DataTableThemeData(
        headingRowColor      : WidgetStateProperty.all(
          isLight ? const Color(0xFFF0F5FF) : const Color(0xFF1A2332)),
        headingTextStyle     : GoogleFonts.cairo(
            fontSize: 13, fontWeight: FontWeight.w700,
            color: isLight ? cs.primary : cs.primary.withOpacity(.9)),
        dataTextStyle        : GoogleFonts.cairo(fontSize: 13, color: textBase),
        dividerThickness     : 0.8,
        horizontalMargin     : 20,
        columnSpacing        : 28,
        headingRowHeight     : 52,
        dataRowMinHeight     : 52,
        dataRowMaxHeight     : 64,
        decoration           : const BoxDecoration(),
      ),

      // ─ Chip ─────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        shape     : RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        labelStyle: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w600),
        padding   : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // ─ Dialog ───────────────────────────────────────────────────────────
      dialogTheme: DialogTheme(
        backgroundColor : cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation       : 0,
        shape           : RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side        : BorderSide(color: isLight ? border : const Color(0xFF2D3748)),
        ),
        titleTextStyle  : GoogleFonts.cairo(
            fontSize: 18, fontWeight: FontWeight.w800, color: textBase),
        contentTextStyle: GoogleFonts.cairo(fontSize: 14, color: textBase),
      ),

      // ─ SnackBar ─────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior         : SnackBarBehavior.floating,
        backgroundColor  : isLight ? navy : const Color(0xFF1E293B),
        contentTextStyle : GoogleFonts.cairo(fontSize: 14, color: Colors.white),
        shape            : RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation        : 0,
      ),

      // ─ Divider ──────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color    : isLight ? border : const Color(0xFF1F2937),
        thickness: 1,
        space    : 1,
      ),

      // ─ Tooltip ──────────────────────────────────────────────────────────
      tooltipTheme: TooltipThemeData(
        textStyle : GoogleFonts.cairo(fontSize: 12, color: Colors.white),
        decoration: BoxDecoration(
          color       : isLight ? navy : const Color(0xFF334155),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      // ─ Tab ──────────────────────────────────────────────────────────────
      tabBarTheme: TabBarTheme(
        labelStyle      : GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w500),
        indicatorSize   : TabBarIndicatorSize.tab,
        dividerColor    : Colors.transparent,
      ),
    );
  }

  // ── Status helpers ───────────────────────────────────────────────────────
  static Color statusColor(String s) => switch (s) {
    'paid'      => success,
    'pending'   => warning,
    'partial'   => info,
    'cancelled' => const Color(0xFF94A3B8),
    'overdue'   => danger,
    'draft'     => const Color(0xFF94A3B8),
    'approved'  => success,
    'rejected'  => danger,
    _           => const Color(0xFF94A3B8),
  };

  static String statusLabel(String s) => switch (s) {
    'paid'      => 'مدفوع',
    'pending'   => 'معلق',
    'partial'   => 'جزئي',
    'cancelled' => 'ملغي',
    'overdue'   => 'متأخر',
    'draft'     => 'مسودة',
    'approved'  => 'معتمد',
    'rejected'  => 'مرفوض',
    _           => s,
  };
}
