import 'package:flutter/material.dart';
import 'package:project_x/nucleo/tema/cores_app.dart';

abstract final class TemaApp {
  static const double raio = 16;
  static const double raioPequeno = 12;

  static ThemeData get claro => _construir(Brightness.light);
  static ThemeData get escuro => _construir(Brightness.dark);

  static ThemeData _construir(Brightness brilho) {
    final bool ehClaro = brilho == Brightness.light;

    final ColorScheme esquemaCores = ColorScheme(
      brightness: brilho,
      primary: CoresApp.primaria,
      onPrimary: CoresApp.onPrimaria,
      primaryContainer: ehClaro
          ? CoresApp.primariaClara
          : CoresApp.primariaEscura,
      onPrimaryContainer: ehClaro
          ? CoresApp.primariaEscura
          : CoresApp.primariaClara,
      secondary: CoresApp.destaque,
      onSecondary: CoresApp.onDestaque,
      secondaryContainer: ehClaro
          ? CoresApp.destaqueClara
          : CoresApp.destaqueEscura,
      onSecondaryContainer: ehClaro
          ? CoresApp.destaqueEscura
          : CoresApp.destaqueClara,
      tertiary: CoresApp.amarelo,
      onTertiary: CoresApp.marinho,
      error: CoresApp.erro,
      onError: CoresApp.superficieClaro,
      errorContainer: CoresApp.erroClaro,
      onErrorContainer: CoresApp.erro,
      surface: ehClaro ? CoresApp.fundoClaro : CoresApp.fundoEscuro,
      onSurface: ehClaro ? CoresApp.textoClaro : CoresApp.textoEscuro,
      surfaceContainerLowest: ehClaro
          ? CoresApp.superficieClaro
          : CoresApp.superficieEscuro,
      surfaceContainerHighest: ehClaro
          ? CoresApp.superficieAlternativaClaro
          : CoresApp.superficieAlternativaEscuro,
      onSurfaceVariant: ehClaro
          ? CoresApp.textoSecundarioClaro
          : CoresApp.textoSecundarioEscuro,
      outline: ehClaro ? CoresApp.bordaClaro : CoresApp.bordaEscuro,
      outlineVariant: ehClaro ? CoresApp.bordaClaro : CoresApp.bordaEscuro,
      inverseSurface: ehClaro ? CoresApp.marinho : CoresApp.creme,
      onInverseSurface: ehClaro ? CoresApp.creme : CoresApp.marinho,
    );

    final BorderRadius raioCampo = BorderRadius.circular(raioPequeno);
    final TextTheme textos = ThemeData(brightness: brilho).textTheme;
    const TextStyle pesado = TextStyle(
      fontWeight: FontWeight.w900,
      letterSpacing: 0.8,
      height: 1.1,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brilho,
      colorScheme: esquemaCores,
      scaffoldBackgroundColor: esquemaCores.surface,
      textTheme: textos.copyWith(
        displaySmall: textos.displaySmall?.merge(pesado),
        headlineLarge: textos.headlineLarge?.merge(pesado),
        headlineMedium: textos.headlineMedium?.merge(pesado),
        headlineSmall: textos.headlineSmall?.merge(pesado),
      ),
      appBarTheme: AppBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: esquemaCores.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: raioCampo,
          borderSide: BorderSide(color: esquemaCores.outline, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: raioCampo,
          borderSide: BorderSide(color: esquemaCores.outline, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: raioCampo,
          borderSide: BorderSide(color: esquemaCores.onSurface, width: 2),
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
          minimumSize: const Size.fromHeight(56),
          backgroundColor: CoresApp.primaria,
          foregroundColor: CoresApp.onPrimaria,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 1.2,
          ),
          shape: RoundedRectangleBorder(borderRadius: raioCampo),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          foregroundColor: esquemaCores.onSurface,
          side: BorderSide(color: esquemaCores.outline, width: 1.5),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          shape: RoundedRectangleBorder(borderRadius: raioCampo),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: esquemaCores.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(raio),
          side: BorderSide(color: esquemaCores.outline),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: esquemaCores.surface,
        indicatorColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith(
          (Set<WidgetState> estados) => IconThemeData(
            color: estados.contains(WidgetState.selected)
                ? CoresApp.primaria
                : esquemaCores.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (Set<WidgetState> estados) => TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: estados.contains(WidgetState.selected)
                ? CoresApp.primaria
                : esquemaCores.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
