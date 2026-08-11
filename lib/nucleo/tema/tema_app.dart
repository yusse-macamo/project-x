import 'package:flutter/material.dart';
import 'package:project_x/nucleo/tema/cores_app.dart';

abstract final class TemaApp {
  static const double raio = 12;
  static const double raioPequeno = 8;

  static ThemeData get claro => _construir(Brightness.light);
  static ThemeData get escuro => _construir(Brightness.dark);

  static ThemeData _construir(Brightness brilho) {
    final bool ehClaro = brilho == Brightness.light;

    final ColorScheme esquemaCores = ColorScheme(
      brightness: brilho,
      primary: CoresApp.ambar,
      onPrimary: CoresApp.textoClaro,
      primaryContainer: ehClaro ? CoresApp.ambarClaro : CoresApp.ambarEscuro,
      onPrimaryContainer: ehClaro ? CoresApp.textoClaro : CoresApp.ambarClaro,
      secondary: ehClaro ? CoresApp.ambarEscuro : CoresApp.ambarClaro,
      onSecondary: ehClaro ? CoresApp.superficieClaro : CoresApp.textoClaro,
      secondaryContainer: ehClaro ? CoresApp.ambarClaro : CoresApp.ambarEscuro,
      onSecondaryContainer: ehClaro ? CoresApp.textoClaro : CoresApp.ambarClaro,
      error: CoresApp.erro,
      onError: CoresApp.superficieClaro,
      errorContainer: CoresApp.erroClaro,
      onErrorContainer: CoresApp.erro,
      surface: ehClaro ? CoresApp.superficieClaro : CoresApp.superficieEscuro,
      onSurface: ehClaro ? CoresApp.textoClaro : CoresApp.textoEscuro,
      surfaceContainerHighest: ehClaro
          ? CoresApp.superficieAlternativaClaro
          : CoresApp.superficieAlternativaEscuro,
      onSurfaceVariant: ehClaro
          ? CoresApp.textoSecundarioClaro
          : CoresApp.textoSecundarioEscuro,
      outline: ehClaro ? CoresApp.bordaClaro : CoresApp.bordaEscuro,
      outlineVariant: ehClaro ? CoresApp.bordaClaro : CoresApp.bordaEscuro,
    );

    final BorderRadius raioCampo = BorderRadius.circular(raioPequeno);

    return ThemeData(
      useMaterial3: true,
      brightness: brilho,
      colorScheme: esquemaCores,
      scaffoldBackgroundColor: esquemaCores.surface,
      appBarTheme: AppBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: esquemaCores.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: raioCampo,
          borderSide: BorderSide(color: esquemaCores.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: raioCampo,
          borderSide: BorderSide(color: esquemaCores.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: raioCampo,
          borderSide: const BorderSide(color: CoresApp.ambar, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: raioCampo,
          borderSide: const BorderSide(color: CoresApp.erro),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: raioCampo,
          borderSide: const BorderSide(color: CoresApp.erro, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: CoresApp.ambar,
          foregroundColor: CoresApp.textoClaro,
          shape: RoundedRectangleBorder(borderRadius: raioCampo),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          foregroundColor: esquemaCores.primary,
          side: BorderSide(color: esquemaCores.outline),
          shape: RoundedRectangleBorder(borderRadius: raioCampo),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(raio),
          side: BorderSide(color: esquemaCores.outline),
        ),
      ),
    );
  }
}
