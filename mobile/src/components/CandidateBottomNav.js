import React from "react";
import { Pressable, Text, View, StyleSheet } from "react-native";
import { colors } from "../theme/colors";

const tabs = [
  { key: "search", label: "Buscar", icon: "⌕", route: "Jobs" },
  { key: "applications", label: "Postulaciones", icon: "✓", route: "Applications" },
  { key: "favorites", label: "Favoritos", icon: "♥", route: "Favorites" },
  { key: "alerts", label: "Alertas", icon: "●", route: "Notifications" },
  { key: "menu", label: "Menú", icon: "☰", route: "MenuArea" }
];

export default function CandidateBottomNav({ navigation, active }) {
  return (
    <View style={styles.bar} accessibilityRole="tablist">
      {tabs.map((tab) => {
        const selected = active === tab.key;
        return (
          <Pressable key={tab.key} style={[styles.tab, selected && styles.tabSelected]} onPress={() => navigation.navigate(tab.route)} accessibilityRole="tab" accessibilityState={{ selected }} accessibilityLabel={tab.label}>
            <Text style={[styles.icon, selected && styles.iconSelected]}>{tab.icon}</Text>
            <Text numberOfLines={1} adjustsFontSizeToFit minimumFontScale={0.72} style={[styles.label, selected && styles.labelSelected]}>{tab.label}</Text>
          </Pressable>
        );
      })}
    </View>
  );
}

const styles = StyleSheet.create({
  bar: { position: "absolute", left: 0, right: 0, bottom: 0, height: 82, backgroundColor: colors.white, borderTopWidth: 1, borderTopColor: "#E5E7EB", flexDirection: "row", paddingHorizontal: 4, paddingVertical: 6, elevation: 14, shadowOpacity: 0.12, shadowRadius: 6 },
  tab: { flex: 1, minWidth: 0, alignItems: "center", justifyContent: "center", paddingHorizontal: 1, borderRadius: 16 },
  tabSelected: { backgroundColor: "#EDE9FE", marginVertical: 1 },
  icon: { fontSize: 24, lineHeight: 28, color: colors.text },
  iconSelected: { color: colors.primary },
  label: { marginTop: 3, fontSize: 11, lineHeight: 15, color: colors.text, textAlign: "center", includeFontPadding: false, fontWeight: "600" },
  labelSelected: { color: colors.primary, fontWeight: "800" }
});
