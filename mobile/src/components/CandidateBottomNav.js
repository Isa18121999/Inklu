import React from "react";
import { Pressable, Text, View, StyleSheet } from "react-native";
import { colors } from "../theme/colors";
import { font, rs } from "../theme/responsive";

const tabs = [
  { key: "home", label: "Inicio", icon: "⌂", route: "CandidateDashboard" },
  { key: "messages", label: "Mensajes", icon: "✉", route: "Messages" },
  { key: "search", label: "Buscar", icon: "⌕", route: "Jobs", center: true },
  { key: "applications", label: "Postulaciones", icon: "✓", route: "Applications" },
  { key: "cv", label: "Mi CV", icon: "▣", route: "CV" }
];

export default function CandidateBottomNav({ navigation, active }) {
  return (
    <View style={styles.bar} accessibilityRole="tablist">
      {tabs.map((tab) => {
        const selected = active === tab.key;
        return (
          <Pressable
            key={tab.key}
            style={[styles.tab, tab.center && styles.centerTab]}
            onPress={() => navigation.navigate(tab.route)}
            accessibilityRole="tab"
            accessibilityState={{ selected }}
            accessibilityLabel={tab.label}
          >
            <View style={[styles.iconCircle, tab.center && styles.centerCircle, selected && !tab.center && styles.iconCircleSelected]}>
              <Text style={[styles.icon, selected && styles.iconSelected, tab.center && styles.centerIcon, selected && tab.center && styles.centerIconSelected]}>{tab.icon}</Text>
            </View>
            <Text numberOfLines={1} adjustsFontSizeToFit minimumFontScale={0.68} style={[styles.label, selected && styles.labelSelected]}>{tab.label}</Text>
          </Pressable>
        );
      })}
    </View>
  );
}

const styles = StyleSheet.create({
  bar: {
    position: "absolute", left: 0, right: 0, bottom: 0, height: rs(78, 74, 84),
    backgroundColor: colors.white, borderTopWidth: 1, borderTopColor: "#E5E7EB",
    flexDirection: "row", paddingHorizontal: rs(4, 2, 7), paddingTop: rs(5, 4, 7), paddingBottom: rs(4, 3, 6),
    elevation: 14, shadowOpacity: 0.12, shadowRadius: 6, zIndex: 20
  },
  tab: { flex: 1, minWidth: 0, alignItems: "center", justifyContent: "flex-end", borderRadius: rs(13, 11, 15), paddingBottom: 1 },
  centerTab: { justifyContent: "flex-start", paddingBottom: 0 },
  iconCircle: { width: rs(34, 30, 38), height: rs(34, 30, 38), borderRadius: rs(17, 15, 19), alignItems: "center", justifyContent: "center" },
  iconCircleSelected: { backgroundColor: "#EDE9FE" },
  centerCircle: {
    width: rs(62, 56, 70), height: rs(62, 56, 70), borderRadius: rs(31, 28, 35),
    backgroundColor: colors.white, borderWidth: 1, borderColor: "#E5E7EB", elevation: 7,
    shadowOpacity: 0.16, shadowRadius: 7, marginTop: rs(-31, -28, -35)
  },
  icon: { fontSize: font(23), lineHeight: font(27), color: "#6B7280", fontWeight: "600" },
  iconSelected: { color: colors.primary },
  centerIcon: { fontSize: font(36), lineHeight: font(40), color: colors.primary, fontWeight: "400" },
  centerIconSelected: { color: colors.primary },
  label: { marginTop: 2, fontSize: font(10.5), lineHeight: font(14), color: colors.text, textAlign: "center", includeFontPadding: false, fontWeight: "600", maxWidth: "100%" },
  labelSelected: { color: colors.primary, fontWeight: "800" }
});
