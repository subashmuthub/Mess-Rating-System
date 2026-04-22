import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class GoogleFontsConfig {
  bool allowRuntimeFetching = false;
}

class GoogleFonts {
  static final GoogleFontsConfig config = GoogleFontsConfig();

  static TextStyle poppins({
    TextStyle? textStyle,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    double? height,
    ui.Locale? locale,
    ui.Paint? foreground,
    ui.Paint? background,
    List<Shadow>? shadows,
    List<ui.FontFeature>? fontFeatures,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
    String? fontFamily,
    List<String>? fontFamilyFallback,
    String? package,
    TextBaseline? textBaseline,
    TextOverflow? overflow,
    bool? inherit,
    String? debugLabel,
  }) {
    return (textStyle ?? const TextStyle()).copyWith(
      fontFamily: 'Roboto',
      color: color,
      backgroundColor: backgroundColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      height: height,
      locale: locale,
      foreground: foreground,
      background: background,
      shadows: shadows,
      fontFeatures: fontFeatures,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
      fontFamilyFallback: fontFamilyFallback,
      package: package,
      textBaseline: textBaseline,
      overflow: overflow,
      inherit: inherit,
      debugLabel: debugLabel,
    );
  }

  static TextTheme poppinsTextTheme([TextTheme? textTheme]) {
    return (textTheme ?? const TextTheme()).apply(fontFamily: 'Roboto');
  }
}