import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class AccessibilityDisplayPreferences {
  final double textScale;
  final bool highContrast;

  const AccessibilityDisplayPreferences({
    this.textScale = 1.0,
    this.highContrast = false,
  });

  AccessibilityDisplayPreferences copyWith({double? textScale, bool? highContrast}) =>
      AccessibilityDisplayPreferences(
        textScale: textScale ?? this.textScale,
        highContrast: highContrast ?? this.highContrast,
      );
}

/// Device-local display preferences. These settings do not leave the device.
class AccessibilitySettings {
  static const _textScaleKey = 'inklu_accessibility_text_scale';
  static const _highContrastKey = 'inklu_accessibility_high_contrast';

  static final ValueNotifier<AccessibilityDisplayPreferences> preferences =
      ValueNotifier(const AccessibilityDisplayPreferences());

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final scale = (prefs.getDouble(_textScaleKey) ?? 1.0).clamp(0.9, 1.5).toDouble();
    preferences.value = AccessibilityDisplayPreferences(
      textScale: scale,
      highContrast: prefs.getBool(_highContrastKey) ?? false,
    );
  }

  static Future<void> setTextScale(double value) async {
    final scale = value.clamp(0.9, 1.5).toDouble();
    preferences.value = preferences.value.copyWith(textScale: scale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_textScaleKey, scale);
  }

  static Future<void> setHighContrast(bool value) async {
    preferences.value = preferences.value.copyWith(highContrast: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_highContrastKey, value);
  }

  static Future<void> resetDisplayPreferences() async {
    preferences.value = const AccessibilityDisplayPreferences();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_textScaleKey);
    await prefs.remove(_highContrastKey);
  }
}
