import React from "react";
import { Text, TouchableOpacity, StyleSheet } from "react-native";
import { colors } from "../theme/colors";
import { font, horizontalPadding, rs } from "../theme/responsive";

const getAccessibleLabel = (title, accessibilityLabel) => {
  if (accessibilityLabel) return accessibilityLabel;
  return String(title).replace(/[\p{Extended_Pictographic}\uFE0F]/gu, "").replace(/\s+/g, " ").trim();
};

export default function AccessibleButton({ title, onPress, type = "primary", disabled = false, accessibilityLabel, accessibilityHint }) {
  return (
    <TouchableOpacity
      style={[styles.button, type === "secondary" && styles.secondary, disabled && styles.disabled]}
      onPress={onPress}
      disabled={disabled}
      activeOpacity={disabled ? 1 : 0.7}
      accessibilityRole="button"
      accessibilityLabel={getAccessibleLabel(title, accessibilityLabel)}
      accessibilityHint={accessibilityHint}
      accessibilityState={{ disabled }}
      accessible
    >
      <Text numberOfLines={1} adjustsFontSizeToFit minimumFontScale={0.82} style={styles.text}>{title}</Text>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  button: { backgroundColor: colors.primary, minHeight: rs(52, 48, 56), paddingHorizontal: horizontalPadding, borderRadius: rs(12, 10, 14), alignItems: "center", justifyContent: "center", marginVertical: rs(8, 6, 10) },
  secondary: { backgroundColor: colors.success },
  disabled: { opacity: 0.5 },
  text: { color: colors.white, fontSize: font(18), fontWeight: "700" },
});
