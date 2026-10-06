import React from "react";
import { Pressable, Text, View, StyleSheet } from "react-native";
import { colors } from "../theme/colors";

const tabs = [
  { key: "search", label: "Buscador", icon: "⌕", route: "Jobs" },
  { key: "applications", label: "Postulaciones", icon: "➤", route: "Applications" },
  { key: "favorites", label: "Favoritos", icon: "♡", route: "Favorites" },
  { key: "alerts", label: "Alertas", icon: "♧", route: "Notifications" },
  { key: "menu", label: "Menú", icon: "☰", route: "MenuArea" }
];

export default function CandidateBottomNav({ navigation, active }) {
  return (
    <View style={styles.bar} accessibilityRole="tablist">
      {tabs.map((tab) => {
        const selected = active === tab.key;
        return (
          <Pressable
            key={tab.key}
            style={[styles.tab, selected && styles.tabSelected]}
            onPress={() => navigation.navigate(tab.route)}
            accessibilityRole="tab"
            accessibilityState={{ selected }}
            accessibilityLabel={tab.label}
          >
            <Text style={[styles.icon, selected && styles.iconSelected]}>{tab.icon}</Text>
            <Text style={[styles.label, selected && styles.labelSelected]}>{tab.label}</Text>
          </Pressable>
        );
      })}
    </View>
  );
}

const styles = StyleSheet.create({
  bar: { position: "absolute", left: 0, right: 0, bottom: 0, height: 78, backgroundColor: colors.secondary, flexDirection: "row", paddingHorizontal: 4, paddingTop: 5, paddingBottom: 5, elevation: 14 },
  tab: { flex: 1, alignItems: "center", justifyContent: "center", minWidth: 56, marginHorizontal: 2, borderRadius: 14 },
  tabSelected: { backgroundColor: colors.primary, elevation: 5 },
  icon: { fontSize: 28, lineHeight: 31, color: "#E5E7EB" },
  iconSelected: { color: colors.white },
  label: { marginTop: 2, fontSize: 12, color: "#E5E7EB", textAlign: "center" },
  labelSelected: { color: colors.white, fontWeight: "800" }
});
