import React from "react";
import { Pressable, Text, View, StyleSheet } from "react-native";
import { colors } from "../theme/colors";
import { font, rs } from "../theme/responsive";

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
  bar: { position: "absolute", left: 0, right: 0, bottom: 0, height: rs(76, 72, 82), backgroundColor: colors.white, borderTopWidth: 1, borderTopColor: "#E5E7EB", flexDirection: "row", paddingHorizontal: rs(4, 2, 6), paddingVertical: rs(5, 4, 7), elevation: 14, shadowOpacity: 0.12, shadowRadius: 6 },
  tab: { flex: 1, minWidth: 0, alignItems: "center", justifyContent: "center", paddingHorizontal: 1, borderRadius: rs(14, 12, 16) },
  tabSelected: { backgroundColor: "#EDE9FE", marginVertical: 1 },
  icon: { fontSize: font(22), lineHeight: font(26), color: colors.text },
  iconSelected: { color: colors.primary },
  label: { marginTop: 2, fontSize: font(10.5), lineHeight: font(14), color: colors.text, textAlign: "center", includeFontPadding: false, fontWeight: "600" },
  labelSelected: { color: colors.primary, fontWeight: "800" }
});
